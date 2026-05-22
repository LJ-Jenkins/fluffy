test_that("Schema regex rule: string passes, others fail", {
  expect_true(Schema(list(regex = "any_string"))@valid)

  expect_false(Schema(list(regex = ""))@valid)
  expect_false(Schema(list(regex = NA_character_))@valid)
  expect_false(Schema(list(regex = c("vec", "hi")))@valid)
  expect_false(Schema(list(regex = 123))@valid)
  expect_error(Schema(list(regex = 123), error = TRUE))
})

test_that("Validator regex rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(regex = "any_string")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$regex, "No data for field.")
})

test_that("Validator regex rule: basic usage", {
  v <- Validator(
    list(x = c("123", "213"), y = c("123", "132"), z = list(x = 1, y = 1)),
    Schema(list(
      x = list(regex = "^1"),
      y = list(regex = "^1"),
      z = list(regex = "^1")
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      x = list(regex = "String(s) do not match regex pattern `^1`."),
      y = list(regex = NULL),
      z = list(regex = NULL)
    )
  )
})
