.add_cross_rule_arg_checks <- function(
  registry,
  cross_rule_name,
  rule_names,
  schema_cross_fn
) {
  if (!is_nz_string(cross_rule_name)) {
    stop(
      "`cross_rule_name` must be a single non-empty, non-NA string.",
      call. = FALSE
    )
  } else if (!is_nz_chr(rule_names, minlength = 2L)) {
    stop(
      "`rule_names` must be a non-zero, non-NA character vector ",
      "of at least length 2.",
      call. = FALSE
    )
  } else if (!is.function(schema_cross_fn)) {
    stop("`schema_cross_fn` must be a function.", call. = FALSE)
  }
}

.add_cross_rule <- function(obj, cross_rule_name, rule_names, schema_cross_fn) {
  .add_cross_rule_arg_checks(obj, cross_rule_name, rule_names, schema_cross_fn)
  .sargs_check(methods::formalArgs(schema_cross_fn), cross = TRUE)

  attr(obj, "cross_rules") <- update_rule_env(
    obj,
    "cross_rules",
    cross_rule_name,
    list(
      rules = rule_names,
      fn = schema_cross_fn
    )
  )

  S7::validate(obj)
}

S7::method(add_cross_rule, Registry) <- function(
  obj,
  name,
  rule_names,
  cross_fn
) {
  .add_cross_rule(obj, name, rule_names, cross_fn)
}

S7::method(add_cross_rule, Schema) <- function(
  obj,
  name,
  rule_names,
  cross_fn
) {
  S7::prop(obj, "Registry", check = FALSE) <- .add_cross_rule(
    S7::prop(obj, "Registry"),
    name,
    rule_names,
    cross_fn
  )

  # manually invalidate the schema cache
  cache <- S7::prop(obj, ".schema_cache")
  cache$result <- NULL

  S7::validate(obj)
}

S7::method(add_cross_rule, Validator) <- function(
  obj,
  name,
  rule_names,
  cross_fn
) {
  nested_prop(obj, "Schema", "Registry", check = FALSE) <- .add_cross_rule(
    nested_prop(obj, "Schema", "Registry"),
    name,
    rule_names,
    cross_fn
  )

  schema_cache <- nested_prop(obj, "Schema", ".schema_cache")
  schema_cache$result <- NULL
  S7::prop(
    obj, "Schema",
    check = FALSE
  ) <- S7::validate(S7::prop(obj, "Schema"))

  # don't need to invalidate the validator cache as that is done
  # in the schema setter

  # validator_cache <- S7::prop(obj, ".validator_cache")
  # validator_cache$result <- NULL

  S7::validate(obj)
}
