test_that("Schema predicate rule: string or function passes, others fail", {
  expect_true(Schema(list(predicate = function(x) x))@valid)
  expect_true(Schema(list(predicate = function(x, y, z) x))@valid)
  expect_true(Schema(list(predicate = r"{\(x) x}"))@valid)
  expect_true(Schema(list(predicate = "\\(x) x"))@valid)
  expect_true(Schema(list(predicate = "character"))@valid)

  expect_false(Schema(list(predicate = ""))@valid)
  expect_false(Schema(list(predicate = c(r"{\(x) x}", r"{\(x) x}")))@valid)
  expect_false(Schema(list(predicate = NA_character_))@valid)
  expect_false(Schema(list(predicate = c("character", "numeric")))@valid)
  expect_false(Schema(list(predicate = 123))@valid)
  expect_error(Schema(list(predicate = 123), error = TRUE))
})

test_that("Validator predicate rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(predicate = "\\(x) x")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$predicate, "No data for field.")
})

test_that("Validator predicate rule: error if non-boolean returned", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name = list(predicate = "\\(x) x")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name$predicate, "Returned non-boolean.")
})

test_that("Validator predicate rule: basic usage", {
  v <- Validator(
    list(x = "123", y = 123, z = list(x = 1, y = 2), list(1)),
    Schema(list(
      x = list(predicate = "\\(x) is.character(x)"),
      y = list(predicate = "\\(x) is.numeric(x)"),
      z = list(predicate = "\\(x) is.list(x)"),
      list(predicate = "\\(x) is.list(x)", list(predicate = "\\(x) x == 9"))
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      x = list(predicate = NULL),
      y = list(predicate = NULL),
      z = list(predicate = NULL),
      list(predicate = NULL, list(predicate = "Does not satisfy predicate."))
    )
  )

  v <- Validator(
    list(x = "123", y = 123),
    Schema(list(
      x = list(predicate = function(x) is.character(x)),
      y = list(predicate = function(x) is.numeric(x))
    ))
  )
  expect_true(v@valid)
})
