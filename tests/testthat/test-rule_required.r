test_that("Schema required rule: boolean passes, other fails", {
  expect_true(Schema(list(required = TRUE))@valid)
  expect_true(Schema(list(required = FALSE))@valid)

  expect_false(Schema(list(required = NA))@valid)
  expect_false(Schema(list(required = c(TRUE, FALSE)))@valid)
  expect_false(Schema(list(required = "not_a_boolean"))@valid)
  expect_false(Schema(list(required = integer()))@valid)
  expect_false(Schema(list(required = numeric()))@valid)
  expect_error(Schema(list(required = NA), error = TRUE))
})

test_that(
  "Validator required rule: no error if value present or required FALSE",
  {
    expect_true(
      Validator(
        list(name = "test"),
        Schema(list(name = list(required = TRUE)))
      )@valid
    )

    expect_true(
      Validator(
        list(name = "test"),
        Schema(list(name = list(required = FALSE)))
      )@valid
    )

    expect_true(
      Validator(
        list(not_name = "test"),
        Schema(list(name = list(required = FALSE)))
      )@valid
    )
  }
)

test_that(
  "Validator required rule: error if value missing and required TRUE",
  {
    expect_false(
      Validator(
        list(not_name = "test"),
        Schema(list(name = list(required = TRUE)))
      )@valid
    )
  }
)

test_that(
  "Validator required rule: if value missing, other rules ignored",
  {
    v <- Validator(
      list(not_name = "test"),
      Schema(list(
        name = list(
          max_val = 40,
          min_val = 10,
          min_length = 5,
          required = FALSE
        )
      ))
    )
    expect_true(v@valid)
    expect_equal(
      v@errors,
      list(
        name = list(
          required = NULL,
          min_val = NULL,
          max_val = NULL,
          min_length = NULL
        )
      )
    )

    v <- Validator(
      list(not_name = "test"),
      Schema(list(name = list(
        max_val = 40,
        min_val = 10,
        min_length = 5,
        required = TRUE
      )))
    )

    expect_false(v@valid)
    expect_equal(
      v@errors,
      list(
        name = list(
          required = "Field not present.",
          min_val = NULL,
          max_val = NULL,
          min_length = NULL
        )
      )
    )
  }
)

test_that(
  "Validator required rule: doesn't intefere with other rules",
  {
    v <- Validator(
      list(name = "test"),
      Schema(list(name = list(
        min_nchar = 5,
        required = TRUE
      )))
    )
    expect_false(v@valid)
    expect_equal(
      v@errors,
      list(
        name = list(
          required = NULL,
          min_nchar = "Char length(s) must be at least 5."
        )
      )
    )

    v <- Validator(
      list(name = "test"),
      Schema(list(name = list(
        min_nchar = 5,
        required = FALSE
      )))
    )
    expect_false(v@valid)
    expect_equal(
      v@errors,
      list(
        name = list(
          required = NULL,
          min_nchar = "Char length(s) must be at least 5."
        )
      )
    )
  }
)
