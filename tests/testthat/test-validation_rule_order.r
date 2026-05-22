test_that("control rules: occurs before other rules", {
  v <- Validator(
    list(a = "1"),
    Schema(list(
      b = list(
        type = "character",
        default = 1L
      ),
      z = list(
        required = FALSE,
        default = 1L
      )
    ))
  )

  expect_true(v@valid)
  expect_equal(
    v@data,
    list(
      a = "1",
      b = 1L
    )
  )
})

test_that("transform rules: occurs before validation rules", {
  v <- Validator(
    list(a = "1", b = 1L),
    Schema(list(
      b = list(
        type = "double",
        coerce = "double"
      )
    ))
  )

  expect_true(v@valid)
  expect_equal(
    v@data,
    list(
      a = "1",
      b = 1
    )
  )
})

test_that("validation rules: occurs after transform rules", {
  v <- Validator(
    list(b = 1L),
    Schema(list(
      b = list(
        type = "integer",
        coerce = "double"
      )
    ))
  )

  expect_false(v@valid)
  expect_equal(
    v@data,
    list(
      b = 1
    )
  )
})

test_that("finalize rules: occurs after every other rule", {
  v <- Validator(
    list(a = "1", b = 1),
    Schema(list(
      a = list(
        apply_last = "function(x) if (is.numeric(x)) x + 9",
        coerce = "numeric"
      ),
      b = list(
        apply_last = "function(x) if (is.numeric(x)) x + 9",
        apply = "function(x) as.numeric(x)"
      )
    ))
  )

  expect_true(v@valid)
  expect_equal(
    v@data,
    list(
      a = 10,
      b = 10
    )
  )
})
