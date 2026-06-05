#' @title
#' Validator
#' @description
#' Create a `Validator` object that validates/transforms R objects
#' using a [Schema].
#' @param data
#' An R object. If using a nested schema, the object must have a `[[` method.
#' @param schema
#' [Schema] object or a non-empty `list` defining the schema.
#' See the [Schema] constructor for details on the schema structure and rules.
#' @param error
#' Single logical value. If `TRUE`, the constructor throws
#' an error when validation fails.
#' @param x
#' Object to be tested.
#' @prop data
#' The validated input data, with any changes that were made during validation.
#' @prop Schema
#' An object of class [Schema] containing the schema used for validation, as
#' well as the [Registry].
#' @prop errors (Read-only)
#' A list mirroring the schema structure, with `NULL` for rules that pass and
#' character error messages for rules that fail.
#' @prop .validator_cache (Read-only)
#' An environment for caching validation results. Used to avoid redundant
#' validation.
#' @prop error
#' Boolean; whether to error upon failure (invalid data or schema).
#' @prop valid (Read-only)
#' Boolean; `TRUE` if the schema is valid and all data validation rules pass,
#' `FALSE`otherwise.
#' @returns
#' A `Validator` S7 object.
#' @details
#' The `Validator` class validates/transforms data using a `Schema`. The
#' process checks each field in the schema against the data, applying the
#' rules specified. Any data element not present in the schema is ignored.
#' Validation is done in four passes, according to rule categories in
#' the [Registry]: `control`, `transform`, `validate`, and `finalize`.
#'
#' Validation results are stored in the `@errors` property, and
#' the overall validity is indicated by the `@valid` property. If the
#' `@error` property/argument is set to `TRUE`, any validation failure will
#' result in an error being thrown. To customise the truncation of error
#' messages, see the [Schema] `@error_print_opts` property. The (possibly)
#' transformed data is stored in the `@data` property.
#'
#' The `Validator` is re-evaluated upon any change to the object properties.
#' If an invalid schema is provided, the validation will fail immediately with
#' the validation error indicating that the schema is invalid. To see the
#' errors in the schema validation, see the `Validator@Schema@errors` property.
#'
#' For full details see the vignettes on
#' [builtin rules](../doc/validation-rules.html),
#' [data validation](../doc/validating-data.html), and
#' [adding custom rules](../doc/custom-rules.html).
#' @seealso [Schema] and [Registry] classes, and [add_rule] for adding custom
#' rules.
#' @examples
#' v <- Validator(
#'   data = list(name = "Alice", age = 30),
#'   schema = list(
#'     name = list(type = "character", required = TRUE),
#'     age = list(type = "numeric", min_val = 0, max_val = 150)
#'   )
#' )
#' v@valid # TRUE
#'
#' # Schema object can be given directly
#' s <- Schema(list(a = list(type = "numeric"), b = list(type = "character")))
#' v <- Validator(list(a = "Hello", b = 42), s)
#' v@valid # FALSE
#' v@errors
#'
#' # To error on invalid schema or data
#' try(Validator(list(a = "Hello", b = 42), s, error = TRUE))
#'
#' # Invalid schemas show their errors
#' try(Validator(list(42), list(type = 123), error = TRUE))
#'
#' # Transforms data according to rules
#' v <- Validator(1, list(coerce = "character"))
#' v@data # "1"
#' @export
Validator <- S7::new_class(
  "Validator",
  package = "fluffy",
  properties = list(
    data = S7::new_property(
      setter = function(self, value) {
        .validator_data_arg_check(value)
        stop_if_rules_present(
          value,
          deep_prop(self, "Schema", "Registry", "rule_names")
        )
        cache <- S7::prop(self, ".validator_cache")
        cache$input <- value
        cache$result <- NULL
        self
      },
      getter = function(self) {
        res <- .get_validator(self)
        if (!is.null(res$data)) {
          res$data
        } else {
          S7::prop(self, ".validator_cache")$input
        }
      }
    ),
    Schema = new_property(
      setter = function(self, value) {
        if (!is.Schema(value)) {
          value <- Schema(value)
        }
        S7::prop(self, "Schema", check = TRUE) <- value
        .invalidate_validator(self)
      }
    ),
    errors = S7::new_property(
      getter = function(self) {
        .get_validator(self)$errors
      }
    ),
    .validator_cache = S7::new_property(
      setter = function(self, value) {
        if (!is.null(S7::prop(self, ".validator_cache"))) {
          stop(
            "Can't set read-only property <fluffy::Validator>@.validator_cache",
            call. = FALSE
          )
        }
        S7::prop(self, ".validator_cache", check = FALSE) <- value
        self
      }
    ),
    error = bool_prop,
    valid = S7::new_property(
      getter = function(self) {
        if (!nested_prop(self, "Schema", "valid")) {
          FALSE
        } else {
          is_list_all_null(.get_validator(self)$errors)
        }
      }
    )
  ),
  validator = function(self) {
    if (S7::prop(self, "error")) {
      if (!nested_prop(self, "Schema", "valid")) {
        format_errors_prop(
          nested_prop(self, "Schema", "errors"),
          nested_prop(self, "Schema", "error_print_opts")
        )
      } else if (!S7::prop(self, "valid")) {
        format_errors_prop(
          S7::prop(self, "errors"),
          nested_prop(self, "Schema", "error_print_opts"),
          obj = "Data",
          rule_names = deep_prop(self, "Schema", "Registry", "rule_names")
        )
      }
    }
  },
  constructor = function(
    data,
    schema,
    error = FALSE
  ) {
    # check data valid
    .validator_data_arg_check(data)

    cache <- new.env(parent = emptyenv())

    obj <- S7::new_object(
      S7::S7_object(),
      .validator_cache = cache,
      Schema = schema,
      error = FALSE
    )

    # error if data has named elements the same as rule names
    stop_if_rules_present(
      data,
      deep_prop(obj, "Schema", "Registry", "rule_names")
    )

    cache$input <- data
    cache$result <- NULL
    # set last to avoid triggering validation before object is fully constructed
    S7::prop(obj, "error", check = TRUE) <- error
    obj
  }
)

#' @rdname Validator
#' @export
is.Validator <- function(x) {
  S7::S7_inherits(x, Validator)
}
