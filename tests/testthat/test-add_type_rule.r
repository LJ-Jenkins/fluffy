test_that(
  "add_type_rule attaches rule to Registry or objs containing",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fn <- function(field) {}

    expect_no_error(
      r <- add_type_rule(r, "new_type_rule", fn)
    )
    expect_equal(r@type_map$new_type_rule, fn)

    expect_no_error(
      s <- add_type_rule(s, "new_type_rule", fn)
    )
    expect_equal(
      s@Registry@type_map$new_type_rule,
      fn
    )

    expect_no_error(
      v <- add_type_rule(v, "new_type_rule", fn)
    )
    expect_equal(
      v@Schema@Registry@type_map$new_type_rule,
      fn
    )
  }
)

test_that("add_type_rule errors on invalid type rule name", {
  r <- Registry()
  s <- Schema(list(type = "integer"))
  v <- Validator(1L, s)
  fn <- function(x, ...) {}
  for (el in list(1L, NA_character_, NULL, "", c("a", "b"))) {
    expect_error(add_type_rule(r, el, fn))
    expect_error(add_type_rule(s, el, fn))
    expect_error(add_type_rule(v, el, fn))
  }
})

test_that("add_type_rule errors on non-function rules", {
  r <- Registry()
  s <- Schema(list(type = "integer"))
  v <- Validator(1L, s)
  for (el in list(1L, NA_character_, NULL, "", c("a", "b"))) {
    expect_error(
      add_type_rule(r, "not_a_function", el)
    )
    expect_error(
      add_type_rule(s, "not_a_function", el)
    )
    expect_error(
      add_type_rule(v, "not_a_function", el)
    )
  }
})

test_that(
  "add_type_rule method errors on invalid type rule function args",
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
        add_type_rule(r, "fn_invalid_args", fn)
      )
      expect_error(
        add_type_rule(s, "fn_invalid_args", fn)
      )
      expect_error(
        add_type_rule(v, "fn_invalid_args", fn)
      )
    }
  }
)
