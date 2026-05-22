test_that("detects matching names in simple list", {
  targets <- Registry()@rule_names
  x <- list(
    required = 1,
    foo = 2,
    default = 3
  )

  expect_equal(
    collect_matching_names(x, targets),
    c("required", "default")
  )
})

test_that("detects matching names in nested lists", {
  targets <- Registry()@rule_names
  x <- list(
    a = list(
      dependency = 1,
      b = list(
        regex = 2
      )
    )
  )

  expect_equal(
    collect_matching_names(x, targets),
    c("dependency", "regex")
  )
})

test_that("detects matching column names in data.frame", {
  targets <- Registry()@rule_names
  df <- data.frame(
    type = 1:3,
    value = 4:6
  )

  x <- list(df = df)

  expect_equal(
    collect_matching_names(x, targets),
    "type"
  )
})

test_that("returns empty when no matches found", {
  targets <- Registry()@rule_names
  x <- list(
    a = 1,
    b = list(c = 2)
  )

  expect_equal(
    collect_matching_names(x, targets),
    character(0)
  )
})

test_that("returns unique matches only", {
  targets <- Registry()@rule_names
  x <- list(
    required = 1,
    nested = list(required = 2)
  )

  expect_equal(
    collect_matching_names(x, targets),
    "required"
  )
})

test_that("detects multiple different targets across structure", {
  targets <- Registry()@rule_names
  x <- list(
    required = 1,
    dependency = list(
      regex = 2,
      max_val = 10
    ),
    df = data.frame(
      min_length = 1:2,
      other = 3:4
    )
  )

  expect_equal(
    collect_matching_names(x, targets),
    c("required", "dependency", "regex", "max_val", "min_length")
  )
})

test_that("handles atomic vectors safely", {
  targets <- Registry()@rule_names
  x <- c(1, 2, 3)

  expect_equal(
    collect_matching_names(x, targets),
    character(0)
  )

  x <- c(required = 1, other = 2)
  expect_equal(
    collect_matching_names(x, targets),
    "required"
  )
})
