.fl_control_rules <- c("required", "default")

.fl_transform_rules <- c("coerce", "apply")

.fl_validate_rules <- c(
  "type", "inherits", "allowed", "forbidden", "unique", "positive", "negative",
  "finite", "allow_na", "sorted",
  "min_val", "max_val", "min_length", "max_length", "min_nrow", "max_nrow",
  "min_nchar", "max_nchar", "nzchar", "regex", "levels",
  "ordered_levels", "dependency", "dependencies", "predicate"
)

.fl_finalize_rules <- c("coerce_last", "apply_last")

.fl_str_to_fn_rules <- c("apply", "apply_last", "predicate")

.fl_str_to_fn_converter <- function(str) {
  # attempt to convert a string to a function.
  # If it fails - return NULL, which will fail the is.function()
  # check, leave original string in place, and trigger an error message
  # from the (schema) rule validator.
  # This will evaluate arbitrary code which can make you vulnerable
  # to code injection if you pass user input to this function.
  # Use with extreme care!
  tryCatch(
    as.function(eval(str2lang(str))),
    error = function(cnd) {
      NULL
    }
  )
}

# just include base:: functions for now
# .fl_is.date <- function(x) inherits(x, c("Date", "POSIXlt", "POSIXct"))

.fl_type_map <- function() {
  list2env(list(
    array = is.array,
    atomic = is.atomic,
    call = is.call,
    character = is.character,
    complex = is.complex,
    data.frame = is.data.frame,
    # date = .fl_is.date,
    double = is.double,
    environment = is.environment,
    expression = is.expression,
    factor = is.factor,
    fn = is.function,
    integer = is.integer,
    language = is.language,
    list = is.list,
    logical = is.logical,
    matrix = is.matrix,
    name = is.name,
    numeric = is.numeric,
    object = is.object,
    ordered = is.ordered,
    pairlist = is.pairlist,
    raw = is.raw,
    recursive = is.recursive,
    symbol = is.symbol,
    table = is.table,
    vector = is.vector
  ))
}

.fl_coerce_map <- function() {
  list2env(list(
    array = as.array,
    call = as.call,
    character = as.character,
    complex = as.complex,
    data.frame = as.data.frame,
    date = as.Date,
    difftime = as.difftime,
    double = as.double,
    environment = as.environment,
    expression = as.expression,
    factor = as.factor,
    fn = as.function,
    integer = as.integer,
    list = as.list,
    logical = as.logical,
    matrix = as.matrix,
    name = as.name,
    numeric = as.numeric,
    ordered = as.ordered,
    pairlist = as.pairlist,
    POSIXct = as.POSIXct,
    POSIXlt = as.POSIXlt,
    raw = as.raw,
    symbol = as.symbol,
    table = as.table,
    vector = as.vector
  ))
}

#-- schema rules

.fl_schema_type_rule <- function(field, .self, ...) {
  if (is.function(field)) {
    if (length(formals(field)) != 1) {
      "Function must have one argument."
    }
  } else if (is.character(field)) {
    if (!is_nz_string(field)) {
      "Must be a length 1, non-NA character string."
    } else if (field %notin% nested_prop(.self, "Registry", "type_names")) {
      paste0("`", field, "` not found in allowed types.")
    }
  } else {
    "Must be a function or a string."
  }
}

.fl_schema_coerce_rule <- function(field, .self, ...) {
  if (is.function(field)) {
    if (length(formals(field)) != 1) {
      "Function must have one argument."
    }
  } else if (is.character(field)) {
    if (!is_nz_string(field)) {
      "Must be a length 1, non-NA character string."
    } else if (field %notin% nested_prop(.self, "Registry", "coerce_names")) {
      paste0("`", field, "` not found in allowed types.")
    }
  } else {
    "Must be a function or a string."
  }
}

.fl_schema_nz_chr_rule <- function(field, ...) {
  if (!is_nz_chr(field)) {
    "Must be a character vector with no NA's or empty strings."
  }
}

.fl_schema_bool_rule <- function(field, ...) {
  if (!is_bool(field)) {
    "Must be a single, non-NA logical value."
  }
}

.fl_schema_true_rule <- function(field, ...) {
  if (!isTRUE(field)) {
    "Must be `TRUE`."
  }
}

.fl_schema_false_rule <- function(field, ...) {
  if (!isFALSE(field)) {
    "Must be `FALSE`."
  }
}

.fl_schema_ne_atomic_rule <- function(field, ...) {
  if (!is_ne_atomic(field)) {
    "Must be a non-empty vector."
  }
}

.fl_schema_scalar_numeric_rule <- function(field, ...) {
  if (!is_scalar_numeric(field)) {
    "Must be a single, non-NA numeric value."
  }
}

.fl_schema_positive_scalar_integerish_rule <- function(field, ...) {
  if (!is_positive_scalar_numeric(field) || !is_integerish(field)) {
    "Must be a single, positive, non-NA integerish value."
  }
}

.fl_schema_nz_string_rule <- function(field, ...) {
  if (!is_nz_string(field)) {
    "Must be a length 1, non-NA character string."
  }
}

.fl_schema_dependency_rule <- function(field, ...) {
  if (is.list(field)) {
    if (!is_list_string_scalar_positive_integerish(field)) {
      paste(
        "Each list element must be all be either",
        "a string (name) or a positive integer (index)."
      )
    }
  } else if (is.numeric(field)) {
    if (
      length(field) == 0 || any(!is.finite(field)) ||
        any(field < 1) || any(!is_integerish(field))
    ) {
      "Indices must be positive integers."
    }
  } else if (is.character(field)) {
    if (length(field) == 0 || anyNA(field) || any(!nzchar(field))) {
      "Character inputs must have no NA's or empty strings."
    }
  } else {
    paste(
      "Must be a character, numeric, or list."
    )
  }
}

.fl_schema_dependencies_rule <- function(field, ...) {
  if (!is.list(field)) {
    return("Must be a list.")
  } else {
    for (i in seq_along(field)) {
      out <- .fl_schema_dependency_rule(field[[i]], ...)
      if (!is.null(out)) {
        return(paste0("For dependency ", i, ": ", out))
      }
    }
  }
  if (anyDuplicated(field)) {
    "Duplicate dependencies."
  }
}

.fl_schema_fn_rule <- function(field, ...) {
  if (!is.function(field)) {
    "Must be a function (or valid string)."
  }
}

.fl_schema_chr_rule <- function(field, ...) {
  if (!is.character(field)) {
    "Must be a character vector."
  }
}

# accept anything (except empty, picked up by validator)
.fl_schema_default_rule <- function(field, ...) {}

.fl_schema_rules <- function() {
  list2env(list(
    type = .fl_schema_type_rule,
    inherits = .fl_schema_nz_chr_rule,
    required = .fl_schema_bool_rule,
    allowed = .fl_schema_ne_atomic_rule,
    forbidden = .fl_schema_ne_atomic_rule,
    unique = .fl_schema_true_rule,
    positive = .fl_schema_true_rule,
    negative = .fl_schema_true_rule,
    finite = .fl_schema_true_rule,
    allow_na = .fl_schema_false_rule,
    sorted = .fl_schema_true_rule,
    min_val = .fl_schema_scalar_numeric_rule,
    max_val = .fl_schema_scalar_numeric_rule,
    min_length = .fl_schema_positive_scalar_integerish_rule,
    max_length = .fl_schema_positive_scalar_integerish_rule,
    min_nrow = .fl_schema_positive_scalar_integerish_rule,
    max_nrow = .fl_schema_positive_scalar_integerish_rule,
    min_nchar = .fl_schema_positive_scalar_integerish_rule,
    max_nchar = .fl_schema_positive_scalar_integerish_rule,
    nzchar = .fl_schema_true_rule,
    regex = .fl_schema_nz_string_rule,
    levels = .fl_schema_chr_rule,
    ordered_levels = .fl_schema_chr_rule,
    coerce = .fl_schema_coerce_rule,
    dependency = .fl_schema_dependency_rule,
    dependencies = .fl_schema_dependencies_rule,
    predicate = .fl_schema_fn_rule,
    apply = .fl_schema_fn_rule,
    apply_last = .fl_schema_fn_rule,
    coerce_last = .fl_schema_coerce_rule,
    default = .fl_schema_default_rule
  ))
}

#-- cross-rules

# cross rules are checked after individual rules, so cross rules only
# apply for fields where the individual rules are valid.
# This means that cross rule functions can assume correct type/size/etc.

.fl_cross_fn_dependency_and_dependencies <- function(node, ...) {
  if (!is.null(node$dependency) && !is.null(node$dependencies)) {
    "Cannot have both `dependency` and `dependencies` rules."
  }
}

.fl_cross_rule_dependency_and_dependencies <- list(
  rules = c("dependency", "dependencies"),
  fn = .fl_cross_fn_dependency_and_dependencies
)

.fl_cross_fn_required_and_default <- function(node, ...) {
  if (node$required && !is.null(node$default)) {
    "Cannot have `required` as TRUE and a `default` value."
  }
}

.fl_cross_rule_required_and_default <- list(
  rules = c("required", "default"),
  fn = .fl_cross_fn_required_and_default
)

.fl_cross_fn_positive_and_negative <- function(node, ...) {
  if (node$positive && node$negative) {
    "Cannot have both `positive` and `negative` rules."
  }
}

.fl_cross_rule_positive_and_negative <- list(
  rules = c("positive", "negative"),
  fn = .fl_cross_fn_positive_and_negative
)

.fl_cross_fn_min_val_larger_than_max_val <- function(node, ...) {
  if (node$min_val > node$max_val) {
    "`min_val` must be smaller than `max_val`."
  }
}

.fl_cross_rule_min_val_larger_than_max_val <- list(
  rules = c("min_val", "max_val"),
  fn = .fl_cross_fn_min_val_larger_than_max_val
)

.fl_cross_fn_min_length_larger_than_max_length <- function(node, ...) {
  if (node$min_length > node$max_length) {
    "`min_length` must be smaller than `max_length`."
  }
}

.fl_cross_rule_min_length_larger_than_max_length <- list(
  rules = c("min_length", "max_length"),
  fn = .fl_cross_fn_min_length_larger_than_max_length
)

.fl_cross_fn_min_nrow_larger_than_max_nrow <- function(node, ...) {
  if (node$min_nrow > node$max_nrow) {
    "`min_nrow` must be smaller than `max_nrow`."
  }
}

.fl_cross_rule_min_nrow_larger_than_max_nrow <- list(
  rules = c("min_nrow", "max_nrow"),
  fn = .fl_cross_fn_min_nrow_larger_than_max_nrow
)

.fl_cross_fn_min_nchar_larger_than_max_nchar <- function(node, ...) {
  if (node$min_nchar > node$max_nchar) {
    "`min_nchar` must be smaller than `max_nchar`."
  }
}

.fl_cross_rule_min_nchar_larger_than_max_nchar <- list(
  rules = c("min_nchar", "max_nchar"),
  fn = .fl_cross_fn_min_nchar_larger_than_max_nchar
)

.fl_cross_fn_allowed_and_forbidden_overlap <- function(node, ...) {
  if (any(node$allowed %in% node$forbidden, na.rm = TRUE)) {
    "Values in `allowed` and `forbidden` must not overlap."
  }
}

.fl_cross_rule_allowed_and_forbidden_overlap <- list(
  rules = c("allowed", "forbidden"),
  fn = .fl_cross_fn_allowed_and_forbidden_overlap
)

.fl_cross_fn_allowed_type_mismatch <- function(node, ...) {
  if (node$type %notin% class(node$allowed)) {
    "Values in `allowed` must be of the type specified in `type`."
  }
}

.fl_cross_rule_allowed_type_mismatch <- list(
  rules = c("type", "allowed"),
  fn = .fl_cross_fn_allowed_type_mismatch
)

.fl_cross_fn_forbidden_type_mismatch <- function(node, ...) {
  if (node$type %notin% class(node$forbidden)) {
    "Values in `forbidden` must be of the type specified in `type`."
  }
}

.fl_cross_rule_forbidden_type_mismatch <- list(
  rules = c("type", "forbidden"),
  fn = .fl_cross_fn_forbidden_type_mismatch
)

.fl_schema_cross_rules <- function() {
  list2env(list(
    dependency_and_dependencies = .fl_cross_rule_dependency_and_dependencies,
    positive_and_negative = .fl_cross_rule_positive_and_negative,
    required_and_default = .fl_cross_rule_required_and_default,
    min_val_larger_than_max_val = .fl_cross_rule_min_val_larger_than_max_val,
    min_length_larger_than_max_length = .fl_cross_rule_min_length_larger_than_max_length,
    min_nrow_larger_than_max_nrow = .fl_cross_rule_min_nrow_larger_than_max_nrow,
    min_nchar_larger_than_max_nchar = .fl_cross_rule_min_nchar_larger_than_max_nchar,
    allowed_and_forbidden_overlap = .fl_cross_rule_allowed_and_forbidden_overlap,
    allowed_type_mismatch = .fl_cross_rule_allowed_type_mismatch,
    forbidden_type_mismatch = .fl_cross_rule_forbidden_type_mismatch
  ))
}

#-- validator rules

.fl_validator_type_rule <- function(field, schema_field, .self, ...) {
  if (is.character(schema_field)) {
    fn <- get0(
      schema_field,
      envir = deep_prop(.self, "Schema", "Registry", "type_map")
    )
    if (!fn(field)) {
      list(error = paste0("Is not type `", schema_field, "`."))
    }
  } else {
    if (!schema_field(field)) {
      list(error = "Is not expected type.")
    }
  }
}

.fl_validator_inherits_rule <- function(field, schema_field, ...) {
  if (!inherits(field, schema_field)) {
    if (length(schema_field) == 1) {
      list(error = paste0("Does not inherit from class `", schema_field, "`."))
    } else {
      list(
        error = paste0(
          "Does not inherit from classes ", backtick(schema_field), "."
        )
      )
    }
  }
}

.fl_validator_required_rule <- function(field, schema_field, ...) {
  if (schema_field && is.null(field)) {
    # if required is TRUE and field is missing
    list(error = "Field not present.", continue = FALSE)
  } else if (!schema_field && is.null(field)) {
    # if required is FALSE and field is missing, skip other rules
    list(continue = FALSE)
  }
}

.fl_validator_allowed_rule <- function(field, schema_field, ...) {
  if (any(field %notin% schema_field, na.rm = TRUE)) {
    list(error = "Contains value(s) not in allowed set.")
  }
}

.fl_validator_forbidden_rule <- function(field, schema_field, ...) {
  if (any(field %in% schema_field, na.rm = TRUE)) {
    list(error = "Contains value(s) in forbidden set.")
  }
}

.fl_validator_unique_rule <- function(field, schema_field, ...) {
  # schema rule only accepts TRUE, so don't need to if(schema_field) check here
  if (anyDuplicated(field)) {
    list(error = "Contains duplicates.")
  }
}

.fl_validator_positive_rule <- function(field, schema_field, ...) {
  if (any(field < 0, na.rm = TRUE)) {
    list(error = "Value(s) must be positive (or zero).")
  }
}

.fl_validator_negative_rule <- function(field, schema_field, ...) {
  if (any(field > 0, na.rm = TRUE)) {
    list(error = "Value(s) must be negative (or zero).")
  }
}

.fl_validator_finite_rule <- function(field, schema_field, ...) {
  if (any(!is.finite(field), na.rm = TRUE)) {
    list(error = "Value(s) must be finite.")
  }
}

.fl_validator_allow_na_rule <- function(field, schema_field, ...) {
  if (anyNA(field)) {
    list(error = "Value(s) cannot be `NA`.")
  }
}

.fl_validator_sorted_rule <- function(field, schema_field, ...) {
  if (!is.atomic(field)) {
    list(error = "Must be an atomic type.")
  } else if (is.unsorted(field, na.rm = TRUE)) {
    list(error = "Values are not sorted.")
  }
}

.fl_validator_min_val_rule <- function(field, schema_field, ...) {
  if (any(field < schema_field, na.rm = TRUE)) {
    list(error = paste0("Value(s) must be at least ", schema_field, "."))
  }
}

.fl_validator_max_val_rule <- function(field, schema_field, ...) {
  if (any(field > schema_field, na.rm = TRUE)) {
    list(error = paste0("Value(s) must be at most ", schema_field, "."))
  }
}

.fl_validator_min_length_rule <- function(field, schema_field, ...) {
  if (length(field) < schema_field) {
    list(error = paste0("Length must be at least ", schema_field, "."))
  }
}

.fl_validator_max_length_rule <- function(field, schema_field, ...) {
  if (length(field) > schema_field) {
    list(error = paste0("Length must be at most ", schema_field, "."))
  }
}

.fl_validator_min_nrow_rule <- function(field, schema_field, ...) {
  n <- nrow(field)
  if (is.null(n)) {
    return(list(error = "Type not applicable for `nrow()`."))
  } else if (n < schema_field) {
    return(
      list(
        error = paste0("Number of rows must be at least ", schema_field, ".")
      )
    )
  }
  NULL
}

.fl_validator_max_nrow_rule <- function(field, schema_field, ...) {
  n <- nrow(field)
  if (is.null(n)) {
    return(list(error = "Type not applicable for `nrow()`."))
  } else if (n > schema_field) {
    return(
      list(
        error = paste0("Number of rows must be at most ", schema_field, ".")
      )
    )
  }
  NULL
}

.fl_validator_min_nchar_rule <- function(field, schema_field, ...) {
  if (any(nchar(field) < schema_field, na.rm = TRUE)) {
    list(error = paste0("Char length(s) must be at least ", schema_field, "."))
  }
}

.fl_validator_max_nchar_rule <- function(field, schema_field, ...) {
  if (any(nchar(field) > schema_field, na.rm = TRUE)) {
    list(error = paste0("Char length(s) must be at most ", schema_field, "."))
  }
}

.fl_validator_nzchar_rule <- function(field, schema_field, ...) {
  if (any(!nzchar(field), na.rm = TRUE)) {
    list(error = "Contains empty string(s).")
  }
}

.fl_validator_regex_rule <- function(field, schema_field, ...) {
  if (any(!grepl(schema_field, field), na.rm = TRUE)) {
    list(
      error = paste0(
        "String(s) do not match regex pattern `", schema_field, "`."
      )
    )
  }
}

.fl_validator_levels_rule <- function(field, schema_field, ...) {
  if (!identical(sort(levels(field)), sort(schema_field))) {
    list(error = "Levels do not match.")
  }
}

.fl_validator_ordered_levels_rule <- function(field, schema_field, ...) {
  if (!identical(levels(field), schema_field)) {
    list(error = "Levels do not match.")
  }
}

.fl_validator_coerce_rule <- function(field, schema_field, .self, ...) {
  if (is.character(schema_field)) {
    schema_field <- get0(
      schema_field,
      envir = deep_prop(.self, "Schema", "Registry", "coerce_map")
    )
  }
  list(data = schema_field(field))
}

.fl_validator_dependency_rule <- function(field, schema_field, .data, ...) {
  if (!is.list(.data)) {
    list(error = "rule only operates on list-like data inputs.")
  } else if (!has_nested_element(.data, schema_field)) {
    list(error = paste0("Missing `data", paste_as_path(schema_field), "`."))
  }
}

.fl_validator_dependencies_rule <- function(field, schema_field, .data, ...) {
  if (!is.list(.data)) {
    list(error = "rule only operates on list-like data inputs.")
  } else {
    for (path in schema_field) {
      if (!has_nested_element(.data, path)) {
        return(
          list(error = paste0("Missing `data", paste_as_path(path), "`."))
        )
      }
    }
  }
}

.fl_validator_predicate_rule <- function(field, schema_field, ...) {
  res <- if (length(formals(schema_field)) == 1L) {
    schema_field(field)
  } else {
    schema_field(field, ...)
  }

  if (!is_bool(res)) {
    list(error = "Returned non-boolean.")
  } else if (!res) {
    list(error = "Does not satisfy predicate.")
  }
}

.fl_validator_apply_rule <- function(field, schema_field, ...) {
  if (length(formals(schema_field)) == 1L) {
    list(data = schema_field(field))
  } else {
    list(data = schema_field(field, ...))
  }
}

.fl_validator_default_rule <- function(field, schema_field, ...) {
  if (is.null(field)) {
    list(data = schema_field, continue = FALSE)
  }
}

.fl_validator_rules <- function() {
  list2env(list(
    type = .fl_validator_type_rule,
    inherits = .fl_validator_inherits_rule,
    required = .fl_validator_required_rule,
    allowed = .fl_validator_allowed_rule,
    forbidden = .fl_validator_forbidden_rule,
    unique = .fl_validator_unique_rule,
    positive = .fl_validator_positive_rule,
    negative = .fl_validator_negative_rule,
    finite = .fl_validator_finite_rule,
    allow_na = .fl_validator_allow_na_rule,
    sorted = .fl_validator_sorted_rule,
    min_val = .fl_validator_min_val_rule,
    max_val = .fl_validator_max_val_rule,
    min_length = .fl_validator_min_length_rule,
    max_length = .fl_validator_max_length_rule,
    min_nrow = .fl_validator_min_nrow_rule,
    max_nrow = .fl_validator_max_nrow_rule,
    min_nchar = .fl_validator_min_nchar_rule,
    max_nchar = .fl_validator_max_nchar_rule,
    nzchar = .fl_validator_nzchar_rule,
    regex = .fl_validator_regex_rule,
    levels = .fl_validator_levels_rule,
    ordered_levels = .fl_validator_ordered_levels_rule,
    coerce = .fl_validator_coerce_rule,
    coerce_last = .fl_validator_coerce_rule,
    dependency = .fl_validator_dependency_rule,
    dependencies = .fl_validator_dependencies_rule,
    predicate = .fl_validator_predicate_rule,
    apply = .fl_validator_apply_rule,
    apply_last = .fl_validator_apply_rule,
    default = .fl_validator_default_rule
  ))
}

#-- helper

#' @title
#' Show fluffy Builtin Rules
#' @description
#' Helper to show the builtin rules in a Registry, and their behaviour.
#' @param rules
#' Which builtin rules to show. `"validation"` for the
#' standard schema/data validation rules, `"cross"` for the cross rules that
#' check for consistency between rules, or `"all"` to show both.
#' @returns
#' List of data.fames if `rules = "all"`, otherwise a single data.frame,
#' with information on the builtin rules for the rule type specified.
#' The data.frame(s) have an attached class `fluffy_rule_info`.
#' @note
#' The `fluffy_rule_info` class has a custom print method that formats the
#' data.frame(s) in a more readable way. The output of this function is only
#' intended to be used for display/interactive purposes.
#' @seealso
#' [Registry] and [add_rule].
#' @examples
#' show_builtins()
#' @export
show_builtins <- function(rules = c("all", "validation", "cross")) {
  rules <- match.arg(rules)

  vrules <- c(
    "required", "default", "apply", "coerce",
    "type", "inherits", "allowed", "forbidden",
    "unique", "positive", "negative", "finite",
    "allow_na", "sorted", "min_val", "max_val", "min_length",
    "max_length", "min_nrow", "max_nrow", "min_nchar",
    "max_nchar", "nzchar", "regex",
    "levels", "ordered_levels", "dependency", "dependencies",
    "predicate", "apply_last", "coerce_last"
  )

  schema_validation <- c(
    "boolean.",
    "non-empty.",
    "function or a valid string.",
    "1 arg function or a valid string.",
    "1 arg function or a valid string.",
    "character vector.",
    "non-empty vector.",
    "non-empty vector.",
    "TRUE.",
    "TRUE.",
    "TRUE.",
    "TRUE.",
    "FALSE.",
    "TRUE.",
    "finite numeric value.",
    "finite numeric value.",
    "positive integerish value.",
    "positive integerish value.",
    "positive integerish value.",
    "positive integerish value.",
    "positive integerish value.",
    "positive integerish value.",
    "boolean.",
    "string.",
    "character vector.",
    "character vector.",
    "character vector, or integerish vector, or list of string/integerish scalars.",
    "list of character vectors, or integerish vectors, or lists of string/integerish scalars.",
    "function or a valid string.",
    "function or a valid string.",
    "1 arg function or a valid string."
  )

  data_validation <- c(
    "exists.",
    "exists and inserts `default` if not.",
    "applies function.",
    "coerces.",
    "type.",
    "inherits from specified classes.",
    "only values in `allowed` set.",
    "no values in `forbidden` set.",
    "no duplicates.",
    "is positive (or zero).",
    "is negative (or zero).",
    "is finite.",
    "no `NA` values.",
    "is sorted.",
    "values at least `min_val`.",
    "values at most `max_val`.",
    "length at least `min_length`.",
    "length at most `max_length`.",
    "nrow at least `min_nrow`.",
    "nrow at most `max_nrow`.",
    "nchar at least `min_nchar`.",
    "nchar at most `max_nchar`.",
    "no empty strings.",
    "matches `regex` pattern.",
    "has levels matching `levels` in any order.",
    "has levels matching `ordered_levels` in order.",
    "dependency field present.",
    "dependency fields present.",
    "satisfies predicate function.",
    "applies function if no errors in node.",
    "coerces if no errors in node."
  )

  control_flow <- c(
    "FALSE and element not present.",
    "default is used.",
    rep("", length(vrules) - 2L)
  )

  validation_rules <- data.frame(
    Rule = c("", paste0("`", vrules, "`")),
    "Schema operation" = c("Checks schema value is:", schema_validation),
    "Data operation" = c("Checks/transforms data element:", data_validation),
    "Control flow" = c("Stops other rules if:", control_flow),
    check.names = FALSE
  )

  crules <- c(
    "dependency_and_dependencies",
    "required_and_default",
    "positive_and_negative",
    "min_val_larger_than_max_val",
    "min_length_larger_than_max_length",
    "min_nrow_larger_than_max_nrow",
    "min_nchar_larger_than_max_nchar",
    "allowed_and_forbidden_overlap",
    "allowed_type_mismatch",
    "forbidden_type_mismatch"
  )

  cross_validation <- c(
    "`dependency` and `dependencies` rules aren't both present.",
    "if `required` is TRUE that a `default` value is not provided.",
    "`positive` and `negative` rules aren't both present.",
    "`min_val` is smaller than `max_val`.",
    "`min_length` is smaller than `max_length`.",
    "`min_nrow` is smaller than `max_nrow`.",
    "`min_nchar` is smaller than `max_nchar`.",
    "values in `allowed` and `forbidden` do not overlap.",
    "values in `allowed` are of the type specified in `type`.",
    "values in `forbidden` are of the type specified in `type`."
  )

  cross_rules <- data.frame(
    "Cross rule" = c(" ", paste0("`", crules, "`")),
    "Schema operation" = c("Checks in a schema node that:", cross_validation),
    check.names = FALSE
  )

  as_fluffy_info <- function(x) {
    structure(x, class = c("fluffy_rule_info", class(x)))
  }

  if (rules == "all") {
    list(
      validation_rules = as_fluffy_info(validation_rules),
      cross_rules = as_fluffy_info(cross_rules)
    )
  } else if (rules == "validation") {
    as_fluffy_info(validation_rules)
  } else if (rules == "cross") {
    as_fluffy_info(cross_rules)
  }
}
