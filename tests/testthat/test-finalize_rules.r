test_that("finalize rules: does not occur if error present in node", {
  v <- Validator(
    list(a = 1L),
    Schema(list(
      a = list(
        apply_last = "function(x) x + 9",
        type = "double",
        coerce_last = "double"
      )
    ))
  )

  expect_false(v@valid)
  expect_equal(class(v@data$a), "integer")
  expect_equal(
    v@errors,
    list(
      a = list(
        type = "Is not type `double`.",
        coerce_last = NULL,
        apply_last = NULL
      )
    )
  )
})

test_that("finalize rules: does occur if no error present in node", {
  v <- Validator(
    list(a = 1L),
    Schema(list(
      a = list(
        apply_last = "function(x) x + 9",
        type = "integer",
        coerce_last = "double"
      )
    ))
  )

  expect_true(v@valid)
  expect_equal(class(v@data$a), "numeric")
})
