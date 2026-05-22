test_that(
  "Schema min/max _nrow rule:
  single positive integerish value passes, other fails",
  {
    test_scalar_positive_integerish_rule("min_nrow")
    test_scalar_positive_integerish_rule("max_nrow")
  }
)

test_that("Validator min/max _nrow rule rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(
      name2 = list(min_nrow = 1),
      name3 = list(max_nrow = 5)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$min_nrow, "No data for field.")
  expect_equal(v@errors$name3$max_nrow, "No data for field.")
})

test_that("Validator min/max _nrow rule: basic usage", {
  v <- Validator(
    list(x = data.frame(x = 5:7), y = data.frame(x = 10:15)),
    Schema(list(
      x = list(min_nrow = 1, max_nrow = 10),
      y = list(min_nrow = 5, max_nrow = 15)
    ))
  )
  expect_true(v@valid)

  v <- Validator(
    list(x = data.frame(x = 1:3), y = data.frame(x = 1:15)),
    Schema(list(
      x = list(min_nrow = 6, max_nrow = 10),
      y = list(min_nrow = 5, max_nrow = 9)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$min_nrow, "Number of rows must be at least 6.")
  expect_equal(v@errors$y$max_nrow, "Number of rows must be at most 9.")

  v <- Validator(
    list(x = data.frame(x = 1:15), y = data.frame(x = 1:3)),
    Schema(list(
      x = list(min_nrow = 3, max_nrow = 10),
      y = list(min_nrow = 5, max_nrow = 9)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$max_nrow, "Number of rows must be at most 10.")
  expect_equal(v@errors$y$min_nrow, "Number of rows must be at least 5.")
})

test_that("Validator min/max _nrow rule: errors if NULL nrow return", {
  v <- Validator(
    list(x = 1:5, y = "not a data frame"),
    Schema(list(
      x = list(min_nrow = 1, max_nrow = 10),
      y = list(min_nrow = 1, max_nrow = 10)
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$x$min_nrow, "Type not applicable for `nrow()`.")
  expect_equal(v@errors$y$min_nrow, "Type not applicable for `nrow()`.")
})
