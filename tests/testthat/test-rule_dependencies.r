test_that(
  "Schema dependencies rule:
    character vector, integerish vector,
    or list of both passes, other fails",
  {
    expect_true(Schema(list(dependencies = list("field2")))@valid)
    expect_true(Schema(list(dependencies = list("field2", "field3")))@valid)
    expect_true(Schema(list(dependencies = list(1)))@valid)
    expect_true(Schema(list(dependencies = list(1, 2)))@valid)
    expect_true(Schema(list(dependencies = list(list("field2"))))@valid)
    expect_true(Schema(
      list(dependencies = list(list("field2"), list(1)))
    )@valid)
    expect_true(Schema(list(dependencies = list(1)))@valid)

    expect_false(Schema(list(dependencies = list("")))@valid)
    expect_false(Schema(list(dependencies = list(NA_character_)))@valid)
    expect_false(
      Schema(list(dependencies = list("field1", NA_character_)))@valid
    )
    expect_false(Schema(list(dependencies = list("field2", "")))@valid)
    for (val in c(0, 1.5, -1, NA, NaN, Inf, -Inf)) {
      expect_false(Schema(list(dependencies = list(val)))@valid)
    }
    expect_false(Schema(list(dependencies = list(NA_integer_)))@valid)
    expect_false(Schema(list(dependencies = list(1, "")))@valid)
    expect_false(Schema(list(dependencies = 1))@valid)
    expect_false(Schema(list(dependencies = "field1"))@valid)
  }
)

test_that("Validator dependencies rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(dependencies = list("field1"))))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors$name2$dependencies,
    "No data for field."
  )
})

test_that("Validator dependencies rule: error if not list-like data", {
  v <- Validator(
    1:10,
    Schema(list(dependencies = list(1L)))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors$dependencies,
    "rule only operates on list-like data inputs."
  )
})

test_that("Validator dependencies rule: basic usage", {
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
    Schema(list(a = list(dependencies = list("b", "h", 4))))
  )
  expect_true(v@valid)

  v <- Validator(
    x,
    Schema(list(a = list(dependencies = list(list("b", 4), 4))))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors$a$dependencies,
    "Missing `data[['b']][[4]]`."
  )

  v <- Validator(
    x,
    Schema(list(a = list(dependencies = list(2:3))))
  )
  expect_true(v@valid)

  v <- Validator(
    x,
    Schema(list(a = list(dependencies = list("k", 2:4))))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors$a$dependencies,
    "Missing `data[[2]][[3]][[4]]`."
  )
})

test_that("Validator dependencies rule: can pick up transformed data", {
  v <- Validator(
    list(b = 1),
    list(a = list(default = 1), b = list(dependency = "a"))
  )
  expect_true(v@valid)
})
