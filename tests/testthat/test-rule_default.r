test_that("Schema default rule: any non-empty value/type including list", {
  expect_true(Schema(list(default = 1))@valid)
  expect_true(Schema(list(default = NA))@valid)
  expect_true(Schema(list(default = "a string"))@valid)
  expect_true(Schema(list(default = list(a = 1, b = 2)))@valid)
  expect_true(Schema(list(default = function(x) x))@valid)
  expect_false(Schema(list(default = list()))@valid)
  expect_true(Schema(list(default = list(NULL)))@valid)
  expect_false(Schema(list(default = NULL))@valid)
})

test_that("Validator default rule: no change if value present", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name = list(default = "default_value")))
  )
  expect_true(v@valid)
  expect_equal(v@data$name, "test")
})

test_that(
  "Validator default rule: if not present (or NULL), default is given",
  {
    v <- Validator(
      list(name = "test"),
      Schema(list(name2 = list(default = "default_value")))
    )
    expect_true(v@valid)
    expect_equal(v@data$name2, "default_value")

    v <- Validator(
      list(name = "test", name2 = NULL),
      Schema(list(name2 = list(default = "default_value")))
    )
    expect_true(v@valid)
    expect_equal(v@data$name2, "default_value")

    v <- Validator(
      list(name = "test", name2 = list(NULL)),
      Schema(list(name2 = list(default = "default_value")))
    )
    expect_true(v@valid) # still valid but no update
    # technically not missing, custom rule would be needed
    expect_equal(v@data$name2, list(NULL))

    v <- Validator(
      list(name = "test", name2 = list()),
      Schema(list(name2 = list(default = "default_value")))
    )
    expect_true(v@valid)
    expect_equal(v@data$name2, list())
  }
)
