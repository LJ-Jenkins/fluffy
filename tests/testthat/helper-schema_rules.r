test_scalar_positive_integerish_rule <- function(rule_name) {
  make <- function(val) setNames(list(val), rule_name)

  for (val in c(1, 2)) {
    expect_true(Schema(make(val))@valid)
  }
  for (val in c(1L, 2L)) {
    expect_true(Schema(make(val))@valid)
  }

  for (val in c(0, 1.5, -1, NA, NaN, Inf, -Inf)) {
    expect_false(Schema(make(val))@valid)
  }
  expect_false(Schema(make(integer()))@valid)
  expect_false(Schema(make(c(1L, 2L)))@valid)
  expect_false(Schema(make("not_a_number"))@valid)
  expect_false(Schema(make(TRUE))@valid)
}

test_scalar_numeric_rule <- function(rule_name) {
  make <- function(val) setNames(list(val), rule_name)

  for (val in c(1, -1, 1.5, -1.5)) {
    expect_true(Schema(make(val))@valid)
  }
  for (val in c(1L, -1L)) {
    expect_true(Schema(make(val))@valid)
  }

  for (val in c(NA, NaN, Inf, -Inf)) {
    expect_false(Schema(make(val))@valid)
  }
  expect_false(Schema(make(integer()))@valid)
  expect_false(Schema(make(c(1L, 2L)))@valid)
  expect_false(Schema(make("not_a_number"))@valid)
  expect_false(Schema(make(TRUE))@valid)
}

test_non_empty_atomic_rule <- function(rule_name) {
  make <- function(val) setNames(list(val), rule_name)

  expect_true(Schema(make(c("a", "b", "c")))@valid)
  expect_false(Schema(make(list(1, "two", 3.0)))@valid)
  expect_true(Schema(make(NA))@valid)
  expect_true(Schema(make(123))@valid)

  expect_false(Schema(make(character(0)))@valid)
  expect_false(Schema(make(list(1:5, 6:10)))@valid)
  expect_error(Schema(make(list()), error = TRUE))
  expect_error(Schema(make(list(mean)), error = TRUE))
}
