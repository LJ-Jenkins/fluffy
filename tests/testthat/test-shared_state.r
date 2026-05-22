test_that(".data can reach up the tree", {
  s <- Schema(
    list(
      a = list(apply = "function(x) x + 1"),
      list(
        b = list(apply = "function(x, .data, ...) if (.data[['a']] == 2) x + 1")
      )
    )
  )
  v <- Validator(list(a = 1, list(b = 1)), s)

  expect_true(v@valid)
  expect_equal(v@data[["a"]], 2)
  expect_equal(v@data[[2]][["b"]], 2)

  s <- Schema(
    list(
      a = list(apply = "function(x) x + 1"),
      list(
        b = list(predicate = "function(x, .data, ...) .data[['a']] == 2")
      )
    )
  )
  v <- Validator(list(a = 2, list(b = 1)), s)

  expect_false(v@valid)
  expect_equal(v@errors[[2]][["b"]]$predicate, "Does not satisfy predicate.")
})

test_that(".data can reach down the tree", {
  s <- Schema(
    list(
      list(list(a = list(apply = "function(x) x + 1"))),
      b = list(
        apply = "function(x, .data, ...) if (.data[[1]][[1]][['a']] == 2) x + 1"
      )
    )
  )
  v <- Validator(list(list(list(a = 1)), b = 1), s)

  expect_true(v@valid)
  expect_equal(v@data[[1]][[1]][["a"]], 2)
  expect_equal(v@data[["b"]], 2)

  s <- Schema(
    list(
      list(list(a = list(apply = "function(x) x + 1"))),
      b = list(
        predicate = "function(x, .data, ...) .data[[1]][[1]][['a']] == 2"
      )
    )
  )
  v <- Validator(list(list(list(a = 2)), b = 1), s)

  expect_false(v@valid)
  expect_equal(v@errors[["b"]]$predicate, "Does not satisfy predicate.")
})

test_that(".data reflects changed atomic elements", {
  s <- Schema(
    list(
      list(
        apply = "function(x, .data, ...) if (.data[[1]] == 0) x + 1"
      ),
      list(
        apply = "function(x, .data, ...) if (.data[[1]] == 1) x + 2"
      ),
      list(
        apply = "function(x, .data, ...) if (.data[[2]] == 2) x + 3"
      )
    )
  )
  v <- Validator(c(0, 0, 0), s)

  expect_true(v@valid)
  expect_equal(v@data, 1:3)

  s <- Schema(
    list(
      list(
        apply = "function(x, .data, ...) if (.data[[1]] == 0) x + 1"
      ),
      list(
        apply = "function(x, .data, ...) if (.data[[1]] == 1) x + 2"
      ),
      list(
        predicate = "function(x, .data, ...) .data[[2]] == 3"
      )
    )
  )
  v <- Validator(c(0, 0, 0), s)

  expect_false(v@valid)
  expect_equal(v@errors[[3]]$predicate, "Does not satisfy predicate.")
})

test_that(".data reflects changed dataframe columns", {
  s <- Schema(
    list(
      x = list(coerce = "double"),
      y = list(
        apply = "function(x, .data, ...) if (typeof(.data[['x']]) == 'double') as.character(x)"
      )
    )
  )
  v <- Validator(data.frame(x = 1L, y = 1L), s)

  expect_true(v@valid)
  expect_equal(typeof(v@data[["x"]]), "double")
  expect_equal(typeof(v@data[["y"]]), "character")

  s <- Schema(
    list(
      x = list(coerce = "double"),
      y = list(
        apply = "function(x, .data, ...) if (typeof(.data[['x']]) == 'integer') as.character(x)"
      )
    )
  )
  v <- Validator(data.frame(x = 1L, y = 1L), s)

  expect_true(v@valid)
  expect_equal(typeof(v@data[["x"]]), "double")
  expect_equal(typeof(v@data[["y"]]), "integer")
})
