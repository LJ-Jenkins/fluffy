.add_tc_rule_arg_checks <- function(type_name, type_fn, txt = "type") {
  if (!is_nz_string(type_name)) {
    stop(
      "`", txt, "_name` must be a single non-empty, non-NA string.",
      call. = FALSE
    )
  } else if (!is.function(type_fn)) {
    stop("`", txt, "_fn` must be a function.", call. = FALSE)
  }
}

.tcargs_check <- function(args, txt = "type") {
  if (length(args) != 1L) {
    stop(
      "`", txt, "_fn` must have exactly one argument (for the field value).",
      call. = FALSE
    )
  }
}

.add_type_rule <- function(obj, type_name, type_fn) {
  .add_tc_rule_arg_checks(type_name, type_fn)
  .tcargs_check(formals(type_fn))

  attr(obj, "type_map") <- update_rule_env(
    obj,
    "type_map",
    type_name,
    type_fn
  )

  (S7::validate(obj))
}

S7::method(add_type_rule, Registry) <- function(
  obj,
  type_name,
  type_fn
) {
  .add_type_rule(obj, type_name, type_fn)
}

method(add_type_rule, Schema) <- function(
  obj,
  type_name,
  type_fn
) {
  S7::prop(obj, "Registry", check = FALSE) <- .add_type_rule(
    S7::prop(obj, "Registry"),
    type_name,
    type_fn
  )

  # manually invalidate the schema cache
  cache <- S7::prop(obj, ".schema_cache")
  cache$result <- NULL

  (S7::validate(obj))
}

S7::method(add_type_rule, Validator) <- function(
  obj,
  type_name,
  type_fn
) {
  nested_prop(obj, "Schema", "Registry", check = TRUE) <- .add_type_rule(
    nested_prop(obj, "Schema", "Registry"),
    type_name,
    type_fn
  )

  schema_cache <- nested_prop(obj, "Schema", ".schema_cache")
  schema_cache$result <- NULL
  S7::prop(
    obj, "Schema",
    check = FALSE
  ) <- S7::validate(S7::prop(obj, "Schema"))

  S7::validate(obj)
}

#--

.add_coerce_rule <- function(obj, coerce_name, coerce_fn) {
  .add_tc_rule_arg_checks(coerce_name, coerce_fn, "coerce")
  .tcargs_check(formals(coerce_fn), "coerce")

  attr(obj, "coerce_map") <- update_rule_env(
    obj,
    "coerce_map",
    coerce_name,
    coerce_fn
  )

  (S7::validate(obj))
}

S7::method(add_coerce_rule, Registry) <- function(
  obj,
  coerce_name,
  coerce_fn
) {
  .add_coerce_rule(obj, coerce_name, coerce_fn)
}

S7::method(add_coerce_rule, Schema) <- function(
  obj,
  coerce_name,
  coerce_fn
) {
  S7::prop(obj, "Registry", check = TRUE) <- .add_coerce_rule(
    S7::prop(obj, "Registry"),
    coerce_name,
    coerce_fn
  )

  # manually invalidate the schema cache
  cache <- S7::prop(obj, ".schema_cache")
  cache$result <- NULL

  (S7::validate(obj))
}

S7::method(add_coerce_rule, Validator) <- function(
  obj,
  coerce_name,
  coerce_fn
) {
  nested_prop(obj, "Schema", "Registry", check = TRUE) <- .add_coerce_rule(
    nested_prop(obj, "Schema", "Registry"),
    coerce_name,
    coerce_fn
  )

  schema_cache <- nested_prop(obj, "Schema", ".schema_cache")
  schema_cache$result <- NULL
  S7::prop(
    obj, "Schema",
    check = FALSE
  ) <- S7::validate(S7::prop(obj, "Schema"))

  (S7::validate(obj))
}
