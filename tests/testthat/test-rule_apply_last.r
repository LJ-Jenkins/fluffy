test_that("Schema apply_last rule: string or function passes, others fail", {
  expect_true(Schema(list(apply_last = function(x) x))@valid)
  expect_true(Schema(list(apply_last = r"{\(x) x}"))@valid)
  expect_true(Schema(list(apply_last = "function(x) x"))@valid)
  expect_true(Schema(list(apply_last = "character"))@valid)

  expect_false(Schema(list(apply_last = ""))@valid)
  expect_false(Schema(list(apply_last = c(r"{\(x) x}", r"{\(x) x}")))@valid)
  expect_false(Schema(list(apply_last = NA_character_))@valid)
  expect_false(Schema(list(apply_last = c("character", "numeric")))@valid)
  expect_false(Schema(list(apply_last = 123))@valid)
  expect_error(Schema(list(apply_last = 123), error = TRUE))
})

test_that("Validator apply_last rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(apply_last = "function(x) x")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$apply, "No data for field.")
})

test_that("Validator apply_last rule: applies if value present", {
  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2), list(1)),
    Schema(list(
      x = list(apply_last = "function(x) as.numeric(x)"),
      y = list(apply_last = "function(x) as.character(x)"),
      z = list(apply_last = "function(x) as.data.frame(x)"),
      list(list(apply_last = "function(x) x + 9"))
    ))
  )
  expect_true(v@valid)
  expect_equal(
    v@data,
    list(
      x = 123,
      y = "123",
      z = data.frame(x = 1, y = 2),
      list(10)
    )
  )
})
