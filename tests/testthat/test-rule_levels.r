test_that("Schema levels rule: chr or NULL passes, others fail", {
  expect_true(Schema(list(levels = "any_string"))@valid)
  expect_true(Schema(list(levels = ""))@valid)
  expect_true(Schema(list(levels = NA_character_))@valid)
  expect_true(Schema(list(ordered_levels = "any_string"))@valid)
  expect_true(Schema(list(ordered_levels = ""))@valid)
  expect_true(Schema(list(ordered_levels = NA_character_))@valid)

  # we will be stricter than `levels()` (for now)
  expect_false(Schema(list(levels = 1))@valid)
  expect_false(Schema(list(levels = NA_integer_))@valid)
  expect_false(Schema(list(levels = 123))@valid)
  expect_false(Schema(list(levels = character(0)))@valid)
  expect_error(Schema(list(levels = list("hi")), error = TRUE))
  expect_false(Schema(list(ordered_levels = 1))@valid)
  expect_false(Schema(list(ordered_levels = NA_integer_))@valid)
  expect_false(Schema(list(ordered_levels = 123))@valid)
  expect_false(Schema(list(ordered_levels = character(0)))@valid)
  expect_error(Schema(list(ordered_levels = list("hi")), error = TRUE))
})

test_that("Validator levels rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(levels = "any_string")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$levels, "No data for field.")

  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(ordered_levels = "any_string")))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$ordered_levels, "No data for field.")
})

test_that("Validator levels rule: basic usage", {
  f <- factor(x = c("a", "b", "c"), levels = c("a", "b", "c"))
  d <- list(a = f, b = 1:3, x = f, y = f, z = f)

  v <- Validator(
    d,
    Schema(list(
      a = list(levels = c("a", "b", "c")),
      b = list(levels = c("a", "b", "c")),
      x = list(levels = c("c", "b", "a")),
      y = list(levels = c("a", "b")),
      z = list(levels = "")
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      a = list(levels = NULL),
      b = list(levels = "Levels do not match."),
      x = list(levels = NULL),
      y = list(levels = "Levels do not match."),
      z = list(levels = "Levels do not match.")
    )
  )

  v <- Validator(
    d,
    Schema(list(
      a = list(ordered_levels = c("a", "b", "c")),
      b = list(ordered_levels = c("a", "b", "c")),
      x = list(ordered_levels = c("c", "b", "a")),
      y = list(ordered_levels = c("a", "b")),
      z = list(ordered_levels = "")
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      a = list(ordered_levels = NULL),
      b = list(ordered_levels = "Levels do not match."),
      x = list(ordered_levels = "Levels do not match."),
      y = list(ordered_levels = "Levels do not match."),
      z = list(ordered_levels = "Levels do not match.")
    )
  )
})
