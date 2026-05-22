test_that("Cannot have both positive and negative rules", {
  v <- Validator(
    list(a = 1, b = 2, x = 3, y = 4),
    Schema(list(a = list(positive = TRUE, negative = TRUE)))
  )
  expect_false(v@valid)
  expect_equal(
    v@Schema@errors$a$positive,
    "Cannot have both `positive` and `negative` rules."
  )
  expect_equal(
    v@Schema@errors$a$negative,
    "Cannot have both `positive` and `negative` rules."
  )

  v <- Validator(
    list(a = 1, b = -2, x = 3, y = 4),
    Schema(list(
      a = list(positive = TRUE),
      b = list(negative = TRUE)
    ))
  )
  expect_true(v@valid)
})
