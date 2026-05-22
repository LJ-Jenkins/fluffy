#-- min_length_larger_than_max_length

test_that("min_length < max_length passes", {
  expect_true(Schema(list(min_length = 1, max_length = 10))@valid)
  expect_true(Schema(list(min_length = 1, max_length = 1))@valid)
  expect_true(Schema(list(min_length = 5, max_length = 100))@valid)
})

test_that("min_length > max_length fails", {
  s <- Schema(list(min_length = 10, max_length = 1))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(
      min_length = "`min_length` must be smaller than `max_length`.",
      max_length = "`min_length` must be smaller than `max_length`."
    )
  )

  expect_error(
    Schema(list(min_length = 10, max_length = 1), error = TRUE)
  )
})

test_that("min_length cross rule skipped when individual rule fails", {
  s <- Schema(list(min_length = -1, max_length = 10))
  expect_false(s@valid)
  expect_true(is.character(s@errors$min_length))
  expect_null(s@errors$max_length)

  s <- Schema(list(min_length = 1, max_length = -5))
  expect_false(s@valid)
  expect_null(s@errors$min_length)
  expect_true(is.character(s@errors$max_length))

  s <- Schema(list(min_length = "bad", max_length = "bad"))
  expect_false(s@valid)
  expect_equal(
    s@errors$min_length,
    "Must be a single, positive, non-NA integerish value."
  )
  expect_equal(
    s@errors$max_length,
    "Must be a single, positive, non-NA integerish value."
  )
})

test_that("min_length cross rule skipped when only one rule present", {
  expect_true(Schema(list(min_length = 5))@valid)
  expect_true(Schema(list(max_length = 5))@valid)
})

test_that("min_length cross rule works in nested fields", {
  s <- Schema(list(
    outer = list(inner = list(min_length = 10, max_length = 1))
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors$outer$inner$min_length,
    "`min_length` must be smaller than `max_length`."
  )
  expect_equal(
    s@errors$outer$inner$max_length,
    "`min_length` must be smaller than `max_length`."
  )
})
