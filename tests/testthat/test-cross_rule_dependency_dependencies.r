test_that("Cannot have both dependency and dependencies rules", {
  v <- Validator(
    list(a = 1, b = 2, x = 3, y = 4),
    Schema(list(a = list(dependency = "b", dependencies = list("x", "y"))))
  )
  expect_false(v@valid)
  expect_equal(
    v@Schema@errors$a$dependency,
    "Cannot have both `dependency` and `dependencies` rules."
  )
  expect_equal(
    v@Schema@errors$a$dependencies,
    "Cannot have both `dependency` and `dependencies` rules."
  )

  v <- Validator(
    list(a = 1, b = 2, x = 3, y = 4),
    Schema(list(
      a = list(dependency = "b"),
      b = list(dependencies = list("x", "y"))
    ))
  )
  expect_true(v@valid)
})
