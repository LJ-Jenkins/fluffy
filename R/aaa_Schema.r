#' @title
#' Create a Schema Object
#' @description
#' An S7 class that defines and validates a schema for the future
#' validation of R objects against it, using a [Validator].
#' @param schema
#' non-empty list defining the schema. Each leaf element to be
#' validated must be named with rules that are registered in the schema rule
#' registry (see [Registry] and [add_rule]). Named elements must be unique
#' at a given level of the list.
#' @param registry
#' object of class [Registry] containing the schema and validator rules to
#' use for schema validation. If not provided, the default registry with
#' builtin rules will be used.
#' @param error
#' single logical value. If `TRUE`, the constructor throws
#' an error when the schema is invalid.
#' @param ...
#' named arguments passed to internal error message formatting functions:
#' `max_depth`, `max_width`, `max_rows`, and `UTF8` which control the
#' truncation and printing of the error message when the schema
#' validation fails. `max_` arguments accept integerish scalar values,
#' and `UTF8` accepts a single logical value. Unnamed arguments or
#' names other than the above will be ignored. Stored in the
#' `error_print_opts` property.
#' @param x
#' object to be tested.
#' @returns
#' An S7 `Schema` object with the following properties:
#' \describe{
#'   \item{`schema`}{The input schema list, with strings converted to
#'     functions where applicable.}
#'   \item{`errors`}{(Read only) A list mirroring the schema structure,
#'     with `NULL` for valid rules and character error messages for
#'     invalid ones.}
#'   \item{`Registry`}{An object of class [Registry] containing the
#'     schema and validator rules used for validation.}
#'   \item{`.schema_cache`}{(Internal, read only) An environment for caching
#'     schema validation results.}
#'   \item{`error`}{Boolean; whether to error on invalid schemas.}
#'   \item{`error_print_opts`}{A list of options for error message printing
#'     when `error = TRUE`. Options are `max_depth`, `max_width`, `max_rows`,
#'     and `UTF8`, which control the truncation and printing of the error
#'     message when validation fails. These options are also used by the
#'     Validator class that ingests the Schema.}
#'   \item{`valid`}{(Read only) Boolean; `TRUE` if schema is valid, `FALSE`
#'     otherwise.}
#' }
#' @details
#' Each element of the input list represents a field with named rules
#' (e.g., `'type'`, `'required'`, `'min_val'`) that are checked against the
#' schema rule registry. Cross rules (e.g., `'min_val_larger_than_max_val'`,
#' where `'min_val'` < `'max_val'`) are also evaluated when all constituent
#' rules pass individually.
#'
#' The schema is re-evaluated upon any change to the schema properties,
#' with the `@valid` property indicates whether the schema is valid
#' (all rules pass) or invalid (any rule fails). If invalid, when passed
#' to a [Validator] the validation will fail immediately.
#'
#' See the [Registry] class for details on the available rules and how to
#' customise them. See the [Validator] class for details on how to use a
#' `Schema` to validate data.
#'
#' For full details see the
#' [validating data vignette](../doc/validating-data.html).
#' @seealso [add_rule] for adding rules to a registry.
#' @examples
#' # A valid schema
#' s <- Schema(list(
#'   name = list(type = "character", required = TRUE),
#'   age = list(type = "numeric", min_val = 0, max_val = 150)
#' ))
#' s@valid # TRUE
#'
#' # An invalid schema (type must be a string)
#' s <- Schema(list(name = list(type = 123)))
#' s@valid # FALSE
#' s@errors # error message
#'
#' # To error on invalid schema
#' try(Schema(list(name = list(type = 123)), error = TRUE))
#' @export
Schema <- S7::new_class(
  "Schema",
  # see S7 github issues #416, #450, #525, etc.
  # used to have setters as well as class and validators,
  # but dynamic properties are never validated in S7,
  # so have moved all validation within.
  properties = list(
    schema = S7::new_property(
      # no class_list as dynamic properties in S7 can't be validated;
      # see above.
      setter = function(self, value) {
        .schema_input_check(value)

        # get the cache environment and use `$` instead of `@`, e.g.:
        # cache$result <- NULL instead of self@.schema_cache$result <- NULL
        # to avoid triggering the setter; we want the setter to stop users
        # editing, but we want to edit (in place) within the object.
        cache <- S7::prop(self, ".schema_cache")
        cache$input <- value
        cache$result <- NULL
        self
      },
      getter = function(self) {
        res <- .get_schema(self)
        if (!is.null(res$data)) {
          res$data
        } else {
          S7::prop(self, ".schema_cache")$input
        }
      }
    ),
    errors = S7::new_property(
      getter = function(self) {
        .get_schema(self)$errors
      }
    ),
    Registry = Registry,
    .schema_cache = S7::new_property(
      setter = function(self, value) {
        if (!is.null(S7::prop(self, ".schema_cache"))) {
          stop(
            "Can't set read-only property <fluffy::Schema>@.schema_cache",
            call. = FALSE
          )
        }
        # our assignment doesn't need to be checked
        # uneditable after
        S7::prop(self, ".schema_cache", check = FALSE) <- value
        self
      }
    ),
    error = bool_prop,
    error_print_opts = error_print_opts_prop("Schema"),
    valid = S7::new_property(
      getter = function(self) {
        is_list_all_null(.get_schema(self)$errors)
      }
    )
  ),
  validator = function(self) {
    if (S7::prop(self, "error") && !S7::prop(self, "valid")) {
      format_errors_prop(
        S7::prop(self, "errors"),
        S7::prop(self, "error_print_opts")
      )
    }
  },
  constructor = function(schema, registry = Registry(), error = FALSE, ...) {
    .schema_input_check(schema)
    cache <- new.env(parent = emptyenv())

    obj <- S7::new_object(
      S7::S7_object(),
      Registry = registry,
      .schema_cache = cache,
      error = FALSE
    )

    # to_print_opts() is in the setter
    # so we can change warning message if opts passed in constructor (dots)
    # vs later editing through assignment
    S7::prop(obj, "error_print_opts", check = FALSE) <- list(...)

    # now safe: cache exists
    cache$input <- schema
    cache$result <- NULL
    S7::prop(obj, "error", check = TRUE) <- error
    obj
  }
)

#' @rdname Schema
#' @export
is.Schema <- function(x) {
  S7::S7_inherits(x, Schema)
}
