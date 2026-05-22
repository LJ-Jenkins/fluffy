test_that("Cannot have both required TRUE and a default value", {
  v <- Validator(
    list(a = 1, b = 2, x = 3, y = 4),
    Schema(list(a = list(required = TRUE, default = 1)))
  )
  expect_false(v@valid)
  expect_equal(
    v@Schema@errors$a$required,
    "Cannot have `required` as TRUE and a `default` value."
  )
  expect_equal(
    v@Schema@errors$a$default,
    "Cannot have `required` as TRUE and a `default` value."
  )

  v <- Validator(
    list(a = 1, b = 2, x = 3, y = 4),
    Schema(list(
      a = list(required = TRUE),
      b = list(required = FALSE, default = list("x", "y"))
    ))
  )
  expect_true(v@valid)
})
