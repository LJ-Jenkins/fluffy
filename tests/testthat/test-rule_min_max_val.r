test_that(
  "Schema min/max _val rule: single numeric value passes, other fails",
  {
    test_scalar_numeric_rule("min_val")
    test_scalar_numeric_rule("max_val")
  }
)

test_that("Validator min/max _val rule rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(
      name2 = list(min_val = 1),
      name3 = list(max_val = 5)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$min_val, "No data for field.")
  expect_equal(v@errors$name3$max_val, "No data for field.")
})

test_that("Validator min/max _val rule: basic usage", {
  v <- Validator(
    list(x = 5, y = 10),
    Schema(list(
      x = list(min_val = 0, max_val = 10),
      y = list(min_val = 5, max_val = 15)
    ))
  )
  expect_true(v@valid)

  v <- Validator(
    list(x = 5, y = 10),
    Schema(list(
      x = list(min_val = 6, max_val = 10),
      y = list(min_val = 5, max_val = 9)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$min_val, "Value(s) must be at least 6.")
  expect_equal(v@errors$y$max_val, "Value(s) must be at most 9.")

  v <- Validator(
    list(x = 3:11, y = 4:9),
    Schema(list(
      x = list(min_val = 3, max_val = 10),
      y = list(min_val = 5, max_val = 9)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$max_val, "Value(s) must be at most 10.")
  expect_equal(v@errors$y$min_val, "Value(s) must be at least 5.")
})
