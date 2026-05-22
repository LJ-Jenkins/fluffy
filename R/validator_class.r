.validator_data_arg_check <- function(value) {
  if (is.data.frame(value) && nrow(value) == 0 || length(value) == 0) {
    stop(
      "<fluffy::Validator>@data cannot be empty",
      call. = FALSE
    )
  }
}

.invalidate_validator <- function(self) {
  cache <- S7::prop(self, ".validator_cache")
  cache$result <- NULL
  self
}

.get_validator <- function(self) {
  cache <- S7::prop(self, ".validator_cache")

  if (is.null(cache$result)) {
    cache$result <- .run_validator(self, cache)
  }
  cache$result
}

.run_validator <- function(self, cache) {
  data <- cache$input

  if (!nested_prop(self, "Schema", "valid")) {
    list(data = data, errors = list(valid_schema = FALSE))
  } else {
    validate_by_schema(
      data,
      nested_prop(self, "Schema", "schema"),
      deep_prop(self, "Schema", "Registry", "rule_names"),
      deep_prop(self, "Schema", "Registry", "control_rules"),
      deep_prop(self, "Schema", "Registry", "transform_rules"),
      deep_prop(self, "Schema", "Registry", "validate_rules"),
      deep_prop(self, "Schema", "Registry", "finalize_rules"),
      deep_prop(self, "Schema", "Registry", "validator_rules"),
      self
    )
  }
}
