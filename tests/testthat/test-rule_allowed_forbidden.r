test_that(
  "Schema allowed/forbidden rule:
    (recursive) non-empty atomic vector or list passes, other fails",
  {
    test_non_empty_atomic_rule("allowed")
    test_non_empty_atomic_rule("forbidden")
  }
)

test_that("Validator allowed/forbidden rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(
      name2 = list(allowed = "numeric"),
      name3 = list(forbidden = "numeric")
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$allowed, "No data for field.")
  expect_equal(v@errors$name3$forbidden, "No data for field.")
})

test_that("Validator allowed/forbidden rule: basic usage", {
  v <- Validator(
    list(x = c(1, 2), y = c(1, 2), z = list(x = 1, y = 2)),
    Schema(list(
      x = list(allowed = c(1, 2)),
      y = list(forbidden = c(3, 4)),
      # using %in%, so this is fine but document properly
      z = list(allowed = c(1, 2))
    ))
  )
  expect_true(v@valid)

  v <- Validator(
    list(x = c(1, 2), y = c(1, 2), z = list(x = 1, y = 2)),
    Schema(list(
      x = list(allowed = c(1, 3)),
      y = list(forbidden = c(1, 2)),
      z = list(allowed = c(10, y = 20))
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      x = list(allowed = "Contains value(s) not in allowed set."),
      y = list(forbidden = "Contains value(s) in forbidden set."),
      z = list(allowed = "Contains value(s) not in allowed set.")
    )
  )
})
