test_that("Schema error messages reflect schema structure after reordering", {
  expect_snapshot(error = TRUE, {
    Schema(
      list(
        type = "nope",
        min_length = "nope",
        a = list(type = "nope"),
        b = list(min_length = "nope", max_val = "nope"),
        x = list(type = "nope", positive = "nope"),
        list(type = "nope"),
        a = list(type = "nope"),
        min_length = "nope",
        list(type = "nope")
      ),
      error = TRUE
    )
  })
})

test_that("Validator accurately presents Schema errors", {
  expect_snapshot(error = TRUE, {
    Validator(
      1,
      list(
        type = "nope",
        min_length = "nope",
        a = list(type = "nope"),
        b = list(min_length = "nope", max_val = "nope"),
        x = list(type = "nope", positive = "nope"),
        list(type = "nope"),
        a = list(type = "nope"),
        min_length = "nope",
        list(type = "nope")
      ),
      error = TRUE
    )
  })
})

test_that(
  "Validator data errors reflect perceived data structure, not schema structure",
  {
    expect_snapshot(error = TRUE, {
      Validator(
        data = list(1, a = "a", b = 10, x = -1),
        schema = list(
          type = "data.frame",
          min_length = 5,
          list(type = "character"),
          a = list(min_nchar = 2),
          b = list(min_length = 2, max_val = 5),
          list(positive = TRUE)
        ),
        error = TRUE
      )
    })
  }
)

test_that("Unmatched data elements reflect perceived data structure", {
  expect_snapshot(error = TRUE, {
    Validator(
      data = list(1, a = "a", b = 10),
      schema = list(
        type = "data.frame",
        min_length = 5,
        list(type = "character"),
        a = list(min_nchar = 2),
        b = list(min_length = 2, max_val = 5),
        list(positive = TRUE),
        x = list(positive = TRUE),
        list(positive = TRUE)
      ),
      error = TRUE
    )
  })
})

test_that(
  "add_rule invalid args error messages are informative",
  {
    r <- Registry()
    fn <- function(x, y) {}
    vfn <- function(x, y, ...) {}

    expect_snapshot(error = TRUE, {
      add_rule(r, "validator_fn_invalid_args", fn)
    })

    expect_snapshot(error = TRUE, {
      add_rule(r, "validator_fn_used_.schema", function(x, .schema, ...) {})
    })

    expect_snapshot(error = TRUE, {
      add_rule(r, "schema_fn_invalid_args", vfn, fn)
    })

    expect_snapshot(error = TRUE, {
      add_rule(r, "schema_fn_used_.data", vfn, function(x, y, .data, ...) {})
    })

    expect_snapshot(error = TRUE, {
      add_cross_rule(r, "cross_fn_invalid_args", c("type", "inherits"), fn)
    })

    expect_snapshot(error = TRUE, {
      add_type_rule(r, "fn_invalid_args", function(x, y) x)
    })

    expect_snapshot(error = TRUE, {
      add_coerce_rule(r, "fn_invalid_args", function(x, y) x)
    })
  }
)
