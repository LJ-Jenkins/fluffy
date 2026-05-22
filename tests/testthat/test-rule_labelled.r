test_that("Schema labelled rule: boolean passes, others fail", {
  expect_true(Schema(list(labelled = TRUE))@valid)
  expect_true(Schema(list(labelled = FALSE))@valid)

  expect_false(Schema(list(labelled = NA))@valid)
  expect_false(Schema(list(labelled = logical()))@valid)
  expect_false(Schema(list(labelled = c(FALSE, FALSE)))@valid)
  expect_false(Schema(list(labelled = "not_a_boolean"))@valid)
  expect_error(Schema(list(labelled = NA), error = TRUE))
})

test_that("Validator labelled rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(labelled = FALSE)))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$labelled, "No data for field.")
})

test_that("Validator labelled rule: basic usage", {
  fake_labels <- function(x) {
    attr(x, "labels") <- "Non-null placeholder"
    x
  }
  data <- list(
    a = fake_labels(c(NA, 1)),
    b = fake_labels(-Inf),
    x = c(1, NA),
    y = c(NaN, 1)
  )

  v <- Validator(
    data,
    Schema(list(
      a = list(labelled = TRUE),
      b = list(labelled = FALSE),
      x = list(labelled = TRUE),
      y = list(labelled = FALSE)
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      a = list(labelled = NULL),
      b = list(labelled = "Labels present."),
      x = list(labelled = "No labels present."),
      y = list(labelled = NULL)
    )
  )
})
