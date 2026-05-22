test_that("Schema unique rule: TRUE passes, others fail", {
  expect_true(Schema(list(unique = TRUE))@valid)

  expect_false(Schema(list(unique = FALSE))@valid)
  expect_false(Schema(list(unique = NA))@valid)
  expect_false(Schema(list(unique = logical()))@valid)
  expect_false(Schema(list(unique = c(TRUE, TRUE)))@valid)
  expect_false(Schema(list(unique = "not_a_boolean"))@valid)
  expect_error(Schema(list(unique = NA), error = TRUE))
})

test_that("Validator unique rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(unique = TRUE)))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$unique, "No data for field.")
})

test_that("Validator unique rule: basic usage", {
  v <- Validator(
    list(x = c("a", "b"), y = 1:3, z = list(x = 1, y = 1), a = rep(1, 5)),
    Schema(list(
      x = list(unique = TRUE),
      y = list(unique = TRUE),
      z = list(unique = TRUE),
      a = list(unique = TRUE)
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      x = list(unique = NULL),
      y = list(unique = NULL),
      z = list(unique = "Contains duplicates."),
      a = list(unique = "Contains duplicates.")
    )
  )
})
