test_that("Schema reorders according to rule order", {
  r <- Registry()
  slist <- list(
    apply_last = "..",
    apply = "..",
    default = 1,
    positive = TRUE,
    type = "character"
  )

  s <- Schema(slist, r)@schema

  expect_equal(
    s,
    list(
      default = 1,
      apply = "..",
      type = "character",
      positive = TRUE,
      apply_last = ".."
    )
  )

  r@validate_rules <- c("positive", r@validate_rules[r@validate_rules != "positive"])
  s <- Schema(slist, r)@schema

  expect_equal(
    s,
    list(
      default = 1,
      apply = "..",
      positive = TRUE,
      type = "character",
      apply_last = ".."
    )
  )
})

test_that("Rules added to end of group by default", {
  r <- Registry()
  r <- add_rule(
    r,
    "new_validate",
    function(x, y, ...) TRUE,
    rule_type = "validate"
  )

  slist <- list(
    type = "character",
    new_validate = 1L
  )

  s <- Schema(slist, r)@schema
  expect_equal(
    s,
    list(
      type = "character",
      new_validate = 1L
    )
  )

  r@validate_rules <- c("new_validate", r@validate_rules[r@validate_rules != "new_validate"])
  s <- Schema(slist, r)@schema

  expect_equal(
    s,
    list(
      new_validate = 1L,
      type = "character"
    )
  )
})
