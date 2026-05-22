#-- min_nchar_larger_than_max_nchar

test_that("min_nchar < max_nchar passes", {
  expect_true(Schema(list(min_nchar = 1, max_nchar = 10))@valid)
  expect_true(Schema(list(min_nchar = 1, max_nchar = 1))@valid)
  expect_true(Schema(list(min_nchar = 5, max_nchar = 100))@valid)
})

test_that("min_nchar > max_nchar fails", {
  s <- Schema(list(min_nchar = 10, max_nchar = 1))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(
      min_nchar = "`min_nchar` must be smaller than `max_nchar`.",
      max_nchar = "`min_nchar` must be smaller than `max_nchar`."
    )
  )

  expect_error(
    Schema(list(min_nchar = 10, max_nchar = 1), error = TRUE)
  )
})

test_that("min_nchar cross rule skipped when individual rule fails", {
  s <- Schema(list(min_nchar = -1, max_nchar = 10))
  expect_false(s@valid)
  expect_true(is.character(s@errors$min_nchar))
  expect_null(s@errors$max_nchar)

  s <- Schema(list(min_nchar = 1, max_nchar = -5))
  expect_false(s@valid)
  expect_null(s@errors$min_nchar)
  expect_true(is.character(s@errors$max_nchar))

  s <- Schema(list(min_nchar = "bad", max_nchar = "bad"))
  expect_false(s@valid)
  expect_equal(s@errors$min_nchar, "Must be a single, positive, non-NA integerish value.")
  expect_equal(s@errors$max_nchar, "Must be a single, positive, non-NA integerish value.")
})

test_that("min_nchar cross rule skipped when only one rule present", {
  expect_true(Schema(list(min_nchar = 5))@valid)
  expect_true(Schema(list(max_nchar = 5))@valid)
})

test_that("min_nchar cross rule works in nested fields", {
  s <- Schema(list(
    outer = list(inner = list(min_nchar = 10, max_nchar = 1))
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors$outer$inner$min_nchar,
    "`min_nchar` must be smaller than `max_nchar`."
  )
  expect_equal(
    s@errors$outer$inner$max_nchar,
    "`min_nchar` must be smaller than `max_nchar`."
  )
})
