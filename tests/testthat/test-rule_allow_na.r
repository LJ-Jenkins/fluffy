test_that("Schema allow_na rule: FALSE passes, others fail", {
  expect_true(Schema(list(allow_na = FALSE))@valid)

  expect_false(Schema(list(allow_na = TRUE))@valid)
  expect_false(Schema(list(allow_na = NA))@valid)
  expect_false(Schema(list(allow_na = logical()))@valid)
  expect_false(Schema(list(allow_na = c(FALSE, FALSE)))@valid)
  expect_false(Schema(list(allow_na = "not_a_boolean"))@valid)
  expect_error(Schema(list(allow_na = NA), error = TRUE))
})

test_that("Validator allow_na rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(allow_na = FALSE)))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$allow_na, "No data for field.")
})

test_that("Validator allow_na rule: basic usage", {
  v <- Validator(
    list(a = c(NA, 1), b = -Inf, x = c(1, NA), y = c(NaN, 1), z = list(x = 1, y = 2)),
    Schema(list(
      a = list(allow_na = FALSE),
      b = list(allow_na = FALSE),
      x = list(allow_na = FALSE),
      y = list(allow_na = FALSE),
      z = list(allow_na = FALSE)
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      a = list(allow_na = "Value(s) cannot be `NA`."),
      b = list(allow_na = NULL),
      x = list(allow_na = "Value(s) cannot be `NA`."),
      y = list(allow_na = "Value(s) cannot be `NA`."),
      z = list(allow_na = NULL)
    )
  )
})
