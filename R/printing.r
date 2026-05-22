wchar <- function(x) nchar(x, type = "width")

backtick <- function(x) paste0("`", x, "`", collapse = ", ")

paste_as_path <- function(x) {
  paste0(
    "[[",
    lapply(x, function(x) {
      if (is.character(x)) paste0("'", x, "'") else x
    }),
    "]]",
    collapse = ""
  )
}

#' @export
"print.fluffy::Registry" <- function(
  x, width = getOption("width") - 20L, give.attr = FALSE, ...
) {
  utils::str(x, width = width, give.attr = give.attr, ...)
}

#' @export
"print.fluffy::Schema" <- function(
  x, width = getOption("width") - 20L, give.attr = FALSE, ...
) {
  utils::str(x, width = width, give.attr = give.attr, ...)
}

#' @export
"print.fluffy::Validator" <- function(
  x, width = getOption("width") - 20L, give.attr = FALSE, ...
) {
  utils::str(x, width = width, give.attr = give.attr, ...)
}

#' @export
print.fluffy_rule_info <- function(x, width = getOption("width") + 20L, ...) {
  x[] <- lapply(x, function(col) gsub("`", "", col))

  truncate_by_matching_width <- function(strs, widths) {
    mapply(
      function(val, w) {
        if (wchar(val) <= w) {
          return(val)
        }
        if (w <= 4) {
          return(substr(val, 1, w))
        }
        paste0(
          substr(val, 1, w - 4),
          " ..."
        )
      },
      strs, widths,
      USE.NAMES = FALSE
    )
  }

  pad <- function(str, width) {
    padding <- pmax(width - wchar(str), 0)
    paste0(str, strrep(" ", padding))
  }

  cnames <- colnames(x)

  given_widths <- vapply(
    seq_along(x),
    function(i) max(wchar(c(cnames[i], x[[i]]))),
    integer(1)
  )

  border_space <- (3L * ncol(x))
  max_col_width <- floor((width - border_space) / ncol(x))
  widths <- pmin(given_widths, max_col_width)
  cnames <- truncate_by_matching_width(cnames, widths)

  for (j in seq_along(x)) {
    x[[j]] <- truncate_by_matching_width(x[[j]], widths[j])
  }

  make_row <- function(vals) {
    vals <- mapply(pad, vals, widths, USE.NAMES = FALSE)
    paste0("|", paste(vals, collapse = "|"), "|\n")
  }

  make_sep <- function(x = "|") {
    paste0(
      x, "-",
      paste(
        vapply(
          widths - 2L,
          function(w) strrep("-", w),
          character(1)
        ),
        collapse = paste0("-", x, "-")
      ),
      "-", x, "\n"
    )
  }

  cat(make_sep("+"))
  cat(make_row(cnames))
  cat(make_sep())
  cat(make_row(as.character(x[1, ])))
  cat(make_sep())

  for (i in seq_len(nrow(x))[-1]) {
    cat(make_row(as.character(x[i, ])))
  }
  cat(make_sep("+"))
}

# based on lobstr:::box_chars()
# all credit to authors
branch_chars <- function(utf8, append_space = TRUE) {
  x <- if (utf8) {
    list("\u2514\u2500", "\u251C\u2500", "\u251C", "\u2502")
  } else {
    list("'-", "|-", "|-", "|")
  }

  if (append_space) {
    x <- lapply(x, function(x) paste0(x, " "))
  }

  names(x) <- c(
    "node", "long_junction", "short_junction", "vertical"
  )
  x
}

# based on lobstr::tree()
# all credit to authors
error_tree <- function(
  x,
  max_depth,
  max_width,
  max_rows,
  utf8
) {
  state <- new.env(parent = emptyenv())
  state$n <- 0L
  state$truncated <- FALSE
  branches <- branch_chars(utf8)

  truncate_tree_line <- function(line, trunc_prefix = "msg") {
    if (wchar(line) <= max_width) {
      return(line)
    }
    j <- paste0(" ...[", trunc_prefix, " truncated]")
    paste0(substr(line, 1, max(1, max_width - wchar(j))), j)
  }

  txt <- error_tree_lines(
    x,
    prefix = "",
    depth = 0L,
    max_depth = max_depth,
    max_width = max_width,
    max_rows = max_rows,
    state = state,
    branches = branches,
    trunc_fn = truncate_tree_line
  )

  if (state$truncated) {
    txt <- c(txt, "...[errors truncated]")
  }

  paste0(txt, collapse = "\n")
}

error_tree_lines <- function(
  x,
  prefix,
  depth,
  max_depth,
  max_width,
  max_rows,
  state,
  branches,
  trunc_fn
) {
  stopifnot(is.list(x))

  n <- length(x)
  if (n == 0) {
    return(character())
  }
  lines <- character()

  for (i in seq_along(x)) {
    if (state$n >= max_rows) {
      state$truncated <- TRUE
      break
    }

    name <- names(x)[i]
    val <- x[[i]]
    last <- i == n

    branch <- if (last) branches$node else branches$long_junction
    line_prefix <- paste0(prefix, branch)

    if (depth >= max_depth) {
      line <- paste0(line_prefix, " ...[msg truncated]")
      lines <- c(lines, trunc_fn(line, trunc_prefix = "depth"))
      state$n <- state$n + 1L
      next
    }

    if (is.list(val)) {
      line <- paste0(line_prefix, name)
      lines <- c(lines, trunc_fn(line))
      state$n <- state$n + 1L

      child_prefix <- paste0(prefix, if (last) "  " else branches$vertical)

      child_lines <- error_tree_lines(
        val,
        prefix = child_prefix,
        depth = depth + 1L,
        max_depth = max_depth,
        max_width = max_width,
        max_rows = max_rows,
        state = state,
        branches = branches,
        trunc_fn = trunc_fn
      )

      lines <- c(lines, child_lines)
    } else {
      txt <- val
      line <- paste0(line_prefix, name, ": ", txt)
      lines <- c(lines, trunc_fn(line))
      state$n <- state$n + 1L
    }
  }

  lines
}
