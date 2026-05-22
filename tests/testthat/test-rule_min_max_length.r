test_that(
  "Schema min/max _length rule:
  single positive integerish value passes, other fails",
  {
    test_scalar_positive_integerish_rule("min_length")
    test_scalar_positive_integerish_rule("max_length")
  }
)

test_that("Validator min/max _length rule rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(
      name2 = list(min_length = 1),
      name3 = list(max_length = 5)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$min_length, "No data for field.")
  expect_equal(v@errors$name3$max_length, "No data for field.")
})

test_that("Validator min/max _length rule: basic usage", {
  v <- Validator(
    list(x = 5:7, y = 10:15),
    Schema(list(
      x = list(min_length = 1, max_length = 10),
      y = list(min_length = 5, max_length = 15)
    ))
  )
  expect_true(v@valid)

  v <- Validator(
    list(x = 1:3, y = 1:15),
    Schema(list(
      x = list(min_length = 6, max_length = 10),
      y = list(min_length = 5, max_length = 9)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$min_length, "Length must be at least 6.")
  expect_equal(v@errors$y$max_length, "Length must be at most 9.")

  v <- Validator(
    list(x = 1:15, y = 1:3),
    Schema(list(
      x = list(min_length = 3, max_length = 10),
      y = list(min_length = 5, max_length = 9)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$max_length, "Length must be at most 10.")
  expect_equal(v@errors$y$min_length, "Length must be at least 5.")
})
