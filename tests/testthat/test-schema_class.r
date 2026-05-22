test_that("Schema attaches class and accepts correct args", {
  s <- Schema(list(
    name = list(type = "character", required = TRUE),
    age = list(type = "numeric", min_val = 0)
  ))

  expect_s7_class(s, Schema)

  expect_error(Schema(c("type" = "character")))
  expect_error(Schema(data.frame(type = "character")))
  expect_error(Schema(list()))
  expect_error(Schema(data.frame()))
  expect_error(Schema(data.frame(x = character())))

  expect_no_error(Schema(list(type = "character"), Registry()))
  expect_error(Schema(list(type = "character"), "not a registry"))

  for (el in list(1L, NA, NULL, c(TRUE, TRUE))) {
    expect_error(Schema(list(type = "character"), error = el))
  }

  expect_no_error(Schema(list(type = "character"), max_depth = 2))
  expect_warning(Schema(list(type = "character"), not_a_print_opt = 1L))
})

test_that("Schema editable props", {
  s <- Schema(list(type = "integer"))

  expect_error(s@schema <- c("type" = "character"))
  expect_no_error(s@schema <- list(type = "numeric"))
  expect_equal(s@schema, list(type = "numeric"))
  expect_error(s@schema <- data.frame(type = "double"))

  expect_no_error(s@schema$type <- "character")
  expect_equal(s@schema$type, "character")

  expect_no_error(s@Registry <- Registry())
  expect_error(s@Registry <- "not a registry")

  expect_no_error(s@error <- TRUE)
  for (el in list(1L, NA, NULL, c(TRUE, TRUE))) {
    expect_error(s@error <- el)
  }

  expect_no_error(s@error_print_opts <- list(max_depth = 5))
  expect_no_error(s@error_print_opts <- list())
  expect_error(s@error_print_opts <- "not a list")
  expect_warning(s@error_print_opts <- list(not_correct_arg = 1L))
})

test_that("Schema uneditable props", {
  s <- Schema(list(type = "integer"))

  expect_error(s@errors <- list(x = 1))
  expect_error(s@errors$type <- "character")
  expect_error(s@.schema_cache <- new.env(parent = emptyenv()))
  expect_error(s@valid <- TRUE)
})
