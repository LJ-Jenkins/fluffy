#-- min_val_larger_than_max_val

test_that("min_val < max_val passes", {
  expect_true(Schema(list(min_val = 1, max_val = 10))@valid)
  expect_true(Schema(list(min_val = -5, max_val = 5))@valid)
  expect_true(Schema(list(min_val = 0, max_val = 0))@valid)
  expect_true(Schema(list(min_val = -1.5, max_val = 1.5))@valid)
})

test_that("min_val > max_val fails", {
  s <- Schema(list(min_val = 10, max_val = 1))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(
      min_val = "`min_val` must be smaller than `max_val`.",
      max_val = "`min_val` must be smaller than `max_val`."
    )
  )

  expect_error(
    Schema(list(min_val = 10, max_val = 1), error = TRUE)
  )
})

test_that("min_val cross rule skipped when individual rule fails", {
  # invalid min_val, valid max_val — cross rule should not fire
  s <- Schema(list(min_val = "not_numeric", max_val = 10))
  expect_false(s@valid)
  expect_true(is.character(s@errors$min_val))
  expect_null(s@errors$max_val)

  # valid min_val, invalid max_val
  s <- Schema(list(min_val = 1, max_val = "not_numeric"))
  expect_false(s@valid)
  expect_null(s@errors$min_val)
  expect_true(is.character(s@errors$max_val))

  # both invalid — cross rule should not fire, each has its own error
  s <- Schema(list(min_val = "bad", max_val = "bad"))
  expect_false(s@valid)
  expect_equal(s@errors$min_val, "Must be a single, non-NA numeric value.")
  expect_equal(s@errors$max_val, "Must be a single, non-NA numeric value.")
})

test_that("min_val cross rule skipped when only one rule present", {
  expect_true(Schema(list(min_val = 5))@valid)
  expect_true(Schema(list(max_val = 5))@valid)
})

test_that("min_val cross rule works in nested fields", {
  s <- Schema(list(
    outer = list(inner = list(min_val = 10, max_val = 1))
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors$outer$inner$min_val,
    "`min_val` must be smaller than `max_val`."
  )
  expect_equal(
    s@errors$outer$inner$max_val,
    "`min_val` must be smaller than `max_val`."
  )
})
