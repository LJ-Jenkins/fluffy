test_that("validation by schema for matching structures", {
  # named
  s <- Schema(
    list(
      a = list(type = "numeric"),
      b = list(
        type = "character",
        apply = function(x) paste0("Hello, ", x, "!")
      )
    )
  )
  d <- list(a = 42, b = "World")
  v <- Validator(d, s)

  expect_true(v@valid)
  expect_equal(v@data, list(a = 42, b = "Hello, World!"))
  expect_equal(
    v@errors,
    list(
      a = list(type = NULL),
      b = list(apply = NULL, type = NULL)
    )
  )

  # unnamed
  names(s@schema) <- NULL
  names(d) <- NULL
  v <- Validator(d, s)

  expect_true(v@valid)
  expect_equal(v@data, list(42, "Hello, World!"))
  expect_equal(
    v@errors,
    list(
      list(type = NULL),
      list(apply = NULL, type = NULL)
    )
  )

  # mix
  names(s@schema) <- c("", "b")
  names(d) <- c("", "b")
  v <- Validator(d, s)

  expect_true(v@valid)
  expect_equal(v@data, list(42, b = "Hello, World!"))
  expect_equal(
    v@errors,
    list(
      list(type = NULL),
      b = list(apply = NULL, type = NULL)
    )
  )
})

test_that("validation by schema for structures with different orders", {
  # named
  s <- Schema(
    list(
      b = list(
        type = "character",
        apply = function(x) paste0("Hello, ", x, "!")
      ),
      a = list(type = "numeric")
    )
  )
  d <- list(a = 42, b = "World")
  v <- Validator(d, s)

  expect_true(v@valid)
  expect_equal(v@data, list(a = 42, b = "Hello, World!"))
  expect_equal(
    v@errors,
    list(
      b = list(apply = NULL, type = NULL),
      a = list(type = NULL)
    )
  )

  # unnamed
  s <- Schema(
    list(
      list(
        type = "character",
        apply = function(x) paste0("Hello, ", x, "!")
      ),
      list(type = "numeric")
    )
  )
  d <- list(42, "World")
  v <- Validator(d, s)

  expect_false(v@valid)
  expect_equal(v@data, list("Hello, 42!", "World"))
  expect_equal(
    v@errors,
    list(
      list(
        apply = NULL,
        type = NULL # apply occurs first and converts
      ),
      list(type = "Is not type `numeric`.")
    )
  )

  # mix
  s <- Schema(
    list(
      list(type = "numeric"),
      list(type = "integer"),
      b = list(
        type = "character",
        apply = function(x) paste0("Hello, ", x, "!")
      )
    )
  )
  d <- list(42, b = "World")
  v <- Validator(d, s)

  expect_false(v@valid)
  expect_equal(v@data, list(42, b = "Hello, World!"))
  expect_equal(
    v@errors,
    list(
      list(type = NULL),
      list(type = "Is not type `integer`."),
      b = list(apply = NULL, type = NULL)
    )
  )
})

test_that("validation by schema for schema bigger than data", {
  s <- Schema(
    list(
      a = list(
        b = list(
          type = "numeric",
          apply = function(x) x + 1
        ),
        list(
          type = "character",
          apply = function(x) paste0("Hello, ", x, "!")
        )
      ),
      b = list(
        type = "character",
        predicate = function(x) x == "Woah"
      ),
      list(
        coerce = "integer"
      )
    )
  )

  d <- list(a = list(b = 42))

  v <- Validator(d, s)
  expect_false(v@valid)
  expect_equal(v@data, list(a = list(b = 43)))
  expect_equal(
    v@errors,
    list(
      a = list(
        b = list(
          apply = NULL,
          type = NULL
        ),
        list(
          apply = "No data for field.",
          type = NULL # no data for field skips
        )
      ),
      b = list(
        type = "No data for field.",
        predicate = NULL
      ),
      list(
        coerce = "No data for field."
      )
    )
  )

  s <- Schema( # example showing problems with named and unnamed
    list(
      a = list(
        b = list(
          type = "numeric",
          apply = function(x) x + 1
        )
      ),
      list(
        type = "character",
        apply = function(x) paste0("Hello, ", x, "!")
      ),
      b = list(
        type = "character",
        predicate = function(x) x == "Woah"
      ),
      list(
        coerce = "integer"
      ),
      type = "list",
      max_length = 1
    )
  )

  d <- list(a = list(b = 42), b = "World")

  v <- Validator(d, s)
  expect_false(v@valid)
  expect_equal(v@data, list(a = list(b = 43), b = "Hello, World!"))
  expect_equal(v@errors, list(
    type = NULL,
    max_length = "Length must be at most 1.",
    a = list(
      b = list(
        apply = NULL,
        type = NULL
      )
    ),
    list(
      apply = NULL,
      type = NULL
    ),
    b = list( # data element validated twice... user error! but we allow.. for now..
      type = NULL,
      predicate = "Does not satisfy predicate."
    ),
    list(
      coerce = "No data for field."
    )
  ))
})

test_that("validation by schema for schema smaller than data", {
  s <- Schema(
    list(
      a = list(b = list(type = "numeric")),
      z = list(max_val = 10),
      list(type = "integer")
    )
  )

  d <- list(
    a = list(
      b = 42,
      c = "extra field",
      100
    ),
    list("what's this"),
    1L,
    z = c(1, 5, 9)
  )

  v <- Validator(d, s)

  expect_true(v@valid)
})

test_that("validation by schema of depth 1", {
  s <- Schema(
    list(
      type = "character",
      max_length = 10,
      max_nchar = 10
    )
  )

  v <- Validator(list("Hello"), s)

  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      type = "Is not type `character`.",
      max_length = NULL,
      max_nchar = NULL
    )
  )

  v <- Validator("Hello", s)

  expect_true(v@valid)
  expect_equal(
    v@errors,
    list(
      type = NULL,
      max_length = NULL,
      max_nchar = NULL
    )
  )


  v <- Validator(list(1L, "Hello"), s)
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      type = "Is not type `character`.",
      max_length = NULL,
      max_nchar = NULL
    )
  )

  v <- Validator(
    list(1L, "Hello"), list(type = "list")
  )
  expect_true(v@valid)
})

test_that("validation by schema of data.frames and df elements", {
  # 1d
  s <- Schema(
    list(
      type = "data.frame",
      apply = function(df) {
        df$z <- df$x + df$y
        df
      }
    )
  )

  d <- data.frame(x = 1:3, y = 4:6)
  v <- Validator(d, s)

  expect_true(v@valid)
  expect_equal(
    v@data,
    data.frame(x = 1:3, y = 4:6, z = c(5, 7, 9))
  )

  # >1d
  s <- Schema(
    list(
      a = list(
        type = "data.frame",
        apply = function(df) {
          df$z <- df$x + df$y
          df
        }
      )
    )
  )

  d <- list(1L, a = data.frame(x = 1:3, y = 4:6), "hello")
  v <- Validator(d, s)
  expect_true(v@valid)
  expect_equal(
    v@data,
    list(1L, a = data.frame(x = 1:3, y = 4:6, z = c(5, 7, 9)), "hello")
  )

  s <- Schema(
    list(
      list(type = "integer"),
      list(list(list(
        type = "data.frame",
        apply = function(df) {
          df$z <- df$x + df$y
          df
        }
      ))),
      list(type = "character")
    )
  )

  d <- list(1L, list(list(data.frame(x = 1:3, y = 4:6))), "hello")
  v <- Validator(d, s)

  expect_true(v@valid)
  expect_equal(
    v@data,
    list(
      1L,
      list(list(data.frame(x = 1:3, y = 4:6, z = c(5, 7, 9)))),
      "hello"
    )
  )

  s <- Schema(
    list(
      list(type = "integer"),
      list(list(list(
        x = list(type = "numeric"),
        y = list(type = "numeric")
      ))),
      list(type = "character")
    )
  )

  v <- Validator(d, s)

  expect_true(v@valid)
  expect_equal(
    v@data,
    list(
      1L,
      list(list(data.frame(x = 1:3, y = 4:6))),
      "hello"
    )
  )

  d <- list(1L, list(list(data.frame(x = 1:3, y = 4:6))), "hello")

  s <- Schema(
    list(
      list(type = "integer"),
      list(list(list(
        type = "data.frame",
        apply = function(df) {
          df$z <- df$x + df$y
          df
        },
        x = list(type = "numeric"),
        y = list(type = "numeric"),
        z = list(type = "numeric")
      ))),
      list(type = "character")
    )
  )
  expect_true(s@valid)
  v <- Validator(d, s)
  expect_true(v@valid)

  v <- Validator(
    data.frame(x = 1, y = 2, z = 3),
    list(
      x = list(predicate = function(x) x == 1),
      y = list(predicate = function(x) x == 9),
      z = list(predicate = function(x) x == 3),
      a = list(type = "character")
    )
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      x = list(predicate = NULL),
      y = list(predicate = "Does not satisfy predicate."),
      z = list(predicate = NULL),
      a = list(type = "No data for field.")
    )
  )
})

test_that("validation by schema on atomics", {
  v <- Validator(
    42, list(type = "numeric")
  )
  expect_true(v@valid)
  expect_equal(v@data, 42)
  expect_equal(v@errors, list(type = NULL))

  v <- Validator(
    42, list(type = "numeric", list(min_val = 40), list(max_val = 50))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      type = NULL,
      list(min_val = NULL),
      list(max_val = "No data for field.")
    )
  )

  v <- Validator(
    1:10,
    list(type = "numeric", list(predicate = function(x) x > 2))
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(type = NULL, list(predicate = "Does not satisfy predicate."))
  )

  v <- Validator(
    c("name@email.com", "invalid_email"),
    list(type = "character", regex = "@email.com")
  )
  expect_false(v@valid)
  expect_equal(
    v@errors,
    list(
      type = NULL,
      regex = "String(s) do not match regex pattern `@email.com`."
    )
  )

  v <- Validator(
    c("name@email.com", "invalid_email"),
    list(
      type = "character",
      apply = function(x) {
        i <- !endsWith(x, "@email.com")
        x[i] <- paste0(x[i], "@email.com")
        x
      },
      regex = "@email.com"
    )
  )
  expect_true(v@valid)
  expect_equal(
    v@errors,
    list(
      apply = NULL,
      type = NULL,
      regex = NULL
    )
  )
})
