test_that("Schema apply rule: string or function passes, others fail", {
  expect_true(Schema(list(apply = function(x) x))@valid)
  expect_true(Schema(list(apply = r"{\(x) x}"))@valid)
  expect_true(Schema(list(apply = "\\(x) x"))@valid)
  expect_true(Schema(list(apply = "character"))@valid)

  expect_false(Schema(list(apply = ""))@valid)
  expect_false(Schema(list(apply = c(r"{\(x) x}", r"{\(x) x}")))@valid)
  expect_false(Schema(list(apply = NA_character_))@valid)
  expect_false(Schema(list(apply = c("character", "numeric")))@valid)
  expect_false(Schema(list(apply = 123))@valid)
  expect_error(Schema(list(apply = 123), error = TRUE))
})

test_that("Validator apply rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(apply = "\\(x) x")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$apply, "No data for field.")
})

test_that("Validator apply rule: applies if value present", {
  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2), list(1)),
    Schema(list(
      x = list(apply = "\\(x) as.numeric(x)"),
      y = list(apply = "\\(x) as.character(x)"),
      z = list(apply = "\\(x) as.data.frame(x)"),
      list(list(apply = "\\(x) x + 9"))
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
