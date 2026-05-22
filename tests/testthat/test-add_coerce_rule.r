test_that(
  "add_coerce_rule attaches rule to Registry or objs containing",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fn <- function(field) {}

    expect_no_error(
      r <- add_coerce_rule(r, "new_coerce_rule", fn)
    )
    expect_equal(r@coerce_map$new_coerce_rule, fn)

    expect_no_error(
      s <- add_coerce_rule(s, "new_coerce_rule", fn)
    )
    expect_equal(
      s@Registry@coerce_map$new_coerce_rule,
      fn
    )

    expect_no_error(
      v <- add_coerce_rule(v, "new_coerce_rule", fn)
    )
    expect_equal(
      v@Schema@Registry@coerce_map$new_coerce_rule,
      fn
    )
  }
)

test_that("add_coerce_rule errors on invalid coerce rule name", {
  r <- Registry()
  s <- Schema(list(type = "integer"))
  v <- Validator(1L, s)
  fn <- function(x, ...) {}
  for (el in list(1L, NA_character_, NULL, "", c("a", "b"))) {
    expect_error(add_coerce_rule(r, el, fn))
    expect_error(add_coerce_rule(s, el, fn))
    expect_error(add_coerce_rule(v, el, fn))
  }
})

test_that("add_coerce_rule errors on non-function rules", {
  r <- Registry()
  s <- Schema(list(type = "integer"))
  v <- Validator(1L, s)
  for (el in list(1L, NA_character_, NULL, "", c("a", "b"))) {
    expect_error(
      add_coerce_rule(r, "not_a_function", el)
    )
    expect_error(
      add_coerce_rule(s, "not_a_function", el)
    )
    expect_error(
      add_coerce_rule(v, "not_a_function", el)
    )
  }
})

test_that(
  "add_coerce_rule method errors on invalid coerce rule function args",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fns <- list(
      too_few = function() {},
      too_many = function(x, y) {}
    )
    vfn <- function(x, y, ...) {}
    for (fn in fns) {
      expect_error(
        add_coerce_rule(r, "fn_invalid_args", fn)
      )
      expect_error(
        add_coerce_rule(s, "fn_invalid_args", fn)
      )
      expect_error(
        add_coerce_rule(v, "fn_invalid_args", fn)
      )
    }
  }
)
