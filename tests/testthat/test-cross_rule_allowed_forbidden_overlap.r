#-- allowed_and_forbidden_overlap

test_that("allowed and forbidden with no overlap passes", {
  expect_true(Schema(
    list(allowed = c("a", "b"), forbidden = c("c", "d"))
  )@valid)
  expect_true(Schema(list(allowed = 1:3, forbidden = 4:6))@valid)
})

test_that("allowed and forbidden with overlap fails", {
  s <- Schema(list(allowed = c("a", "b"), forbidden = c("b", "c")))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(
      allowed = "Values in `allowed` and `forbidden` must not overlap.",
      forbidden = "Values in `allowed` and `forbidden` must not overlap."
    )
  )

  s <- Schema(list(allowed = 1:3, forbidden = 3:5))
  expect_false(s@valid)
  expect_equal(
    s@errors,
    list(
      allowed = "Values in `allowed` and `forbidden` must not overlap.",
      forbidden = "Values in `allowed` and `forbidden` must not overlap."
    )
  )

  expect_error(
    Schema(list(allowed = c("a", "b"), forbidden = c("b", "c")), error = TRUE)
  )
})

test_that("allowed/forbidden cross rule skipped when individual rule fails", {
  s <- Schema(list(allowed = mean, forbidden = c("a", "b")))
  expect_false(s@valid)
  expect_true(is.character(s@errors$allowed))
  expect_null(s@errors$forbidden)

  s <- Schema(list(allowed = c("a", "b"), forbidden = mean))
  expect_false(s@valid)
  expect_null(s@errors$allowed)
  expect_true(is.character(s@errors$forbidden))

  s <- Schema(list(allowed = list(), forbidden = list()))
  expect_false(s@valid)
  expect_equal(s@errors$allowed, "Empty element.")
  expect_equal(s@errors$forbidden, "Empty element.")
})

test_that("allowed/forbidden cross rule skipped when only one rule present", {
  expect_true(Schema(list(allowed = c("a", "b")))@valid)
  expect_true(Schema(list(forbidden = c("a", "b")))@valid)
})

test_that("allowed/forbidden cross rule works in nested fields", {
  s <- Schema(list(
    outer = list(
      inner = list(allowed = c("a", "b"), forbidden = c("b", "c"))
    )
  ))
  expect_false(s@valid)
  expect_equal(
    s@errors$outer$inner$allowed,
    "Values in `allowed` and `forbidden` must not overlap."
  )
  expect_equal(
    s@errors$outer$inner$forbidden,
    "Values in `allowed` and `forbidden` must not overlap."
  )
})
