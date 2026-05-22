test_that(
  "Schema dependency rule:
    character vector, integerish vector,
    or list of both passes, other fails",
  {
    expect_true(Schema(list(dependency = "field2"))@valid)
    expect_true(Schema(list(dependency = c("field2", "field3")))@valid)
    expect_true(Schema(list(dependency = 1))@valid)
    expect_true(Schema(list(dependency = c(1, 2)))@valid)
    expect_true(Schema(list(dependency = list("field2")))@valid)
    expect_true(Schema(list(dependency = list("field2", 1)))@valid)
    expect_true(Schema(list(dependency = list(1)))@valid)

    expect_false(Schema(list(dependency = ""))@valid)
    expect_false(Schema(list(dependency = NA_character_))@valid)
    expect_false(Schema(list(dependency = c("field1", NA_character_)))@valid)
    expect_false(Schema(list(dependency = c("field2", "")))@valid)
    for (val in c(0, 1.5, -1, NA, NaN, Inf, -Inf)) {
      expect_false(Schema(list(dependency = val))@valid)
    }
    expect_false(Schema(list(dependency = NA_integer_))@valid)
    expect_false(Schema(list(dependency = list(1, "")))@valid)
  }
)

test_that("Validator dependency rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(dependency = "field1")))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors$name2$dependency,
    "No data for field."
  )
})

test_that("Validator dependency rule: error if not list-like data", {
  v <- Validator(
    1:10,
    Schema(list(dependency = 1L))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors$dependency,
    "rule only operates on list-like data inputs."
  )
})

test_that("Validator dependency rule: basic usage", {
  x <- list(
    a = 1,
    b = list(
      c = 2,
      d = list(
        e = 3,
        f = list(g = 4)
      ),
      p = list(10:13)
    ),
    h = list(i = 5, j = 6),
    k = c(7, 8, 9)
  )

  v <- Validator(
    x,
    Schema(list(a = list(dependency = "b")))
  )
  expect_true(v@valid)

  v <- Validator(
    x,
    Schema(list(a = list(dependency = c("b", "h"))))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors$a$dependency,
    "Missing `data[['b']][['h']]`."
  )

  v <- Validator(
    x,
    Schema(list(a = list(dependency = 2:3)))
  )
  expect_true(v@valid)

  v <- Validator(
    x,
    Schema(list(a = list(dependency = 2:4)))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors$a$dependency,
    "Missing `data[[2]][[3]][[4]]`."
  )
})
