test_that("mismatch between allowed rule type and type rule type", {
  s <- Schema(list(
    field = list(type = "numeric", allowed = c("a", "b"))
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(field = list(
      type = "Values in `allowed` must be of the type specified in `type`.",
      allowed = "Values in `allowed` must be of the type specified in `type`."
    ))
  )

  s <- Schema(list(
    field = list(type = "numeric", allowed = c(1, 2))
  ))
  expect_true(s@valid)
})

test_that("mismatch between forbidden rule type and type rule type", {
  s <- Schema(list(
    field = list(type = "numeric", forbidden = c("a", "b"))
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(field = list(
      type = "Values in `forbidden` must be of the type specified in `type`.",
      forbidden = "Values in `forbidden` must be of the type specified in `type`."
    ))
  )

  s <- Schema(list(
    field = list(type = "numeric", forbidden = c(1, 2))
  ))
  expect_true(s@valid)
})
