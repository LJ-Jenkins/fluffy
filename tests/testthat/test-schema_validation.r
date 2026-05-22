test_that("Schema with invalid list", {
  expect_no_error(
    s <- Schema(list(name = list(type = 123)))
  )
  expect_false(s@valid)
  expect_true(is.character(s@errors$name$type))

  expect_error(
    Schema(list(name = list(type = 123)), error = TRUE)
  )

  expect_error(Schema(list(), error = FALSE))
  expect_error(Schema(list(), error = TRUE))

  expect_no_error(
    s <- Schema(list(field = list()))
  )
  expect_false(s@valid)
  expect_false(Schema(list(type = list()))@valid)
  expect_false(Schema(list(type = list()))@valid)
})

test_that("schema works with list of depth 1", {
  s <- Schema(
    list(
      type = "character",
      max_length = 10,
      max_nchar = 10
    )
  )
  expect_true(s@valid)
})

test_that("schema allows list elements of depth 1 and depth >1", {
  s <- Schema(
    list(
      type = "character",
      list(type = "numeric")
    )
  )
  expect_true(s@valid)
})

test_that("schema with multiple invalid rules collects all errors", {
  s <- Schema(list(
    field1 = list(type = 123, required = "not_bool"),
    field2 = list(min_val = "text"),
    field3 = list(max_length = -5),
    field4 = list(allowed = list()),
    field5 = list(forbidden = NA, type = "unknown"),
    field6 = list(type = "character")
  ))
  expect_false(s@valid)
  errors <- s@errors
  x <- rapply(errors, function(x) if (is.character(x)) TRUE else FALSE)
  expect_equal(x, c(
    field1.required = TRUE,
    field1.type = TRUE,
    field2.min_val = TRUE,
    field3.max_length = TRUE,
    field4.allowed = TRUE,
    field5.type = TRUE
  ))
})

test_that("Schema validates a correct schema", {
  s <- Schema(list(
    name = list(type = "character", required = TRUE),
    value = list(type = "numeric", min_val = 0, max_val = 100)
  ))
  expect_true(s@valid)

  expect_true(Schema(list(
    level1 = list(
      level2 = list(
        level3 = list(
          level4 = list(
            type = "character"
          )
        )
      )
    )
  ))@valid)
})

test_that("Schema detects unnamed schema fields", {
  # List with unnamed elements at the field-rule level
  s <- Schema(list(field = list("character")))
  expect_false(s@valid)
  expect_error(Schema(list(field = list("character")), error = TRUE))
  s <- Schema(list(field = list(type = "character", "required")))
  expect_false(s@valid)
  expect_error(
    Schema(
      list(field = list(type = "character", "required")),
      error = TRUE
    )
  )
})

test_that("Schema detects unknown rule names", {
  s <- Schema(list(
    field = list(unknown_rule = "value")
  ))
  expect_false(s@valid)
  expect_error(
    Schema(
      list(field = list(unknown_rule = "value")),
      error = TRUE
    )
  )
})

test_that("Schema with all valid rule types validates correctly", {
  s <- Schema(list(
    field = list(
      type = "character",
      required = TRUE,
      allowed = c("a", "b", "c"),
      min_length = 1,
      max_length = 10,
      regex = "^[a-c]$"
    )
  ))
  expect_true(s@valid)
})

test_that("Schema with numeric constraints validates correctly", {
  s <- Schema(list(
    score = list(
      type = "numeric",
      required = FALSE,
      min_val = 0,
      max_val = 100,
      min_length = 1,
      max_length = 1
    )
  ))
  expect_true(s@valid)
})

test_that("Schema works with string to fn rules", {
  s <- Schema(list(
    field = list(
      predicate = "function(x) x > 0"
    )
  ))
  expect_true(s@valid)

  s <- Schema(list(
    field = list(
      predicate = "function(x) x=,"
    )
  ))
  expect_false(s@valid)

  s <- Schema(list(
    field = list(
      apply = "function(x) toupper(x)"
    )
  ))
  expect_true(s@valid)

  expect_error(
    Schema(list(
      field = list(
        apply = "function(x) x=, toupper(x)"
      )
    ), error = TRUE)
  )
})

test_that("Schema reorders input to match rule_names order", {
  s <- Schema(list(
    field = list(
      max_length = 10,
      type = "character",
      required = TRUE
    )
  ))
  expect_true(s@valid)
  expect_equal(names(s@schema$field), c("required", "type", "max_length"))

  s <- Schema(list(
    field = list(
      max_length = 10,
      field2 = list(
        type = "character",
        regex = "$ing",
        field3 = list(
          predicate = is.integer,
          default = 1L
        )
      ),
      required = TRUE
    )
  ))
  expect_equal(
    names(s@schema$field),
    c("required", "max_length", "field2")
  )
  expect_equal(
    names(s@schema$field$field2),
    c("type", "regex", "field3")
  )
  expect_equal(
    names(s@schema$field$field2$field3),
    c("default", "predicate")
  )
})

test_that("mixed named/unnamed in nested fields detected", {
  s <- Schema(list(
    outer = list(
      inner = list(type = "character", "stray_value")
    )
  ))
  expect_false(s@valid)
  expect_true(is.character(s@errors$outer$inner[[2]]))

  s <- Schema(list(
    outer = list(
      inner = list("character", "integer")
    )
  ))
  expect_false(s@valid)

  s <- Schema(list(
    a = list(
      b = list(
        c = list(type = "character", 42)
      )
    )
  ))
  expect_false(s@valid)
})

test_that("Duplicate names at a given depth not allowed", {
  s <- Schema(list(
    field = list(type = "character", type = "integer")
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(field = list(
      type = "Names must be unique at the same depth.",
      type = "Names must be unique at the same depth."
    ))
  )

  s <- Schema(list(
    field = list(type = "character", type = "not_a_type")
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(field = list(
      type = "Names must be unique at the same depth.",
      type = "Names must be unique at the same depth."
    ))
  )

  s <- Schema(list(
    field = list(type = "character", required = TRUE),
    field = list(type = "integer", required = FALSE)
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(
      field = "Names must be unique at the same depth.",
      field = "Names must be unique at the same depth."
    )
  )

  s <- Schema(list(
    field = list(type = "character", list(type = "integer")),
    node = list(type = "integer", list(type = "character"))
  ))
  expect_true(s@valid)
})

test_that("Schema str to function rules are auto converted", {
  s <- Schema(list(
    field = list(
      apply = "function(x) as.character(x)",
      predicate = "function(x) is.character(x)"
    )
  ))

  expect_equal(
    s@schema$field$apply,
    function(x) as.character(x),
    ignore_function_env = TRUE
  )
  expect_null(s@errors$field$apply)
  expect_true(s@valid)

  expect_equal(
    s@schema$field$predicate,
    function(x) is.character(x),
    ignore_function_env = TRUE
  )
  expect_null(s@errors$field$predicate)
  expect_true(s@valid)

  s <- Schema(list(apply = "x= as.character(x)"))
  expect_true(is.character(s@schema$apply))
  expect_true(is.character(s@errors$apply))
  expect_false(s@valid)
})

test_that("is_list_all_null for valid and invalid schemas", {
  expect_true(is_list_all_null(list()))
  expect_true(is_list_all_null(list(a = NULL, b = NULL)))
  expect_false(is_list_all_null(list(a = "error", b = NULL)))
  expect_false(is_list_all_null(list(a = NULL, b = "error")))
  expect_false(is_list_all_null(list(a = "error1", b = "error2")))

  expect_false(
    is_list_all_null(list(
      field1 = list(list(list(type = "character"))),
      field2 = list(list(list(required = FALSE))),
      field3 = list(max_val = 1),
      field4 = list(list(list(list(allowed = c("a", "b", "c")))))
    ))
  )
  expect_false(
    is_list_all_null(list(
      field1 = list(list(list(type = NULL))),
      field2 = list(list(list(required = NULL))),
      field3 = list(max_val = NULL),
      field4 = list(list(list(list(allowed = c("a", "b", "c")))))
    ))
  )

  expect_true(
    is_list_all_null(list(
      field1 = list(list(list(type = NULL))),
      field2 = list(list(list(required = NULL))),
      field3 = list(max_val = NULL),
      field4 = list(list(list(list(allowed = NULL))))
    ))
  )
})
