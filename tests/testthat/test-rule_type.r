test_that("Schema type rule: valid string passes, others fail", {
  expect_true(Schema(list(type = function(x) x))@valid)
  expect_false(Schema(list(type = function(x, y) x))@valid)
  expect_false(Schema(list(type = function() NULL))@valid)

  # don't do str2fn conversion
  expect_false(Schema(list(type = r"{\(x) x}"))@valid)
  expect_false(Schema(list(type = "\\(x) x"))@valid)
  expect_false(Schema(list(type = "notpresent"))@valid)
  expect_true(Schema(list(type = "character"))@valid)

  expect_false(Schema(list(type = ""))@valid)
  expect_false(Schema(list(type = NA_character_))@valid)
  expect_false(Schema(list(type = c("character", "numeric")))@valid)
  expect_false(Schema(list(type = 123))@valid)
  expect_error(Schema(list(type = 123), error = TRUE))
})

test_that("Validator type rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(type = "numeric")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$type, "No data for field.")
})

test_that("Validator type rule: basic usage", {
  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2)),
    Schema(list(
      x = list(type = "character"),
      y = list(type = "numeric"),
      z = list(type = "list")
    ))
  )
  expect_true(v@valid)

  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2)),
    Schema(list(
      x = list(type = "numeric"),
      y = list(type = "character"),
      z = list(type = "data.frame")
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors, list(
    x = list(type = "Is not type `numeric`."),
    y = list(type = "Is not type `character`."),
    z = list(type = "Is not type `data.frame`.")
  ))

  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2)),
    Schema(list(
      x = list(type = function(x) is.numeric(x)),
      y = list(type = function(x) is.character(x)),
      z = list(type = function(x) is.data.frame(x))
    ))
  )
  expect_false(v@valid)
  expect_equal(v@errors, list(
    x = list(type = "Is not expected type."),
    y = list(type = "Is not expected type."),
    z = list(type = "Is not expected type.")
  ))
})
