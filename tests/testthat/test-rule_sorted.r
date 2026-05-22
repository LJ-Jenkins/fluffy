test_that("Schema sorted rule: TRUE passes, others fail", {
  expect_true(Schema(list(sorted = TRUE))@valid)

  expect_false(Schema(list(sorted = FALSE))@valid)
  expect_false(Schema(list(sorted = NA))@valid)
  expect_false(Schema(list(sorted = logical()))@valid)
  expect_false(Schema(list(sorted = c(TRUE, TRUE)))@valid)
  expect_false(Schema(list(sorted = "not_a_boolean"))@valid)
  expect_error(Schema(list(sorted = NA), error = TRUE))
})

test_that("Validator sorted rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(sorted = TRUE)))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$sorted, "No data for field.")
})

test_that("Validator sorted rule: basic usage", {
  v <- Validator(
    list(
      a = c(NA, 1, -1), b = c(-Inf, 1, 2), x = c(1, 2, NA),
      y = c(NaN, 2, 1), z = list(x = 1, y = 2)
    ),
    Schema(list(
      a = list(sorted = TRUE),
      b = list(sorted = TRUE),
      x = list(sorted = TRUE),
      y = list(sorted = TRUE),
      z = list(sorted = TRUE)
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      a = list(sorted = "Values are not sorted."),
      b = list(sorted = NULL),
      x = list(sorted = NULL),
      y = list(sorted = "Values are not sorted."),
      z = list(sorted = "Must be an atomic type.")
    )
  )
})
