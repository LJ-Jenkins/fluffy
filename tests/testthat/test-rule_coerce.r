test_that("Schema coerce rule: valid string or function passes, others fail", {
  expect_true(Schema(list(coerce = function(x) x))@valid)
  expect_false(Schema(list(coerce = function(x, y) x))@valid)
  expect_false(Schema(list(coerce = function() NULL))@valid)

  # don't do str2fn conversion
  expect_false(Schema(list(coerce = r"{\(x) x}"))@valid)
  expect_false(Schema(list(coerce = "\\(x) x"))@valid)
  expect_false(Schema(list(coerce = "notpresent"))@valid)
  expect_true(Schema(list(coerce = "character"))@valid)

  expect_false(Schema(list(coerce = ""))@valid)
  expect_false(Schema(list(coerce = NA_character_))@valid)
  expect_false(Schema(list(coerce = c("character", "numeric")))@valid)
  expect_false(Schema(list(coerce = 123))@valid)
  expect_error(Schema(list(coerce = 123), error = TRUE))
})

test_that("Validator coerce rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(coerce = "numeric")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$coerce, "No data for field.")
})

test_that("Validator coerce rule: coerces if value present", {
  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2)),
    Schema(list(
      x = list(coerce = "numeric"),
      y = list(coerce = "character"),
      z = list(coerce = "data.frame")
    ))
  )
  expect_true(v@valid)
  expect_equal(
    v@data,
    list(
      x = 123,
      y = "123",
      z = data.frame(x = 1, y = 2)
    )
  )

  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2)),
    Schema(list(
      x = list(coerce = function(x) as.numeric(x)),
      y = list(coerce = function(x) as.character(x)),
      z = list(coerce = function(x) as.data.frame(x))
    ))
  )
  expect_true(v@valid)
  expect_equal(
    v@data,
    list(
      x = 123,
      y = "123",
      z = data.frame(x = 1, y = 2)
    )
  )
})
