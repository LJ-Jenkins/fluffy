test_that("Schema inherits rule: chr vector passes, others fail", {
  expect_true(Schema(list(inherits = "type1"))@valid)
  expect_true(Schema(list(inherits = c("type2", "type3")))@valid)

  expect_false(Schema(list(inherits = ""))@valid)
  expect_false(Schema(list(inherits = NA_character_))@valid)
  expect_false(Schema(list(inherits = c("type1", NA_character_)))@valid)
  expect_false(Schema(list(inherits = c("type2", "")))@valid)
  expect_false(Schema(list(inherits = 123))@valid)
  expect_error(Schema(list(inherits = 123), error = TRUE))
})

test_that("Validator inherits rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(inherits = "numeric")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$inherits, "No data for field.")
})

test_that("Validator inherits rule: basic usage", {
  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2)),
    Schema(list(
      x = list(inherits = "character"),
      y = list(inherits = "numeric"),
      z = list(inherits = "list")
    ))
  )
  expect_true(v@valid)

  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2)),
    Schema(list(
      x = list(inherits = "numeric"),
      y = list(inherits = "character"),
      z = list(inherits = "data.frame")
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors, list(
    x = list(inherits = "Does not inherit from class `numeric`."),
    y = list(inherits = "Does not inherit from class `character`."),
    z = list(inherits = "Does not inherit from class `data.frame`.")
  ))

  x <- structure("123", class = c("my_class1", "my_class2", "character"))
  v <- Validator(
    x, Schema(list(inherits = c("my_class1", "my_class2")))
  )
  expect_true(v@valid)

  v <- Validator(
    x, Schema(list(inherits = c("my_class3", "my_class4")))
  )
  expect_false(v@valid)
  expect_equal(v@errors, list(
    inherits = "Does not inherit from classes `my_class3`, `my_class4`."
  ))
})
