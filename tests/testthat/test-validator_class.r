test_that(
  "Validator attaches class and accepts non-empty atomics/lists/data.frames",
  {
    sv <- Schema(list(type = "integer"))
    sl <- Schema(list(list(type = "integer")))

    v <- Validator(1L, sv)
    expect_s7_class(v, Validator)

    for (el in list(1L, list(1L), data.frame(x = 1L))) {
      expect_no_error(Validator(el, sl))
    }

    for (el in list(
      character(), integer(), double(), list(), data.frame(), raw()
    )) {
      expect_error(Validator(el, sv))
    }

    expect_error(Validator(1L, c("type" = "integer")))

    for (el in list(1L, NA, NULL, c(TRUE, TRUE))) {
      expect_error(Validator(1L, sv, error = el))
    }
  }
)

test_that("Validator editable props", {
  v <- Validator(1L, list(type = "integer"))

  expect_error(v@data <- list())
  expect_no_error(v@data <- data.frame(x = 1L))
  expect_equal(v@data, data.frame(x = 1L))

  expect_error(v@Schema <- c("type" = "character"))
  expect_no_error(v@Schema <- list(type = "numeric"))
  expect_equal(v@Schema, Schema(list(type = "numeric")))
  expect_error(v@Schema <- data.frame(type = "double"))

  expect_no_error(v@error <- FALSE)
  for (el in list(1L, NA, NULL, c(TRUE, TRUE))) {
    expect_error(v@error <- el)
  }
})

test_that("Validator uneditable props", {
  v <- Validator(1L, list(type = "integer"))

  expect_error(v@errors <- list(x = 1))
  expect_error(v@errors$type <- "character")
  expect_error(v@.validator_cache <- new.env(parent = emptyenv()))
  expect_error(v@valid <- TRUE)
})

test_that("Validator errors if data has names that match rule names", {
  expect_error(
    Validator(list(required = 1), list(type = "list"))
  )

  expect_error(
    Validator(data.frame(x = 1, apply = 2), list(type = "data.frame"))
  )

  expect_error(
    Validator(c("regex" = 1L), list(type = "integer"))
  )
})
