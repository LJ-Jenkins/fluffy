test_that("Schema finite rule: TRUE passes, others fail", {
  expect_true(Schema(list(finite = TRUE))@valid)

  expect_false(Schema(list(finite = FALSE))@valid)
  expect_false(Schema(list(finite = NA))@valid)
  expect_false(Schema(list(finite = logical()))@valid)
  expect_false(Schema(list(finite = c(TRUE, TRUE)))@valid)
  expect_false(Schema(list(finite = "not_a_boolean"))@valid)
  expect_error(Schema(list(finite = NA), error = TRUE))
})

test_that("Validator finite rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(finite = TRUE)))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$finite, "No data for field.")
})

test_that("Validator finite rule: basic usage", {
  v <- Validator(
    list(a = c(NA, 1), b = -Inf, x = c(1, Inf), y = c(NaN, 1), z = c(1, 2)),
    Schema(list(
      a = list(finite = TRUE),
      b = list(finite = TRUE),
      x = list(finite = TRUE),
      y = list(finite = TRUE),
      z = list(finite = TRUE)
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      a = list(finite = "Value(s) must be finite."),
      b = list(finite = "Value(s) must be finite."),
      x = list(finite = "Value(s) must be finite."),
      y = list(finite = "Value(s) must be finite."),
      z = list(finite = NULL)
    )
  )
})
