# fluffy

Validate R objects against user-defined schemas, with informative errors
and data transformation.

## Installation

Install the latest release of fluffy from CRAN:

``` r

install.packages("fluffy")
```

You can install the development version of fluffy from GitHub:

``` r

# install.packages("pak")
pak::pak("LJ-Jenkins/fluffy")
```

## Basic Usage

``` r

library(fluffy)

df <- data.frame(x = 1:3, y = c(" a", "b  ", " c"))

v <- Validator(
  data = df,
  schema = list(
    type = "data.frame",
    min_nrow = 1,
    x = list(
      type = "numeric",
      max_val = 5
    ),
    y = list(
      type = "character",
      apply = function(x) trimws(x),
      nzchar = TRUE
    )
  )
)

#- Specified data is transformed
v@data
#>   x y
#> 1 1 a
#> 2 2 b
#> 3 3 c

#- Overall validity
v@valid
#> [1] TRUE

#- Structured errors property
v@errors
#> $type
#> NULL
#> 
#> $min_nrow
#> NULL
#> 
#> $x
#> $x$type
#> NULL
#> 
#> $x$max_val
#> NULL
#> 
#> 
#> $y
#> $y$apply
#> NULL
#> 
#> $y$type
#> NULL
#> 
#> $y$nzchar
#> NULL

#- Informative errors that reflect the perceived data structure
Validator(
  data = list(1, a = "a", b = 10, x = -1),
  schema = list(
    type = "data.frame",
    list(type = "character"),
    a = list(min_nchar = 2),
    b = list(min_length = 2, max_val = 5),
    x = list(positive = TRUE)
  ),
  error = TRUE
)
#> Error:
#> ! <fluffy::Validator> object is invalid:
#> - Data validation failed with the following errors:
#> ├─ type: Is not type `data.frame`.
#> ├─ [[1]]
#> │ └─ type: Is not type `character`.
#> ├─ a
#> │ └─ min_nchar: Char length(s) must be at least 2.
#> ├─ b
#> │ ├─ max_val: Value(s) must be at most 5.
#> │ └─ min_length: Length must be at least 2.
#> └─ x
#>   └─ positive: Value(s) must be positive (or zero).

#- Transformed data can be accessed during the validation
Validator(
  data = list(a = 1, b = 1),
  schema = list(
    a = list(apply = "function(x) x + 1"),
    b = list(apply = function(x, .data, ...) if (.data[["a"]] > 1) x + 1)
  )
)@data
#> $a
#> [1] 2
#> 
#> $b
#> [1] 2

#- Extensible
s <- Schema(list(double_if_five_else_error = TRUE))
s@valid
#> [1] FALSE
s@errors
#> $double_if_five_else_error
#> [1] "Unknown rule: `double_if_five_else_error`."

s <- add_rule(
  s,
  name = "double_if_five_else_error",
  validator_fn = function(field, schema_field, ...) {
    if (schema_field) {
      if (length(field) != 1L) {
        list(error = "Field must be length 1.")
      } else if (field != 5) {
        list(error = "Does not equal 5.")
      } else {
        list(data = field * 2)
      }
    }
  },
  schema_fn = function(schema_field, ...) {
    if (!isTRUE(schema_field) && !isFALSE(schema_field)) {
      "Must be a boolean."
    }
  },
  rule_type = "transform"
)
s@valid
#> [1] TRUE

v <- Validator(data = 5, schema = s)
v@valid
#> [1] TRUE
v@data
#> [1] 10
Validator(data = 1, schema = s, error = TRUE)
#> Error:
#> ! <fluffy::Validator> object is invalid:
#> - Data validation failed with the following errors:
#> └─ double_if_five_else_error: Does not equal 5.

#- Works on numerous non-empty R object types, with data elements able to be
# validated if they can be accessed with `[[`.
Validator(
  call("mean", 1:10),
  list(
    type = "call",
    list(type = "name"),
    list(predicate = "function(x) identical(x, 1:10)")
  )
)@valid
#> [1] TRUE
Validator(expression(x + 1), list(type = "expression"))@valid
#> [1] TRUE
Validator(table(x = 1), list(type = "table"))@valid
#> [1] TRUE
Validator(new.env(), list(type = "environment"))@valid
#> Error:
#> ! <fluffy::Validator>@data cannot be empty
e <- new.env()
e$a <- 1L
e$b <- "Hi"
Validator(
  e,
  list(
    type = "environment",
    a = list(type = "integer"),
    b = list(type = "character")
  )
)@valid
#> [1] TRUE
```

## Overview

fluffy provides three [S7](https://CRAN.R-project.org/package=S7)
classes: `Registry`, `Schema`, and `Validator`.

`Registry` defines rules and stores all built-in fluffy rule names and
definitions.

``` r

r <- Registry()

S7::prop_names(r)
#>  [1] "rule_names"          "control_rules"       "transform_rules"    
#>  [4] "validate_rules"      "finalize_rules"      "str_to_fn_rules"    
#>  [7] "str_to_fn_converter" "type_names"          "type_map"           
#> [10] "coerce_names"        "coerce_map"          "schema_rules"       
#> [13] "cross_rule_names"    "cross_rules"         "validator_rules"
```

`Schema` takes a user-defined nested list schema, validates the schema,
and reorders the schema according to the order defined in the
`Registry`. By default `Schema` creates a `Registry` if one is not
passed to the function.

``` r

s <- Schema(list(type = "integer", default = 1L))

s@schema
#> $default
#> [1] 1
#> 
#> $type
#> [1] "integer"

S7::prop_names(s)
#> [1] "schema"           "errors"           "Registry"         ".schema_cache"   
#> [5] "error"            "error_print_opts" "valid"
```

`Validator` takes data and a user-defined `Schema`, and applies each
`Schema` field against the data. It does this in four passes:

1.  control rules: rules that can alter control flow and stop other
    rules operating, e.g., `required`.
2.  transform rules: rules that can modify the data, e.g., `apply` and
    `coerce`.
3.  validate rules: rules that check the data against the schema, e.g.,
    `type` and `min_val`.
4.  finalize rules: rules that only operate if all other rules in the
    schema node passed validation without error, e.g., `apply_last` and
    `coerce_last`.

A list given as a schema will be passed to
[`Schema()`](https://lj-jenkins.github.io/fluffy/reference/Schema.md) on
ingest.

``` r

v <- Validator(
  data = list(a = 1, b = "Hello"),
  schema = list(
    a = list(
      type = "numeric",
      min_val = 0,
      max_val = 5
    ),
    b = list(
      type = "character",
      apply = "\\(x) paste(x, 'World!')"
    ),
    c = list(
      required = FALSE,
      type = "data.frame"
    ),
    d = list(
      default = 10L
    )
  )
)

v@data
#> $a
#> [1] 1
#> 
#> $b
#> [1] "Hello World!"
#> 
#> $d
#> [1] 10

S7::prop_names(v)
#> [1] "data"             "Schema"           "errors"           ".validator_cache"
#> [5] "error"            "valid"
```

Using list schemas but virtually any R type for validation, fluffy can
be used on a range of data types once loaded into R.

``` r

yaml_schema <- yaml::yaml.load(
  "
  type: 'list'
  a:
    type: 'character'
  b:
    type: 'list'
    a:
      type: 'numeric'
    b:
      type: 'character'
      min_nchar: 3
  "
)

yaml_data <- yaml::yaml.load(
  "
  a: 1
  b:
    a: 1
    b: 'Hi'
  "
)

Validator(yaml_data, yaml_schema, error = TRUE)
#> Error:
#> ! <fluffy::Validator> object is invalid:
#> - Data validation failed with the following errors:
#> ├─ a
#> │ └─ type: Is not type `character`.
#> └─ b
#>   └─ b
#>     └─ min_nchar: Char length(s) must be at least 3.

json_schema <- jsonlite::fromJSON(
  '{
    "type": "list",
    "a": {
      "type": "numeric",
      "min_length": 2
    },
    "b": {
      "type": "list",
      "a": {
        "type": "numeric",
        "max_val": 5
      },
      "b": {
        "type": "character"
      }
    }
  }'
)

json_data <- jsonlite::fromJSON(
  '{
    "a": 1,
    "b": {
      "a": 10,
      "b": "Hi"
    }
  }'
)

Validator(json_data, json_schema, error = TRUE)
#> Error:
#> ! <fluffy::Validator> object is invalid:
#> - Data validation failed with the following errors:
#> ├─ a
#> │ └─ min_length: Length must be at least 2.
#> └─ b
#>   └─ a
#>     └─ max_val: Value(s) must be at most 5.

# rectangular data, from `readr` readme
# works for any data.frame data, e.g., sav, dta, xls, xlsx, csv, tsv, etc.
rect_schema <- list(
  type = "data.frame",
  chicken = list(
    type = "character",
    nzchar = TRUE
  ),
  sex = list(
    coerce = "factor",
    levels = c("rooster", "hen")
  ),
  eggs_laid = list(
    type = "integer",
    positive = TRUE
  ),
  motto = list(
    type = "character",
    nzchar = TRUE
  )
)

rect_data <- readr::read_csv(
  readr::readr_example("chickens.csv"),
  show_col_types = FALSE
)

Validator(rect_data, rect_schema, error = TRUE)
#> Error:
#> ! <fluffy::Validator> object is invalid:
#> - Data validation failed with the following errors:
#> └─ eggs_laid
#>   └─ type: Is not type `integer`.
```

## Vignettes

For detailed information on using fluffy, see the vignettes:

- [Builtin
  rules](https://lj-jenkins.github.io/fluffy/articles/validation-rules.html)

- [Creating Schemas and Validating
  Data](https://lj-jenkins.github.io/fluffy/articles/validating-data.html)

- [Adding custom
  rules](https://lj-jenkins.github.io/fluffy/articles/custom-rules.html)

## Notes

fluffy was inspired by and modelled on Python’s
[Cerberus](https://github.com/pyeve/cerberus) (hence the name!).

Error printing in fluffy was modelled on
[lobstr](https://lobstr.r-lib.org/)’s tree function.

fluffy was originally called ‘RV’ but was renamed to distinguish itself
from the [rv package manager](https://github.com/A2-ai/rv).

## Getting help

If you encounter a clear bug, please file an issue with a minimal
reproducible example on
[GitHub](https://github.com/LJ-Jenkins/fluffy/issues).

## Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://lj-jenkins.github.io/fluffy/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
