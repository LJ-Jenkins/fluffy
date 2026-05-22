test_that(
  "Schema min/max _nchar rule:
  single positive integerish value passes, other fails",
  {
    test_scalar_positive_integerish_rule("min_nchar")
    test_scalar_positive_integerish_rule("max_nchar")
  }
)

test_that("Validator min/max _nchar rule rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(
      name2 = list(min_nchar = 1),
      name3 = list(max_nchar = 5)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$min_nchar, "No data for field.")
  expect_equal(v@errors$name3$max_nchar, "No data for field.")
})

test_that("Validator min/max _nchar rule: basic usage", {
  v <- Validator(
    list(x = "123456789", y = "12345"),
    Schema(list(
      x = list(min_nchar = 1, max_nchar = 10),
      y = list(min_nchar = 5, max_nchar = 15)
    ))
  )
  expect_true(v@valid)

  v <- Validator(
    list(x = c("123456", "12345"), y = c("12345", "1234567891")),
    Schema(list(
      x = list(min_nchar = 6, max_nchar = 10),
      y = list(min_nchar = 5, max_nchar = 9)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$min_nchar, "Char length(s) must be at least 6.")
  expect_equal(v@errors$y$max_nchar, "Char length(s) must be at most 9.")

  v <- Validator(
    list(x = c("123", "12345678901"), y = c("12345", "123")),
    Schema(list(
      x = list(min_nchar = 3, max_nchar = 10),
      y = list(min_nchar = 5, max_nchar = 9)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$max_nchar, "Char length(s) must be at most 10.")
  expect_equal(v@errors$y$min_nchar, "Char length(s) must be at least 5.")
})
