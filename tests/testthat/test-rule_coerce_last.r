test_that(
  "Schema coerce_last rule: valid string or function passes, others fail",
  {
    expect_true(Schema(list(coerce_last = function(x) x))@valid)
    expect_true(Schema(list(coerce_last = function(x, y) x))@valid)
    expect_false(Schema(list(coerce_last = function() NULL))@valid)

    # don't do str2fn conversion
    expect_false(Schema(list(coerce_last = r"{\(x) x}"))@valid)
    expect_false(Schema(list(coerce_last = "\\(x) x"))@valid)
    expect_false(Schema(list(coerce_last = "notpresent"))@valid)
    expect_true(Schema(list(coerce_last = "character"))@valid)

    expect_false(Schema(list(coerce_last = ""))@valid)
    expect_false(Schema(list(coerce_last = NA_character_))@valid)
    expect_false(Schema(list(coerce_last = c("character", "numeric")))@valid)
    expect_false(Schema(list(coerce_last = 123))@valid)
    expect_error(Schema(list(coerce_last = 123), error = TRUE))
  }
)

test_that("Validator coerce_last rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(coerce_last = "numeric")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$coerce_last, "No data for field.")
})

test_that("Validator coerce_last rule: coerces if value present", {
  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2)),
    Schema(list(
      x = list(coerce_last = "numeric"),
      y = list(coerce_last = "character"),
      z = list(coerce_last = "data.frame")
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
      x = list(coerce_last = function(x) as.numeric(x)),
      y = list(coerce_last = function(x) as.character(x)),
      z = list(coerce_last = function(x) as.data.frame(x))
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
