validate_by_schema <- function(
  data,
  schema,
  rule_names,
  control_rules,
  transform_rules,
  validate_rules,
  finalize_rules,
  rule_registry,
  self
) {
  # for each walk, rules that were operated/ignored due
  # to control flow will become error properties and
  # will be skipped
  se <- list()
  se$errors <- rapply(schema, function(x) NULL, how = "replace")
  se$schema <- schema
  stages <- list(control_rules, transform_rules, validate_rules, finalize_rules)

  root_env <- new.env(parent = emptyenv())
  root_env$data <- data
  get_root <- function() root_env$data
  set_root <- function(v) root_env$data <- v

  for (i in seq_along(stages)) {
    se <- validate_rule_group(
      se$schema,
      se$errors,
      rule_names,
      stages[[i]],
      if (i == 4) TRUE else FALSE,
      rule_registry,
      get_root,
      set_root,
      get_root,
      self
    )
  }

  list(data = get_root(), errors = se$errors)
}

validate_rule_group <- function(
  schema,
  errors,
  rule_names,
  group_rules,
  final_pass,
  rule_registry,
  get, # () -> current node's value, reading fresh from root
  set, # (v) -> write v into current node's slot, propagates to root
  get_root, # () -> full root data, for .data in rules
  self
) {
  # names of the schema
  schema_names <- methods::allNames(schema)

  # index rules and group rules
  all_rules_i <- schema_names %in% rule_names
  n_rules <- sum(all_rules_i)
  group_rules_i <- schema_names %in% group_rules
  non_group_rules_i <- all_rules_i & !group_rules_i

  # if any group rules, execute them
  if (any(group_rules_i)) {
    rules <- schema_names[group_rules_i]

    # don't execute finalize rules if any other rules
    # have already errored
    if (
      !(
        final_pass &&
          any(
            vapply(all_rules_i, function(r) !is.null(errors[[r]]), logical(1))
          )
      )
    ) {
      for (rule in rules) {
        if (!is.null(
          attr(schema[[rule]], "*__FLUFFY_SKIP__*")
        )) {
          next
        }

        res <- do_rule(
          get(),
          schema[[rule]],
          rule,
          rule_registry,
          get_root,
          self
        )

        if (!is.null(res$data)) set(res$data)
        errors[rule] <- res["error"]
        if (!res$continue) {
          # control flow breaks remaining control rules -
          # break loop and this group won't be processed further,
          # but add attr to remaining non-control rules to skip
          # in future processing
          for (j in which(non_group_rules_i)) {
            attr(schema[[j]], "*__FLUFFY_SKIP__*") <- TRUE
          }
          break
        }
      }
    }
  }

  # loop the schema
  for (i in seq_along(schema_names)) {
    if (all_rules_i[i]) {
      # if it's a rule of any kind, skip
      next
    }

    key <- schema_names[[i]]
    schema_field <- schema[[i]]
    error_field <- errors[[i]]

    if (!nzchar(key)) {
      # unnamed schema fields are positional; adjust index past the rules
      # as schemas are auto-ordered rules first, the
      # index of the non-rule schema element will be
      # the index in the data minus the number of rules
      key <- i - n_rules
    }

    child_get <- function() {
      d <- get()
      data_names <- methods::allNames(d)

      if (is.character(key)) {
        if (key %in% data_names) {
          d[[key]]
        } else {
          NULL
        }
      } else {
        if (key > length(d)) {
          NULL
        } else {
          d[[key]]
        }
      }
    }

    child_set <- function(v) {
      d <- get()
      d[[key]] <- v
      set(d)
    }

    out <- validate_rule_group(
      schema_field,
      error_field,
      rule_names,
      group_rules,
      final_pass,
      rule_registry,
      child_get,
      child_set,
      get_root,
      self
    )

    schema[[i]] <- out$schema
    errors[[i]] <- out$errors
  }
  list(schema = schema, errors = errors)
}

do_rule <- function(
  data_value,
  schema_value,
  rule_name,
  rule_registry,
  get_root,
  self
) {
  if (!any(c("default", "required") %in% rule_name) && is.null(data_value)) {
    return(
      list(
        data = data_value,
        error = "No data for field.",
        continue = FALSE
      )
    )
  }

  fn <- rule_registry[[rule_name]]
  if (is.null(fn)) {
    return(
      list(
        data = data_value,
        error = paste0("Unknown rule: `", rule_name, "`."),
        continue = TRUE
      )
    )
  }

  res <- fn(
    data_value,
    schema_value,
    .data = get_root(),
    .self = self
  )

  rule_output_check(res, data_value)
}

rule_output_check <- function(res, value) {
  if (is.null(res)) {
    list(
      data = value,
      error = NULL,
      continue = TRUE
    )
  } else if (!is.list(res)) {
    list(
      data = value,
      error = "Rule must return a list.",
      continue = TRUE
    )
  } else if (all(c("data", "error", "continue") %notin% names(res))) {
    list(
      data = value,
      error = "Rule list return must have `data`, `error` or `continue` elements.",
      continue = TRUE
    )
  } else if (!is.null(res$error) && !is_nz_string(res$error)) {
    list(
      data = value,
      error = "Rule list `error` element must be a non-empty string.",
      continue = TRUE
    )
  } else if (!is.null(res$continue) && !is_bool(res$continue)) {
    list(
      data = value,
      error = "Rule list `continue` element must be a boolean.",
      continue = TRUE
    )
  } else {
    list(
      data = res$data %||% value,
      error = res$error,
      continue = res$continue %||% TRUE
    )
  }
}
