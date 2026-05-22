test_that("Schema nzchar rule: TRUE passes, others fail", {
  expect_true(Schema(list(nzchar = TRUE))@valid)

  expect_false(Schema(list(nzchar = FALSE))@valid)
  expect_false(Schema(list(nzchar = NA))@valid)
  expect_false(Schema(list(nzchar = logical()))@valid)
  expect_false(Schema(list(nzchar = c(TRUE, TRUE)))@valid)
  expect_false(Schema(list(nzchar = "not_a_boolean"))@valid)
  expect_error(Schema(list(nzchar = NA), error = TRUE))
})

test_that("Validator nzchar rule: error if no field", {
  v <- Validator(
    list(name = "test"),
    Schema(list(name2 = list(nzchar = TRUE)))
  )
  expect_false(v@valid)
  expect_equal(v@errors$name2$nzchar, "No data for field.")
})

test_that("Validator nzchar rule: basic usage", {
  v <- Validator(
    list(x = c("123", ""), y = c("", "1"), z = list(x = 1, y = 2)),
    Schema(list(
      x = list(nzchar = TRUE),
      y = list(nzchar = TRUE),
      z = list(nzchar = TRUE)
    ))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      x = list(nzchar = "Contains empty string(s)."),
      y = list(nzchar = "Contains empty string(s)."),
      z = list(nzchar = NULL)
    )
  )
})
