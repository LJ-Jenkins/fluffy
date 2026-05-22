validate_schema_walk <- function(
  schema,
  rule_names,
  rule_registry,
  cross_rules_names,
  cross_rules_registry,
  full_schema,
  self
) {
  # 3 passes required:
  # 1 for rule checking (mixed nodes/full leafs)
  # 2 for cross_rules after individual rules checked
  # 3 for recursing into list elements (not dependencies)
  nms <- methods::allNames(schema)
  # copy before modifying for the cross rules
  og_schema <- schema

  # error on duplicate names at same level
  is_dup <- all_duplicates(nms) & nzchar(nms)
  if (any(is_dup)) {
    schema[is_dup] <- "Names must be unique at the same depth."
  }

  # first, mixed nodes: apply check to the leaf elements
  # full leafs will use this too
  j <- c()
  cr_flag <- 0
  for (i in seq_along(schema)) {
    if (is_dup[i]) {
      next
    }

    # error on empties
    if (length(schema[[i]]) == 0) {
      schema[[i]] <- "Empty element."
      next
    }

    key <- nms[[i]]
    if (!.fl_obj_is_list(schema[[i]]) || key %in% rule_names) {
      # leafs must be named
      if (!nzchar(key)) {
        schema[[i]] <- "Schema leafs must be named with rules."
        next
      }

      schema[i] <- check_schema_rule(
        key,
        schema[[i]],
        rule_registry,
        full_schema,
        self
      )

      cr_flag <- cr_flag + 1
    } else { # track list elements for recursion
      j <- c(j, i)
    }
  }

  # second, check cross rules
  if (cr_flag > 1) { # min 2 for a cross rule
    for (cr_name in cross_rules_names) {
      cr <- cross_rules_registry[[cr_name]]
      rules <- cr$rules
      # if all the required rules are present in the mixed node or leaf
      # and all of the individual rules have passed (aka are NULL)
      # then proceed with cross rule check
      if (
        rules %allin% nms &&
          all(
            vapply(schema[rules], function(.x) is.null(.x[[1]]), logical(1))
          )
      ) {
        # for the cross rule check, as schema is being turned into 'errors'
        # use the values from the og_schema instead of the modified schema
        out <- cr$fn(og_schema[rules], .schema = full_schema, .self = self)
        if (!is.null(out)) {
          # change all the individual rules to the cross rule error
          schema[rules] <- out
        }
      }
    }
  }

  # third, recurse into list elements (not dependencies)
  for (i in j) {
    schema[[i]] <- validate_schema_walk(
      schema[[i]],
      rule_names,
      rule_registry,
      cross_rules_names,
      cross_rules_registry,
      full_schema,
      self
    )
  }

  schema
}

check_schema_rule <- function(
  rule_name,
  rule_value,
  rule_registry,
  full_schema,
  self
) {
  schema_fn <- rule_registry[[rule_name]]
  out <- if (is.null(schema_fn)) {
    paste0("Unknown rule: `", rule_name, "`.")
  } else {
    schema_fn(rule_value, .schema = full_schema, .self = self)
  }
  list(out)
}
