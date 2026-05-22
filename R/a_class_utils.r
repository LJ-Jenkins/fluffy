nested_prop <- function(obj, nested_obj, prop) {
  # saving nano/microseconds... why not..
  S7::prop(S7::prop(obj, nested_obj), prop)
}

`nested_prop<-` <- function(obj, nested_obj, prop, check = TRUE, value) {
  S7::prop(S7::prop(obj, nested_obj), prop, check = check) <- value
  obj
}

deep_prop <- function(obj, nested_obj1, nested_obj2, prop) {
  S7::prop(S7::prop(S7::prop(obj, nested_obj1), nested_obj2), prop)
}

update_rule_env <- function(obj, prop, rule_name, to_add) {
  new_env <- list2env(as.list(S7::prop(obj, prop)))
  new_env[[rule_name]] <- to_add
  new_env
}

format_errors_prop <- function(x, opts, obj = "Schema", rule_names = NULL) {
  x <- switch(obj,
    "Schema" = to_pathnames(x),
    "Data" = to_data_pathnames(x, rule_names = rule_names),
    stop("Unknown object class in `format_errors_prop()`. Please report.")
  )

  x <- remove_null_list_els(x)
  paste0(
    obj, " validation failed with the following errors:\n",
    error_tree(x, opts$max_depth, opts$max_width, opts$max_rows, opts$UTF8)
  )
}

prop_bool_check <- function(x) {
  # class_logical does the type check
  if (length(x) != 1L || is.na(x)) "must be boolean (TRUE/FALSE)."
}

bool_prop <- S7::new_property(
  S7::class_logical,
  validator = function(value) {
    prop_bool_check(value)
  }
)

cross_rule_operating_names_check <- function(cross_rules, rule_names) {
  any(
    vapply(cross_rules, function(x) {
      any(x$rules %notin% rule_names)
    }, logical(1))
  )
}

env_prop <- function(prop_name) {
  msg <- if (endsWith(prop_name, "map")) {
    paste0("`add_", sub("map", "", prop_name), "rule()`.")
  } else if (startsWith(prop_name, "cross")) {
    "`add_cross_rule()`."
  } else {
    "`add_rule()`."
  }
  S7::new_property(
    S7::class_environment,
    setter = function(self, value) {
      if (!is.null(S7::prop(self, prop_name))) {
        stop(
          "<fluffy::Registry>@", prop_name, " can only be edited through ",
          msg,
          call. = FALSE
        )
      }
      # don't check as the default input we know to be correct
      # and the `add_*_rule()` variants call `S7::validate()` at end
      S7::prop(self, prop_name, check = FALSE) <- value
      self
    }
  )
}

env_names_prop <- function(prop_name) {
  S7::new_property(
    # using dynamic getter for now but may look to make
    # dynamic only on object change in future to stop
    # repeated calls
    getter = function(self) {
      ls(S7::prop(self, prop_name))
    }
  )
}

to_print_opts <- function(x, from_dots = FALSE) {
  defaults <- list(
    max_depth = 10L,
    max_width = getOption("width"),
    max_rows = 30L,
    UTF8 = l10n_info()[["UTF-8"]]
  )

  if (length(x) == 0L) {
    return(defaults)
  }

  allowed <- c("max_depth", "max_width", "max_rows", "UTF8")
  nms <- methods::allNames(x)
  i <- nms %notin% allowed

  if (any(i)) {
    msg <- if (from_dots) {
      "args passed from dots `...` to"
    } else {
      "named elements in"
    }

    warning(
      "Extra ", msg, " `error_print_opts` will be ignored.\n",
      "Valid names are ", paste0("`", allowed, "`", collapse = ", "), ".",
      immediate. = TRUE,
      call. = FALSE
    )
  }

  if (any(!i)) {
    for (j in which(!i)) {
      if (nms[j] == "UTF8") {
        if (!is_bool(x[[j]])) {
          stop(
            "`UTF8` must be boolean (TRUE/FALSE).",
            call. = FALSE
          )
        }
      } else {
        if (!is_numeric_print_option(x[[j]])) {
          stop(
            "`", nms[j], "` must be a single positive integer.",
            call. = FALSE
          )
        }
        x[[j]] <- as.integer(x[[j]])
      }
    }
  }

  x[i] <- NULL
  utils::modifyList(defaults, x)
}

error_print_opts_prop <- function(obj_class) {
  S7::new_property(
    setter = function(self, value) {
      if (is.null(S7::prop(self, "error_print_opts"))) {
        # not yet set, opts coming from dots
        value <- to_print_opts(value, from_dots = TRUE)
      } else {
        # after construction, so being assigned <-
        # so check that list
        if (!is.list(value)) {
          stop(
            paste0("<fluffy::", obj_class, ">@error_print_opts must be a list."),
            call. = FALSE
          )
        }
        value <- to_print_opts(value)
      }

      # no checking as the printing options should never
      # affect the obj validation
      S7::prop(self, "error_print_opts", check = FALSE) <- value
      self
    }
  )
}
