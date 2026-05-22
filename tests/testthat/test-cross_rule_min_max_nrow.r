#-- min_nrow_larger_than_max_nrow

test_that("min_nrow < max_nrow passes", {
  expect_true(Schema(list(min_nrow = 1, max_nrow = 10))@valid)
  expect_true(Schema(list(min_nrow = 1, max_nrow = 1))@valid)
  expect_true(Schema(list(min_nrow = 5, max_nrow = 100))@valid)
})

test_that("min_nrow > max_nrow fails", {
  s <- Schema(list(min_nrow = 10, max_nrow = 1))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(
      min_nrow = "`min_nrow` must be smaller than `max_nrow`.",
      max_nrow = "`min_nrow` must be smaller than `max_nrow`."
    )
  )

  expect_error(
    Schema(list(min_nrow = 10, max_nrow = 1), error = TRUE)
  )
})

test_that("min_nrow cross rule skipped when individual rule fails", {
  s <- Schema(list(min_nrow = -1, max_nrow = 10))
  expect_false(s@valid)
  expect_true(is.character(s@errors$min_nrow))
  expect_null(s@errors$max_nrow)

  s <- Schema(list(min_nrow = 1, max_nrow = -5))
  expect_false(s@valid)
  expect_null(s@errors$min_nrow)
  expect_true(is.character(s@errors$max_nrow))

  s <- Schema(list(min_nrow = "bad", max_nrow = "bad"))
  expect_false(s@valid)
  expect_equal(
    s@errors$min_nrow,
    "Must be a single, positive, non-NA integerish value."
  )

  expect_equal(
    s@errors$max_nrow,
    "Must be a single, positive, non-NA integerish value."
  )
})

test_that("min_nrow cross rule skipped when only one rule present", {
  expect_true(Schema(list(min_nrow = 5))@valid)
  expect_true(Schema(list(max_nrow = 5))@valid)
})

test_that("min_nrow cross rule works in nested fields", {
  s <- Schema(list(
    outer = list(inner = list(min_nrow = 10, max_nrow = 1))
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(outer = list(inner = list(
      min_nrow = "`min_nrow` must be smaller than `max_nrow`.",
      max_nrow = "`min_nrow` must be smaller than `max_nrow`."
    )))
  )
})
