test_that(
  "Schema length rule:
  single positive integerish value passes, other fails",
  {
    test_scalar_positive_integerish_rule("length")
  }
)

test_that("Validator length rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(
      name2 = list(length = 1),
      name3 = list(length = 5)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$length, "No data for field.")
  expect_equal(v@errors$name3$length, "No data for field.")
})

test_that("Validator length rule: basic usage", {
  v <- Validator(
    list(x = 5:7, y = 10:15),
    Schema(list(
      x = list(length = 3),
      y = list(length = 6)
    ))
  )
  expect_true(v@valid)

  v <- Validator(
    list(x = 1:3, y = 1:15),
    Schema(list(
      x = list(length = 6),
      y = list(length = 9)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$length, "Length must be 6.")
  expect_equal(v@errors$y$length, "Length must be 9.")

  v <- Validator(
    list(x = 1:15, y = 1:3),
    Schema(list(
      x = list(length = 10),
      y = list(length = 5)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$length, "Length must be 10.")
  expect_equal(v@errors$y$length, "Length must be 5.")
})
