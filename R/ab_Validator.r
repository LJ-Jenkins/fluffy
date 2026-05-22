#' @title
#' Create a Validator Object
#' @description
#' An S7 class that validates R objects against a [Schema].
#' The `Validator` takes a `schema` (an object of class `Schema` or a `list`
#' that can be converted to a `Schema`) and validates input `data` against
#' the rules defined in the `schema`.
#' @param data
#' Any R object. If using a nested schema, the object must have the `[[` method
#' implemented.
#' @param schema
#' [Schema] object or a non-empty `list` defining the schema.
#' See the [Schema] constructor for details on the schema structure and rules.
#' @param error
#' single logical value. If `TRUE`, an error is thrown when the validation
#' fails.
#' @param x
#' object to be tested.
#' @returns
#' An S7 `Validator` object with the following properties:
#' \describe{
#'   \item{`data`}{The validated input data, with any changes that were
#'      made during validation.}
#'   \item{`Schema`}{An object of class [Schema]. This also contains the
#'      [Registry] used for validation, which can be accessed via
#'      `@Schema@Registry`.}
#'   \item{`errors`}{(Read only) A list mirroring the data or schema structure
#'     (depending on `match_schema` and `match_data`), with `NULL` for valid
#'     fields and character error messages for invalid ones. Extra fields
#'     showing missigness may be present when both `match_schema` and
#'     `match_data` are `TRUE`.}
#'   \item{`.validator_cache`}{(Internal, read only) An environment for caching
#'     validation results.}
#'   \item{`error`}{Boolean; whether to error upon failure
#'     (invalid data or schema).}
#'   \item{`valid`}{(Read only) Boolean; `TRUE` if schema is valid and all
#'     data validation rules pass, `FALSE` otherwise (invalid data or schema).}
#' }
#' @details
#' The validation process checks each field in the `schema` against the data,
#' creating an errors list that mirrors the schema structure with `NULL` for
#' valid fields and character error messages for invalid fields.
#'
#' These validation results are stored in the `@errors` property, and
#' the overall validity is indicated by the `@valid` property. If the
#' `@error` property/argument is set to `TRUE`, any validation failure will
#' result in an error being thrown. To customise the truncation of error
#' messages, see the `@Schema@error_print_opts` property.
#'
#' The `Validator` is re-evaluated upon any change to the object properties.
#' If an invalid schema is provided, the validation will fail immediately with
#' the validation error indicating that the schema is invalid. To see the
#' errors in the schema validation, see the `Validator@Schema@errors` property.
#'
#' See the [Schema] class for details on the schema class structure, and the
#' [Registry] class for details on the available validation rules.
#'
#' For full details see the
#' [validating data vignette](../doc/validating-data.html).
#' @seealso [add_rule] for adding rules to a registry.
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
#' v <- Validator(list("Hello", 42), s)
#' v@valid # FALSE
#' v@errors
#'
#' # To error on invalid schema or data
#' try(Validator(list("Hello", 42), s, error = TRUE))
#'
#' # Invalid schemas show their errors
#' try(Validator(list(42), list(type = 123), error = TRUE))
#' @export
Validator <- S7::new_class(
  "Validator",
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
