test_that("Registry attaches class and accepts no args", {
  r <- Registry()
  expect_s7_class(r, Registry)
  expect_error(Registry(1L))
})

test_that("Registry editable props", {
  r <- Registry()
  expect_no_error(r@control_rules <- sort(r@control_rules))
  expect_no_error(r@transform_rules <- sort(r@transform_rules))
  expect_no_error(r@validate_rules <- sort(r@validate_rules))
  expect_no_error(r@finalize_rules <- sort(r@finalize_rules))
  expect_no_error(r@str_to_fn_rules <- c("type", "max_length"))
  expect_equal(r@str_to_fn_rules, c("type", "max_length"))
  expect_no_error(r@str_to_fn_converter <- function(x) x)
  expect_equal(r@str_to_fn_converter, function(x) x)
})

test_that("Registry uneditable props", {
  r <- Registry()
  expect_error(r@rule_names <- sort(r@rule_names))
  expect_error(r@type_names <- c("integer", "character"))
  expect_error(r@type_map <- new.env(parent = emptyenv()))
  expect_error(r@coerce_names <- c("integer", "character"))
  expect_error(r@coerce_map <- new.env(parent = emptyenv()))
  expect_error(r@schema_rule_names <- c("integer", "character"))
  expect_error(r@schema_rules <- new.env(parent = emptyenv()))
  expect_error(r@schema_cross_rule_names <- c("integer", "character"))
  expect_error(r@schema_cross_rules <- new.env(parent = emptyenv()))
  expect_error(r@validator_rule_names <- c("integer", "character"))
  expect_error(r@validator_rules <- new.env(parent = emptyenv()))
})

test_that("Registry errors on str_to_fn rule not in rule names", {
  r <- Registry()
  expect_error(r@str_to_fn_rules <- c(r@str_to_fn_rules, "not a rule"))
})

test_that("Registry errors on str_to_fn_converter without 1 fn arg", {
  r <- Registry()
  expect_error(r@str_to_fn_converter <- function(x, y) x)
  expect_error(r@str_to_fn_converter <- function() NULL)
  expect_no_error(r@str_to_fn_converter <- function(...) ...elt(1))
})

test_that("Registry errors on duplicate rule names", {
  r <- Registry()
  expect_error(r@transform_rules <- c(r@transform_rules, "default"))
  expect_error(r@finalize_rules <- "apply")
})

test_that("Registry errors on rule names not in validator/schema rules", {
  r <- Registry()
  expect_error(r@finalize_rules <- "not_a_rule")
  expect_error(r@finalize_rules <- c(r@finalize_rules, "not_a_rule"))
})

test_that(
  "Registry errors on validator/schema/cross rule not in rule names",
  {
    r <- Registry()
    # should never happen if using add_rule...
    attr(r, "validator_rules")$not_a_rule <- function(x) x
    expect_error(S7::validate(r))
    r <- Registry()
    attr(r, "schema_rules")$not_a_rule <- function(x) x
    expect_error(S7::validate(r))
    r <- Registry()
    attr(r, "cross_rules")$type <- function(x) x
    expect_error(S7::validate(r))
  }
)
