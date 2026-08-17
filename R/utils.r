"%allin%" <- function(lhs, rhs) !anyNA(match(lhs, rhs))
"%nonein%" <- function(lhs, rhs) sum(match(lhs, rhs, nomatch = 0L)) == 0L
"%onein%" <- function(lhs, rhs) sum(lhs %in% rhs) == 1L
# to match new base R version
"%notin%" <- function(x, table) match(x, table, nomatch = 0L) == 0L

fml_args <- function(x) formals(args(x))

is_integerish <- function(x) {
  (x %% 1) == 0
}

is_bool <- function(x) {
  is.logical(x) && length(x) == 1 && !is.na(x)
}

p0_newline_collapse <- function(..., newline) {
  paste0(..., "\n", paste0(newline, collapse = "\n"), collapse = "\n")
}

is_list_all_null <- function(x) {
  if (is.null(unlist(x))) {
    TRUE
  } else {
    FALSE
  }
}

is_list_string_scalar_positive_integerish <- function(x) {
  all(
    vapply(x, function(x) {
      is_nz_string(x) || (is_positive_scalar_numeric(x) && is_integerish(x))
    }, logical(1))
  )
}

# mimic vctrs::obj_is_list()
.fl_obj_is_list <- function(x) {
  # not including the "AsIs" as TRUE like vctrs does,
  # may change in future
  typeof(x) == "list" &&
    is.null(dim(x)) &&
    (is.null(class(x)) || class(x)[length(class(x))] == "list")
}

all_duplicates <- function(x) {
  duplicated(x) | duplicated(x, fromLast = TRUE)
}

is_nz_string <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
}

is_nz_chr <- function(x, minlength = 1L) {
  is.character(x) && length(x) >= minlength && !anyNA(x) && all(nzchar(x))
}

is_ne_atomic <- function(x) {
  is.atomic(x) && length(x) > 0
}

is_scalar_numeric <- function(x) {
  is.numeric(x) && length(x) == 1 && is.finite(x)
}

is_positive_scalar_numeric <- function(x) {
  is.numeric(x) && length(x) == 1 && is.finite(x) && x > 0
}

is_numeric_print_option <- function(x) {
  is_positive_scalar_numeric(x) && is_integerish(x)
}

remove_null_list_els <- function(x) {
  if (!is.list(x)) {
    return(x)
  }

  x <- lapply(x, remove_null_list_els)
  x <- x[!vapply(x, is.null, logical(1))]

  if (length(x) == 0) {
    return(NULL)
  }

  x
}

to_pathnames <- function(x, lhs_bracket = "[[", rhs_bracket = "]]") {
  nms <- names(x)
  j <- seq_along(x)

  if (is.null(nms)) {
    names(x) <- paste0(lhs_bracket, j, rhs_bracket)
  } else {
    nms[!nzchar(nms)] <- paste0(lhs_bracket, j[!nzchar(nms)], rhs_bracket)
    names(x) <- nms
  }

  for (i in j) {
    if (is.list(x[[i]])) {
      x[[i]] <- to_pathnames(x[[i]], lhs_bracket, rhs_bracket)
    }
  }

  x
}

to_data_pathnames <- function(
  x,
  rule_names,
  lhs_bracket = "[[",
  rhs_bracket = "]]"
) {
  nms <- names(x)
  n_rules <- sum(rule_names %in% nms)
  j <- seq_along(x)
  v <- j - n_rules

  if (is.null(nms)) {
    names(x) <- paste0(lhs_bracket, j, rhs_bracket)
  } else {
    nms[!nzchar(nms)] <- paste0(lhs_bracket, v[!nzchar(nms)], rhs_bracket)
    names(x) <- nms
  }

  for (i in j) {
    if (is.list(x[[i]])) {
      x[[i]] <- to_data_pathnames(x[[i]], rule_names, lhs_bracket, rhs_bracket)
    }
  }

  x
}

has_nested_element <- function(x, path) {
  for (i in seq_along(path)) {
    p <- path[[i]]
    if (is.numeric(p)) {
      if (p > length(x)) {
        return(FALSE)
      }
    } else {
      if (p %notin% names(x)) {
        return(FALSE)
      }
    }
    if (i < length(path)) x <- x[[p]]
  }
  TRUE
}

collect_matching_names <- function(x, targets) {
  recurse <- function(obj) {
    res <- character(0)
    nms <- names(obj)
    if (!is.null(nms)) {
      res <- c(res, nms[nms %in% targets])
    }

    if (.fl_obj_is_list(obj)) {
      for (el in obj) {
        res <- c(res, recurse(el))
      }
    }

    unique(res)
  }

  recurse(x)
}

stop_if_rules_present <- function(x, rules) {
  if (length(found <- collect_matching_names(x, rules))) {
    stop(
      "Data cannot have elements with the same name as rules.\n",
      "Found: ", backtick(found), ".",
      call. = FALSE
    )
  }
}
