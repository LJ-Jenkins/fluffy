test_that("environment storage shared before rule addition", {
  r <- Registry()
  s <- Schema(list(type = "integer"), registry = r)
  v <- Validator(list(1L), schema = s)

  expect_equal(r@schema_rules, s@Registry@schema_rules)
  expect_equal(r@validator_rules, v@Schema@Registry@validator_rules)
})

test_that("adding rule copies env and doesn't mutate in place", {
  r <- Registry()
  s <- Schema(list(type = "integer"), registry = r)
  v <- Validator(list(1L), schema = s)
  fn <- function(x) {}
  fn2 <- function(x, y, ...) {}
  fn3 <- function(x, ...) {}

  r2 <- add_coerce_rule(r, "new_coerce_rule", fn)
  expect_equal(r2@coerce_map$new_coerce_rule, fn)
  expect_null(r@coerce_map$new_coerce_rule)
  expect_null(s@Registry@coerce_map$new_coerce_rule)
  expect_null(v@Schema@Registry@coerce_map$new_coerce_rule)
  expect_false(identical(r@coerce_map, r2@coerce_map))

  s2 <- add_type_rule(s, "new_type_rule", fn)
  expect_equal(s2@Registry@type_map$new_type_rule, fn)
  expect_null(s@Registry@type_map$new_type_rule)
  expect_null(v@Schema@Registry@type_map$new_type_rule)
  expect_false(identical(s@Registry@type_map, s2@Registry@type_map))

  v2 <- add_rule(v, "new_rule", fn2)
  expect_equal(v2@Schema@Registry@validator_rules$new_rule, fn2)
  expect_null(v@Schema@Registry@validator_rules$new_rule)
  expect_false(identical(
    v@Schema@Registry@validator_rules,
    v2@Schema@Registry@validator_rules
  ))

  r <- add_cross_rule(r, "new_cross_rule", c("type", "inherits"), fn3)
  expect_equal(r@cross_rules$new_cross_rule$fn, fn3)
  expect_null(s@Registry@cross_rules$new_cross_rule)
  expect_false(identical(r@cross_rules, s@Registry@cross_rules))
})
