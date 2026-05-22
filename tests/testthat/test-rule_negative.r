test_that("Schema negative rule: TRUE passes, others fail", {
  expect_true(Schema(list(negative = TRUE))@valid)

  expect_false(Schema(list(negative = FALSE))@valid)
  expect_false(Schema(list(negative = NA))@valid)
  expect_false(Schema(list(negative = logical()))@valid)
  expect_false(Schema(list(negative = c(TRUE, TRUE)))@valid)
  expect_false(Schema(list(negative = "not_a_boolean"))@valid)
  expect_error(Schema(list(negative = NA), error = TRUE))
})

test_that("Validator negative rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(negative = TRUE)))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$negative, "No data for field.")
})

test_that("Validator negative rule: basic usage", {
  v <- Validator(
    list(x = c(1, -1), y = c(0, -1), z = list(x = -1, y = -2)),
    Schema(list(
      x = list(negative = TRUE),
      y = list(negative = TRUE),
      z = list(negative = TRUE)
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      x = list(negative = "Value(s) must be negative (or zero)."),
      y = list(negative = NULL),
      z = list(negative = NULL)
    )
  )
})
