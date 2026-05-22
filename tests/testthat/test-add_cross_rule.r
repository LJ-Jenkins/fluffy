test_that(
  "add_cross_rule attaches rule to Registry or objs containing",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fn <- function(field, ...) {}

    expect_no_error(
      r <- add_cross_rule(
        r,
        "new_cross_rule",
        c("type", "inherits"),
        fn
      )
    )
    expect_equal(
      r@cross_rules$new_cross_rule,
      list(rules = c("type", "inherits"), fn = fn)
    )

    expect_no_error(
      s <- add_cross_rule(
        s,
        "new_cross_rule",
        c("type", "inherits", "max_length"),
        fn
      )
    )
    expect_equal(
      s@Registry@cross_rules$new_cross_rule,
      list(rules = c("type", "inherits", "max_length"), fn = fn)
    )

    expect_no_error(
      v <- add_cross_rule(
        v,
        "new_cross_rule",
        c("type", "inherits", "max_length", "min_length"),
        fn
      )
    )
    expect_equal(
      v@Schema@Registry@cross_rules$new_cross_rule,
      list(rules = c("type", "inherits", "max_length", "min_length"), fn = fn)
    )
  }
)

test_that("add_cross_rule errors on invalid cross rule name", {
  r <- Registry()
  s <- Schema(list(type = "integer"))
  v <- Validator(1L, s)
  fn <- function(x, ...) {}
  for (el in list(1L, NA_character_, NULL, "", c("a", "b"))) {
    expect_error(add_cross_rule(r, el, c("type", "inherits"), fn))
    expect_error(add_cross_rule(s, el, c("type", "inherits"), fn))
    expect_error(add_cross_rule(v, el, c("type", "inherits"), fn))
  }
})

test_that(
  "add_cross_rule errors on cross rule name conflict with schema names",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fn <- function(x, ...) {}
    for (el in c("type", "inherits", "max_length", "min_length")) {
      expect_error(add_cross_rule(r, el, c("type", "inherits"), fn))
      expect_error(add_cross_rule(s, el, c("type", "inherits"), fn))
      expect_error(add_cross_rule(v, el, c("type", "inherits"), fn))
    }
  }
)

test_that("add_cross_rule errors on invalid rule names", {
  r <- Registry()
  s <- Schema(list(type = "integer"))
  v <- Validator(1L, s)
  fn <- function(x, y, ...) {}
  for (el in list(
    1L, NA_character_, NULL, "", c("", "b"),
    c(NA_character_, "b"), c("not_a_rule", "inherits")
  )) {
    expect_error(add_cross_rule(r, "new_cross_rule", el, fn))
    expect_error(add_cross_rule(s, "new_cross_rule", el, fn))
    expect_error(add_cross_rule(v, "new_cross_rule", el, fn))
  }
})

test_that("add_cross_rule errors on non-function rules", {
  r <- Registry()
  s <- Schema(list(type = "integer"))
  v <- Validator(1L, s)
  for (el in list(1L, NA_character_, NULL, "", c("a", "b"))) {
    expect_error(
      add_cross_rule(r, "not_a_function", c("type", "inherits"), el)
    )
    expect_error(
      add_cross_rule(s, "not_a_function", c("type", "inherits"), el)
    )
    expect_error(
      add_cross_rule(v, "not_a_function", c("type", "inherits"), el)
    )
  }
})

test_that(
  "add_cross_rule method errors on invalid cross rule function args",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fns <- list(
      too_few = function(x) {},
      no_dots = function(x, y) {},
      dots_and_keyword = function(.self, ...) {},
      dots_and_keyword2 = function(.schema, ...) {},
      both_keywords_and_dots = function(.self, .schema, ...) {},
      too_many = function(x, y, z, ...) {},
      wrong_keyword = function(x, .data, ...) {}
    )
    for (fn in fns) {
      expect_error(
        add_cross_rule(r, "fn_invalid_args", c("type", "inherits"), fn)
      )
      expect_error(
        add_cross_rule(s, "fn_invalid_args", c("type", "inherits"), fn)
      )
      expect_error(
        add_cross_rule(v, "fn_invalid_args", c("type", "inherits"), fn)
      )
    }
  }
)

test_that(
  "add_cross_rule method accepts valid cross rule function args",
  {
    r <- Registry()
    s <- Schema(list(type = "integer"))
    v <- Validator(1L, s)
    fns <- list(
      arg_and_dots = function(x, ...) {},
      arg_dots_and_keyword = function(x, .self, ...) {},
      arg_dots_and_keyword2 = function(x, .schema, ...) {},
      arg_both_keywords = function(x, .self, .schema) {}
    )
    for (fn in fns) {
      expect_no_error(
        add_cross_rule(r, "fn_invalid_args", c("type", "inherits"), fn)
      )
      expect_no_error(
        add_cross_rule(s, "fn_invalid_args", c("type", "inherits"), fn)
      )
      expect_no_error(
        add_cross_rule(v, "fn_invalid_args", c("type", "inherits"), fn)
      )
    }
  }
)
