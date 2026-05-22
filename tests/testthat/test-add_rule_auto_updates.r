# Registry doesn't need auto updating as it doesn't have a cache
test_that("add_type/coerce_rule returns obj that has been re-validated", {
  s <- Schema(list(type = "my_type"))
  expect_false(s@valid)
  expect_equal(s@errors, list(type = "`my_type` not found in allowed types."))
  s <- add_type_rule(s, "my_type", function(x) x)
  expect_true(s@valid)
  expect_null(s@errors$type)

  s <- Schema(list(coerce = "my_type"))
  expect_false(s@valid)
  expect_equal(s@errors, list(coerce = "`my_type` not found in allowed types."))
  s <- add_coerce_rule(s, "my_type", function(x) x)
  expect_true(s@valid)
  expect_null(s@errors$coerce)
})

test_that("add_cross_rule returns obj that has been re-validated", {
  s <- Schema(list(min_val = 2, max_val = 8))
  expect_true(s@valid)

  s <- add_cross_rule(
    s,
    name = "min_and_max_val_add_to_10",
    rule_names = c("min_val", "max_val"),
    cross_fn = function(schema_field, ...) {
      if (schema_field$min_val + schema_field$max_val == 10) {
        "min_val and max_val cannot add to 10."
      }
    }
  )
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(
      min_val = "min_val and max_val cannot add to 10.",
      max_val = "min_val and max_val cannot add to 10."
    )
  )
})

test_that("add_rule returns obj that has been re-validated", {
  test_rule <- function(obj) {
    add_rule(
      obj = obj,
      name = "check_my_attr",
      validator_fn = function(data_field, schema_field, ...) {
        if (attr(data_field, "my_attr") != schema_field) {
          list(error = "Data doesn't match schema 'my_attr'.")
        }
      },
      schema_fn = function(schema_field, ...) {
        if (!is.character(schema_field) || length(schema_field) != 1L) {
          "Must be length 1 character"
        }
      },
      rule_type = "validate"
    )
  }

  s <- Schema(list(check_my_attr = 1L))
  expect_equal(
    s@errors,
    list(check_my_attr = "Unknown rule: `check_my_attr`.")
  )

  s <- test_rule(s)
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(check_my_attr = "Must be length 1 character")
  )

  s@schema$check_my_attr <- "Hi"
  expect_true(s@valid)

  v <- Validator(structure(1L, my_attr = "Hi"), list(check_my_attr = "Hi"))
  expect_false(v@valid)

  v <- test_rule(v)
  expect_true(v@valid)
})
