.add_rule_arg_checks <- function(registry, rule_name, validator_fn, schema_fn) {
  if (!is_nz_string(rule_name)) {
    stop("`rule_name` must be a single non-empty string.", call. = FALSE)
  } else if (!is.function(validator_fn)) {
    stop("`validator_fn` must be a function.", call. = FALSE)
  } else if (!is.function(schema_fn)) {
    stop("`schema_fn` must be a function.", call. = FALSE)
  }
}

.vargs_check <- function(vargs) {
  if (i <- !is.null(vargs)) {
    if (".schema" %in% vargs) {
      stop(
        "Validator rule functions cannot have a `.schema` argument.\n",
        "Did you mean to use `.data`?",
        call. = FALSE
      )
    }

    valid <- .rule_fn_args_valid(
      length(vargs),
      c(3L, 4L),
      c(".self", ".data"),
      vargs
    )
  }

  if (!i || !valid) {
    stop(
      "Validator rule function arguments must be in one of the following ",
      "forms:\n",
      "- `function(field, schema_field, ...)`\n",
      "- `function(field, schema_field, .self, ...)` |\n",
      "   `function(field, schema_field, .data, ...)`\n",
      "- `function(field, schema_field, .self, .data)`",
      call. = FALSE
    )
  }
}

.sargs_check <- function(sargs, cross = FALSE) {
  if (cross) {
    txt <- "cross "
    arg <- "node"
  } else {
    txt <- NULL
    arg <- "field"
  }

  if (i <- !is.null(sargs)) {
    if (".data" %in% sargs) {
      stop(
        "Schema ", txt, "rule functions cannot have a `.data` argument.\n",
        "Did you mean to use `.schema`?",
        call. = FALSE
      )
    }

    valid <- .rule_fn_args_valid(
      length(sargs),
      c(2L, 3L),
      c(".self", ".schema"), # c(".self", ".data"),
      sargs
    )
  }

  if (!i || !valid) {
    stop(
      "Schema ", txt,
      "rule function arguments must be in one of the following forms:\n",
      "- `function(", arg, ", ...)`\n",
      "- `function(", arg, ", .self, ...)` |\n",
      "   `function(", arg, ", .schema, ...)`\n",
      "- `function(", arg, ", .self, .schema)`",
      call. = FALSE
    )
  }
}

.rule_fn_args_valid <- function(le, arg_le, keys, args) {
  if (le < arg_le[[1]] || le > arg_le[[2]]) {
    FALSE
  } else if (
    (le == arg_le[[1]] && "..." %in% args && keys %nonein% args) ||
      (le == arg_le[[2]] && (
        "..." %in% args && keys %onein% args ||
          "..." %notin% args && keys %allin% args
      ))
  ) {
    TRUE
  } else {
    FALSE
  }
}

.add_rule <- function(obj, rule_name, validator_fn, schema_fn, rule_type) {
  if (i <- is.null(schema_fn)) {
    schema_fn <- function(field, ...) {}
  }

  .add_rule_arg_checks(
    obj,
    rule_name,
    validator_fn,
    schema_fn
  )

  # fn checks, first validator fn
  .vargs_check(methods::formalArgs(validator_fn))
  if (!i) { # if schema fn provided, check args
    .sargs_check(methods::formalArgs(schema_fn))
  }

  rule_type <- paste0(rule_type, "_rules")
  # add the rule name
  S7::prop(obj, rule_type, check = FALSE) <- c(
    S7::prop(obj, rule_type),
    rule_name
  )

  # add the rule fns to duplicated envs so no mutation in place
  # use attr to bypass the setter (which forces this fn to be used)
  attr(obj, "validator_rules") <- update_rule_env(
    obj,
    "validator_rules",
    rule_name,
    validator_fn
  )

  attr(obj, "schema_rules") <- update_rule_env(
    obj,
    "schema_rules",
    rule_name,
    schema_fn
  )

  S7::validate(obj)
}

S7::method(add_rule, Registry) <- function(
  obj,
  name,
  validator_fn,
  schema_fn = NULL,
  rule_type = c("validate", "control", "transform", "finalize")
) {
  rule_type <- match.arg(rule_type)
  .add_rule(obj, name, validator_fn, schema_fn, rule_type)
}

S7::method(add_rule, Schema) <- function(
  obj,
  name,
  validator_fn,
  schema_fn = NULL,
  rule_type = c("validate", "control", "transform", "finalize")
) {
  rule_type <- match.arg(rule_type)
  S7::prop(obj, "Registry", check = TRUE) <- .add_rule(
    S7::prop(obj, "Registry"),
    name,
    validator_fn,
    schema_fn,
    rule_type
  )

  # manually invalidate the schema cache
  cache <- S7::prop(obj, ".schema_cache")
  cache$result <- NULL

  S7::validate(obj)
}

S7::method(add_rule, Validator) <- function(
  obj,
  name,
  validator_fn,
  schema_fn = NULL,
  rule_type = c("validate", "control", "transform", "finalize")
) {
  rule_type <- match.arg(rule_type)
  nested_prop(obj, "Schema", "Registry", check = TRUE) <- .add_rule(
    nested_prop(obj, "Schema", "Registry"),
    name,
    validator_fn,
    schema_fn,
    rule_type
  )

  schema_cache <- nested_prop(obj, "Schema", ".schema_cache")
  schema_cache$result <- NULL
  S7::prop(
    obj, "Schema",
    check = FALSE
  ) <- S7::validate(S7::prop(obj, "Schema"))

  S7::validate(obj)
}
