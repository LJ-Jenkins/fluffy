test_that("Cannot have both length and min/max_length rules", {
  v <- Validator(
    list(a = 1, b = 2, x = 3, y = 4),
    Schema(list(a = list(length = 1, min_length = 2)))
  )
  expect_false(v@valid)
  expect_equal(
    v@Schema@errors$a$length,
    "Cannot have both `length` and `min_length` rules."
  )
  expect_equal(
    v@Schema@errors$a$min_length,
    "Cannot have both `length` and `min_length` rules."
  )

  v <- Validator(
    list(a = 1, b = 2, x = 3, y = 4),
    Schema(list(
      a = list(length = 1),
      b = list(min_length = 1)
    ))
  )
  expect_true(v@valid)

  v <- Validator(
    list(a = 1, b = 2, x = 3, y = 4),
    Schema(list(a = list(length = 1, max_length = 2)))
  )
  expect_false(v@valid)
  expect_equal(
    v@Schema@errors$a$length,
    "Cannot have both `length` and `max_length` rules."
  )
  expect_equal(
    v@Schema@errors$a$max_length,
    "Cannot have both `length` and `max_length` rules."
  )
})
