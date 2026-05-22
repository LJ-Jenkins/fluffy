test_that("has_nested_element correctly identifies nested elements", {
  x <- list(
    a = 1,
    b = list(
      c = 2,
      d = list(
        e = 3,
        f = list(g = 4)
      )
    ),
    h = list(i = 5, j = 6),
    k = c(7, 8, 9)
  )

  single_index <- list(list(1), list(2), list(3), list(4))
  single_index_vec <- c(1, 2, 3, 4)
  for (i in seq_along(single_index)) {
    expect_true(has_nested_element(x, single_index[[i]]))
  }

  single_name <- list(list("a"), list("b"), list("h"), list("k"))
  single_name_vec <- c("a", "b", "h", "k")
  for (i in seq_along(single_name)) {
    expect_true(has_nested_element(x, single_name[[i]]))
    expect_true(has_nested_element(x, single_name_vec[i]))
  }

  nested_index <- list(list(2, 1), list(2, 2, 1), list(2, 2, 2, 1), list(3, 1))
  nested_index_vec <- list(c(2, 1), c(2, 2, 1), c(2, 2, 2, 1), c(3, 1))
  for (i in seq_along(nested_index)) {
    expect_true(has_nested_element(x, nested_index[[i]]))
    expect_true(has_nested_element(x, nested_index_vec[[i]]))
  }

  nested_names <- list(
    list("b", "c"),
    list("b", "d", "e"),
    list("b", "d", "f", "g"),
    list("h", "i"),
    list("h", "j")
  )
  nested_names_vec <- list(
    c("b", "c"),
    c("b", "d", "e"),
    c("b", "d", "f", "g"),
    c("h", "i"),
    c("h", "j")
  )
  for (i in seq_along(nested_names)) {
    expect_true(has_nested_element(x, nested_names[[i]]))
    expect_true(has_nested_element(x, nested_names_vec[[i]]))
  }

  mixed_paths <- list(
    list(2, "c"),
    list(2, 2, "e"),
    list("b", 2, "e"),
    list(3, "i")
  )
  for (i in seq_along(mixed_paths)) {
    expect_true(has_nested_element(x, mixed_paths[[i]]))
  }

  # Paths to non-list elements (still exist)
  expect_true(has_nested_element(x, list("a")))
  expect_true(has_nested_element(x, list("k", 2)))
})

test_that(
  "has_nested_element correctly returns FALSE for non-existent elements",
  {
    x <- list(
      a = 1,
      b = list(
        c = 2,
        d = list(
          e = 3,
          f = list(g = 4)
        )
      ),
      h = list(i = 5, j = 6),
      k = c(7, 8, 9)
    )

    not_present <- list(
      list("z"), list("b", "x"), list("b", "d", "y"),
      list(10), list(2, 3), list(2, 2, 3), list(2, 2, 2, 2),
      list("b", 3), list(2, "d", 3)
    )
    for (path in not_present) {
      expect_false(has_nested_element(x, path))
    }

    not_present_vec <- list(
      c("z"), c("b", "x"), c("b", "d", "y"),
      c(10), c(2, 3), c(2, 2, 3), c(2, 2, 2, 2)
    )
    for (path in not_present_vec) {
      expect_false(has_nested_element(x, path))
    }
  }
)

test_that("has_nested_element treats NULL and empty vectors as valid", {
  x <- list(
    a = NULL,
    b = list(),
    c = list(d = NULL, e = list())
  )

  expect_true(has_nested_element(x, list("a")))
  expect_true(has_nested_element(x, list("b")))
  expect_true(has_nested_element(x, list("c", "d")))
  expect_true(has_nested_element(x, list("c", "e")))

  expect_false(has_nested_element(x, list("z")))
  expect_false(has_nested_element(x, list("c", "f")))
})
