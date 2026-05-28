test_that(
  "add_rule attaches rule to Registry or objs containing",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fn <- function(x, y, ...) {}
    sfn <- function(field, ...) {}

    expect_no_error(r <- add_rule(r, "new_rule", fn))
    expect_equal(r@validator_rules$new_rule, fn)
    expect_equal(r@schema_rules$new_rule, sfn, ignore_function_env = TRUE)
    expect_true("new_rule" %in% r@validate_rules)
    expect_true("new_rule" %in% r@rule_names)

    expect_no_error(s <- add_rule(s, "new_rule", fn, rule_type = "control"))
    expect_equal(s@Registry@validator_rules$new_rule, fn)
    expect_equal(
      s@Registry@schema_rules$new_rule, sfn,
      ignore_function_env = TRUE
    )
    expect_true("new_rule" %in% s@Registry@control_rules)
    expect_true("new_rule" %in% s@Registry@rule_names)

    expect_no_error(v <- add_rule(v, "new_rule", fn, rule_type = "transform"))
    expect_equal(v@Schema@Registry@validator_rules$new_rule, fn)
    expect_equal(
      v@Schema@Registry@schema_rules$new_rule, sfn,
      ignore_function_env = TRUE
    )
    expect_true("new_rule" %in% v@Schema@Registry@transform_rules)
    expect_true("new_rule" %in% v@Schema@Registry@rule_names)

    expect_no_error(r <- add_rule(r, "new_frule", fn, rule_type = "finalize"))
    expect_equal(r@validator_rules$new_rule, fn)
    expect_equal(r@schema_rules$new_rule, sfn, ignore_function_env = TRUE)
    expect_true("new_frule" %in% r@finalize_rules)
    expect_true("new_frule" %in% r@rule_names)
  }
)

test_that("add_rule errors on non string rule name", {
  r <- Registry()
  s <- Schema(list(type = "integer"))
  v <- Validator(1L, s)
  fn <- function(x, y, ...) {}
  for (el in list(1L, NA_character_, NULL, "", c("a", "b"))) {
    expect_error(add_rule(r, el, fn))
    expect_error(add_rule(s, el, fn))
    expect_error(add_rule(v, el, fn))
  }
})

test_that("add_rule errors on non-function rules", {
  r <- Registry()
  s <- Schema(list(type = "integer"))
  v <- Validator(1L, s)
  for (el in list(1L, NA_character_, NULL, "", c("a", "b"))) {
    expect_error(add_rule(r, "not_a_function", el))
    expect_error(add_rule(s, "not_a_function", el))
    expect_error(add_rule(v, "not_a_function", el))
  }
  fn <- function(x, y, ...) {}
  for (el in list(1L, NA_character_, "", c("a", "b"))) {
    expect_error(add_rule(r, "not_a_function", fn, el))
    expect_error(add_rule(s, "not_a_function", fn, el))
    expect_error(add_rule(v, "not_a_function", fn, el))
  }
  expect_no_error(
    add_rule(r, "valid_rule", fn, NULL)
  )
  expect_no_error(
    add_rule(s, "valid_rule", fn, NULL)
  )
  expect_no_error(
    add_rule(v, "valid_rule", fn, NULL)
  )
})

test_that(
  "add_rule method errors on invalid validator function args",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fns <- list(
      too_few = function(x, y) {},
      no_dots = function(x, y, z) {},
      dots_and_keyword = function(x, .self, ...) {},
      dots_and_keyword2 = function(x, .data, ...) {},
      both_keywords_and_dots = function(x, .self, .data, ...) {},
      too_many = function(x, y, z, w, ...) {},
      wrong_keyword = function(x, .schema, ...) {}
    )
    for (fn in fns) {
      expect_error(add_rule(r, "fn_invalid_args", fn))
      expect_error(add_rule(s, "fn_invalid_args", fn))
      expect_error(add_rule(v, "fn_invalid_args", fn))
    }
  }
)

test_that(
  "add_rule method passes on valid validator function args",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fns <- list(
      args_and_dots = function(x, y, ...) {},
      args_dots_and_keyword = function(x, y, .self, ...) {},
      args_dots_and_keyword2 = function(x, y, .data, ...) {},
      args_both_keywords = function(x, y, .self, .data) {}
    )
    for (fn in fns) {
      expect_no_error(add_rule(r, "fn_valid_args", fn))
      expect_no_error(add_rule(s, "fn_valid_args", fn))
      expect_no_error(add_rule(v, "fn_valid_args", fn))
    }
  }
)

test_that(
  "add_rule method errors on invalid schema function args",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fns <- list(
      too_few = function(x) {},
      no_dots = function(x, y) {},
      dots_and_keyword = function(.self, ...) {},
      dots_and_keyword2 = function(.schema, ...) {},
      both_keywords_and_dots = function(.self, .schema, ...) {},
      too_many = function(x, y, z, ...) {},
      wrong_keyword = function(x, .data, ...) {}
    )
    vfn <- function(x, y, ...) {}
    for (fn in fns) {
      expect_error(add_rule(r, "fn_invalid_args", vfn, fn))
      expect_error(add_rule(s, "fn_invalid_args", vfn, fn))
      expect_error(add_rule(v, "fn_invalid_args", vfn, fn))
    }
  }
)

test_that(
  "add_rule method passes on valid schema function args",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fns <- list(
      arg_and_dots = function(x, ...) {},
      arg_dots_and_keyword = function(x, .self, ...) {},
      arg_dots_and_keyword2 = function(x, .schema, ...) {},
      arg_both_keywords = function(x, .self, .schema) {}
    )
    vfn <- function(x, y, ...) {}
    for (fn in fns) {
      expect_no_error(add_rule(r, "fn_invalid_args", vfn, fn))
      expect_no_error(add_rule(s, "fn_invalid_args", vfn, fn))
      expect_no_error(add_rule(v, "fn_invalid_args", vfn, fn))
    }
  }
)
