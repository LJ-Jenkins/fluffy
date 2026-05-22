.schema_input_check <- function(value) {
  if (!is.list(value) || is.data.frame(value)) {
    stop(
      "<fluffy::Schema>@schema must be <list>, not <",
      if (is.data.frame(value)) "data.frame" else typeof(value),
      ">",
      call. = FALSE
    )
  }

  if (length(value) == 0) {
    stop(
      "<fluffy::Schema>@schema must be a non-empty <list>",
      call. = FALSE
    )
  }
}

.get_schema <- function(self) {
  cache <- S7::prop(self, ".schema_cache")

  if (is.null(cache$result)) {
    cache$result <- .run_schema_validation(self, cache)
  }
  cache$result
}

.run_schema_validation <- function(self, cache) {
  schema <- cache$input

  nms <- nested_prop(self, "Registry", "rule_names")
  str_fn_nms <- nested_prop(self, "Registry", "str_to_fn_rules")

  schema <- reorder_schema_by_rules(
    schema,
    nms
  )

  schema <- convert_string_rules_walk(
    schema,
    str_fn_nms,
    nms[nms %notin% str_fn_nms],
    nested_prop(self, "Registry", "str_to_fn_converter")
  )

  # schema validation doesn't care about rule types
  errors <- validate_schema_walk(
    schema,
    nms,
    nested_prop(self, "Registry", "schema_rules"),
    nested_prop(self, "Registry", "cross_rule_names"),
    nested_prop(self, "Registry", "cross_rules"),
    schema,
    self
  )

  list(data = schema, errors = errors)
}

reorder_schema_by_rules <- function(schema, rules) {
  if (!.fl_obj_is_list(schema)) {
    return(schema)
  }

  nms <- names(schema)
  if (is.null(nms)) {
    return(lapply(schema, reorder_schema_by_rules, rules))
  }

  match_idx <- which(!is.na(match(nms, rules)))
  ordered_matches <- match_idx[order(match(nms[match_idx], rules))]
  non_matches <- setdiff(seq_along(schema), match_idx)

  schema <- schema[c(ordered_matches, non_matches)]
  schema[] <- lapply(schema, reorder_schema_by_rules, rules)

  schema
}

convert_string_rules_walk <- function(
  schema,
  string_rule_names,
  other_rule_names,
  str_to_fn_converter
) {
  nms <- methods::allNames(schema)
  for (i in seq_along(schema)) {
    field_name <- nms[[i]]
    field_value <- schema[[i]]

    if (field_name %in% other_rule_names) {
      next # ignore recursion for rules
    }

    if (.fl_obj_is_list(field_value) && length(field_value) > 0) {
      schema[[i]] <- convert_string_rules_walk(
        field_value,
        string_rule_names,
        other_rule_names,
        str_to_fn_converter
      )
    } else if (
      field_name %in% string_rule_names && is_nz_string(field_value)
    ) {
      fn <- str_to_fn_converter(field_value)
      if (is.function(fn)) {
        schema[[i]] <- fn
      }
      # if not a function, leave as is and let validation error
    }
  }

  schema
}
