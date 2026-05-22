test_that("Schema positive rule: TRUE passes, others fail", {
  expect_true(Schema(list(positive = TRUE))@valid)

  expect_false(Schema(list(positive = FALSE))@valid)
  expect_false(Schema(list(positive = NA))@valid)
  expect_false(Schema(list(positive = logical()))@valid)
  expect_false(Schema(list(positive = c(TRUE, TRUE)))@valid)
  expect_false(Schema(list(positive = "not_a_boolean"))@valid)
  expect_error(Schema(list(positive = NA), error = TRUE))
})

test_that("Validator positive rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(positive = TRUE)))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$positive, "No data for field.")
})

test_that("Validator positive rule: basic usage", {
  v <- Validator(
    list(x = c(1, -1), y = c(0, 1), z = list(x = 1, y = 2)),
    Schema(list(
      x = list(positive = TRUE),
      y = list(positive = TRUE),
      z = list(positive = TRUE)
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      x = list(positive = "Value(s) must be positive (or zero)."),
      y = list(positive = NULL),
      z = list(positive = NULL)
    )
  )
})
