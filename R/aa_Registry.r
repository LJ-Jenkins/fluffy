#' @title
#' Registry
#' @description
#' Create a `Registry` object that defines and stores rules for validating
#' data against a [Schema].
#' @param x
#' Object to be tested.
#' @prop rule_names (Read-only)
#' All rules, in order of evaluation.
#' Derived from the combination of the
#' `control`, `transform`, `validate`, and `finalize` rules.
#' @prop control_rules
#' Rules that influence the control flow.
#' These will be applied in the first pass when validating data.
#' @prop transform_rules
#' Rules that transform data. These will be applied
#' in the second pass when validating data.
#' @prop validate_rules
#' Rules that validate data. These will be applied
#' in the penultimate pass when validating.
#' @prop finalize_rules
#' Rules that finalize validation. These will be
#' applied in the last pass when validating, after all other rules have been
#' applied. These rules will only apply if no previous rules for that schema
#' node have failed.
#' @prop str_to_fn_rules
#' Schema rules that are allowed to have string or
#' function values, with string values being converted to functions
#' automatically during schema validation.
#' @prop str_to_fn_converter
#' Function that converts string values to functions for the
#' `@str_to_fn_rules`.
#' @prop type_names (Read-only)
#' Allowed type names. Derived from the keys of the
#' `@type_map`.
#' @prop type_map
#' Environment mapping type names to type definition functions. Can only
#' be added to via [add_type_rule()].
#' @prop coerce_names (Read-only)
#' Allowed coercion names. Derived from the keys of the
#' `@coerce_map`.
#' @prop coerce_map
#' Environment mapping coercion names to coercion functions. Can only
#' be added to via [add_coerce_rule()].
#' @prop schema_rules
#' Environment mapping schema rule names to schema validation functions. Can
#' only be added to via [add_rule()].
#' @prop cross_rule_names (Read-only)
#' Schema cross rules. Derived from the keys
#' of the `@cross_rules` environment.
#' @prop cross_rules
#' Environment containing the schema cross rule functions (rules that check
#' relationships between multiple schema rule values). Can only be added to
#' via [add_cross_rule()].
#' @prop validator_rules
#' Environment mapping validator rule names to validator functions. Can only
#' be added to via [add_rule()].
#' @returns
#' A `Registry` S7 object.
#' @details
#' The `Registry` class serves as a central repository for all the rules used
#' in `fluffy` schema and data validation. It is passed to the [Schema] and
#' [Validator] classes, which use the rules stored in the `Registry` to
#' validate schemas and data, respectively.
#'
#' To see the available builtin rules,
#' use the helper function [`show_builtins()`], which lists all the builtin
#' rules in a `Registry`.
#'
#' As `Registry` objects are automatically created in the `Schema` constructor,
#' which is in turn called in the `Validator` constructor, a `Registry` does not
#' need to be created separately to use `fluffy`'s validation functionality.
#' Custom rules can also be added to the `Registry` within a `Schema` or
#' `Validator`  object. However, rule addition will trigger re-validation of
#' the given object, so for the addition of many new rules, it is beneficial
#' to create a `Registry` object, add all the rules to it, and then pass it to
#' the other classes.
#'
#' For full details see the vignettes on
#' [builtin rules](../doc/validation-rules.html),
#' [data validation](../doc/validating-data.html), and
#' [adding custom rules](../doc/custom-rules.html).
#' @seealso [Schema] and [Validator] constructors. [add_rule] for adding
#' rules to a `Registry`.
#' @examples
#' r <- Registry()
#' s <- Schema(list(type = "integer"), registry = r)
#'
#' is.Registry(r)
#' @export
Registry <- S7::new_class(
  "Registry",
  package = "fluffy",
  properties = list(
    rule_names = S7::new_property(
      getter = function(self) {
        c(
          S7::prop(self, "control_rules"),
          S7::prop(self, "transform_rules"),
          S7::prop(self, "validate_rules"),
          S7::prop(self, "finalize_rules")
        )
      }
    ),
    control_rules = S7::class_character,
    transform_rules = S7::class_character,
    validate_rules = S7::class_character,
    finalize_rules = S7::class_character,
    str_to_fn_rules = S7::class_character,
    str_to_fn_converter = S7::new_property(
      S7::class_function,
      validator = function(value) {
        if (length(formals(value)) != 1L) {
          "must be a function that takes exactly one argument."
        }
      }
    ),
    type_names = env_names_prop("type_map"),
    type_map = env_prop("type_map"),
    coerce_names = env_names_prop("coerce_map"),
    coerce_map = env_prop("coerce_map"),
    schema_rules = env_prop("schema_rules"),
    cross_rule_names = env_names_prop("cross_rules"),
    cross_rules = env_prop("cross_rules"),
    validator_rules = env_prop("validator_rules")
  ),
  validator = function(self) {
    if (anyDuplicated(S7::prop(self, "rule_names"))) {
      # we only need to check rule_names as it is a combination of the others
      "@rule_names must not contain duplicates."
    } else if (any(
      ls(S7::prop(self, "schema_rules")) %notin% S7::prop(self, "rule_names")
    )) {
      paste(
        "@schema_rules contains names of rules not",
        "in @rule_names."
      )
    } else if (any(
      S7::prop(self, "rule_names") %notin% ls(S7::prop(self, "schema_rules"))
    )) {
      paste(
        "@rule_names contains names of rules not",
        "in @schema_rules."
      )
    } else if (any(
      ls(S7::prop(self, "validator_rules")) %notin% S7::prop(self, "rule_names")
    )) {
      paste(
        "@validator_rules contains names of rules not",
        "in @rule_names."
      )
    } else if (any(
      S7::prop(self, "rule_names") %notin% ls(S7::prop(self, "validator_rules"))
    )) {
      paste(
        "@rule_names contains names of rules not",
        "in @validator_rules."
      )
    } else if (any(
      S7::prop(self, "str_to_fn_rules") %notin% S7::prop(self, "rule_names")
    )) {
      paste(
        "@str_to_fn_rules contains names of rules not",
        "in @rule_names."
      )
    } else if (any(
      S7::prop(self, "cross_rule_names") %in% S7::prop(self, "rule_names")
    )) {
      paste(
        "@cross_rule_names must be different from",
        "@rule_names."
      )
    } else if (cross_rule_operating_names_check(
      S7::prop(self, "cross_rules"),
      S7::prop(self, "rule_names")
    )) {
      paste0(
        "@cross_rules contains names of rules to operate on that ",
        "are not in @rule_names."
      )
    }
  },
  constructor = function() {
    S7::new_object(
      S7::S7_object(),
      control_rules = .fl_control_rules,
      transform_rules = .fl_transform_rules,
      validate_rules = .fl_validate_rules,
      finalize_rules = .fl_finalize_rules,
      str_to_fn_rules = .fl_str_to_fn_rules,
      str_to_fn_converter = .fl_str_to_fn_converter,
      type_map = .fl_type_map(),
      coerce_map = .fl_coerce_map(),
      schema_rules = .fl_schema_rules(),
      cross_rules = .fl_schema_cross_rules(),
      validator_rules = .fl_validator_rules()
    )
  }
)

#' @rdname Registry
#' @export
is.Registry <- function(x) {
  S7::S7_inherits(x, Registry)
}
