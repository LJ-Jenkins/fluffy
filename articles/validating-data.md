# Creating Schemas and Validating Data

``` r

library(fluffy)
```

fluffy schemas are nested list objects that are passed to the `Schema`
class. The class automatically re-orders and validates schema before it
is supplied to the`Validator` class for data validation. During
validation, the schema definition determines the data matching and rule
application. As a result, understanding schemas is central to using
fluffy effectively. Most of this vignette focuses on constructing
schemas, with the final section demonstrating how to use them for data
validation.

### Creating a schema list

The lists used for fluffy schemas are nested list objects with
rule-named leaf elements that determine validation behaviour. The names
or positions of the nested lists are used to match their rules to the
corresponding data elements.

``` r

list(
  type = "data.frame",
  id = list(
    type = "numeric"
  ),
  email = list(
    type = "character",
    regex = "@gmail.com$"
  ),
  list(
    min_length = 2
  )
)
```

Rules at the top level of the nested list are applied to the whole data
object. Nested list elements are matched to data elements by their name
if present or by position if there is no name present.

When matching by position, rule elements are first removed, so the first
non-rule element will always be matched against `[[1]]` of the matching
data node. See the following illustrations:

    #> <list>
    #> ├─Top level rule: "Applied to `data`."
    #> └─<list>
    #>   ├─Depth 1 rule: "Applied to `data[[1]]`."
    #>   └─<list>
    #>     └─Depth 2 rule: "Applied to `data[[1]][[1]]`."

    #> <list>
    #> ├─Top level rule: "Applied to `data`."
    #> └─x: <list>
    #>   ├─Depth 1 rule: "Applied to `data[['x']]`."
    #>   └─x: <list>
    #>     └─Depth 2 rule: "Applied to `data[['x']][['x']]`."

This behaviour continues no matter the level of nesting, so it is
possible to apply rules to deeply nested values.

    #> <list>
    #> └─<list>
    #>   └─<list>
    #>     └─<list>
    #>       └─"Applied to `data[[1]][[1]][[1]]`."

#### Double hits with positional matching

When matching schema elements to data, the `Validator` first attempts to
match by name before falling back to positional matching. As data
elements are not flagged when validated (and thus can be validated
multiple times), this can cause unexpected behaviour. See the following
example where the data is matched twice:

``` r

Validator(
  data = list(x = 1L),
  schema = list(
    list(type = "integer"), # matched positionally
    x = list(type = "character") # matched by name to same element
  )
)@errors
#> [[1]]
#> [[1]]$type
#> NULL
#> 
#> 
#> $x
#> $x$type
#> [1] "Is not type `character`."
```

It is strongly encouraged to use fully named schemas/data unless you are
certain about their structure.

### Using the Schema class

The `Schema` class takes the nested list and re-orders it, transforms
certain rules from strings to functions where necessary, then validates
the schema.

#### Schema re-ordering

Rules are applied in four separate passes according to their category:
‘control’, ‘transform’, ‘validate’ and ‘finalize’. The ‘finalize’ pass
behaves slightly differently to the others, in that rules in this group
are only applied if there are no errors from the previous passes in that
schema node.

For each category, the `Schema` reorders the list upon ingest according
to the corresponding orders of the name properties in the `Registry` (by
default `Schema` uses a default, uncustomised `Registry` if one is not
provided):

``` r

r <- Registry()
r@control_rules
#> [1] "required" "default"
r@transform_rules
#> [1] "coerce" "apply"
r@validate_rules
#>  [1] "type"           "inherits"       "allowed"        "forbidden"     
#>  [5] "unique"         "positive"       "negative"       "finite"        
#>  [9] "allow_na"       "sorted"         "min_val"        "max_val"       
#> [13] "min_length"     "max_length"     "min_nrow"       "max_nrow"      
#> [17] "min_nchar"      "max_nchar"      "nzchar"         "regex"         
#> [21] "levels"         "ordered_levels" "dependency"     "dependencies"  
#> [25] "predicate"

Schema(
  list(
    min_length = 2L,
    type = "integer",
    default = 10L,
    coerce = "double"
  )
)@schema
#> $default
#> [1] 10
#> 
#> $coerce
#> [1] "double"
#> 
#> $type
#> [1] "integer"
#> 
#> $min_length
#> [1] 2
```

The order of the rules within each of the `Registry` properties can be
edited to specify a different order, which can then be fed to the
`Schema`:

``` r

r <- Registry()
r@validate_rules <- c("min_length", r@validate_rules[!grepl("min_length", r@validate_rules)])

Schema(
  schema = list(
    min_length = 2L,
    type = "integer",
    default = 10L,
    coerce = "double"
  ),
  registry = r
)@schema
#> $default
#> [1] 10
#> 
#> $coerce
#> [1] "double"
#> 
#> $min_length
#> [1] 2
#> 
#> $type
#> [1] "integer"
```

For more information about the builtin rules and how they operate, or
how to add custom rules to a `Registry`, see the [builtin rules
vignette](https://lj-jenkins.github.io/fluffy/articles/validation-rules.md)
and the [custom rules
vignette](https://lj-jenkins.github.io/fluffy/articles/custom-rules.md).

#### String to function conversion

Certain rules can be given character strings as an input which are
turned into functions during schema validation. The rules that this
apply to can be found in the `Registry`, along with the function that
does the conversion. Both can be edited.

BEWARE: No check is made on the content of the string, so use the
builtin converter with extreme care for user inputs - it is vulnerable
to code injection. This functionality can be removed by simply making
the `@str_to_fn_rules` property an empty character.

``` r

r <- Registry()
r@str_to_fn_rules
#> [1] "apply"      "apply_last" "predicate"

r@str_to_fn_converter
#> function (str) 
#> {
#>     tryCatch(as.function(eval(str2lang(str))), error = function(cnd) {
#>         NULL
#>     })
#> }
#> <bytecode: 0x560517b99560>
#> <environment: namespace:fluffy>

Schema(
  list(predicate = "function(x) x > 10")
)@schema
#> $predicate
#> function (x) 
#> x > 10
#> <environment: 0x560519182a28>
```

### Schema validation and errors

`Schema` objects validate their list input and store an `@errors`
property that highlights validation errors.

The `@errors` list mirrors the structure of the input schema list with
`NULL` elements where the schema is valid and error messages where the
schema is invalid:

``` r

Schema(
  list(
    type = "not a type",
    list(apply = 1),
    list(type = "character"),
    list(a = list(min_length = function(x) x + 1))
  )
)@errors
#> $type
#> [1] "`not a type` not found in allowed types."
#> 
#> [[2]]
#> [[2]]$apply
#> [1] "Must be a function (or valid string)."
#> 
#> 
#> [[3]]
#> [[3]]$type
#> NULL
#> 
#> 
#> [[4]]
#> [[4]]$a
#> [[4]]$a$min_length
#> [1] "Must be a single, positive, non-NA integerish value."
```

This can be used by the user in their own error messages, or if the
`@error` property is set to `TRUE`, an error will occur with the
non-null elements forming the message (with possible truncation
according to the `@error_print_opts`), see below.

Note: the error messages from the `Validator` instead show the locations
of the data that failed validation, see the ‘Errors’ section of ‘Data
validation’ below.

#### Schema nodes

For each schema node `Schema` validates that:

- There are no duplicate names.
- All leaf elements are named.
- Leaf elements are named with recognised rules.

``` r

Schema(
  list(
    x = list(type = "character"),
    x = list(type = "integer"),
    list("character"),
    list(my_rule = 1L)
  ),
  error = TRUE
)
#> Error:
#> ! <fluffy::Schema> object is invalid:
#> - Schema validation failed with the following errors:
#> ├─ x: Names must be unique at the same depth.
#> ├─ x: Names must be unique at the same depth.
#> ├─ [[3]]
#> │ └─ [[1]]: Schema leafs must be named with rules.
#> └─ [[4]]
#>   └─ my_rule: Unknown rule: `my_rule`.
```

#### Rule validation

Each rule has an associated schema validation rule that checks the value
given. For example, the ‘predicate’ rule checks that given values are
either strings or functions. The ‘dependency’ rule checks that given
values are either a character vector (names), a numeric integerish
vector, or a non-nested list containing a mix of the two.

``` r

Schema(
  list(
    predicate = 1L,
    dependency = 1.5
  ),
  error = TRUE
)
#> Error:
#> ! <fluffy::Schema> object is invalid:
#> - Schema validation failed with the following errors:
#> ├─ dependency: Indices must be positive integers.
#> └─ predicate: Must be a function (or valid string).
```

#### Cross rule validation

There are also cross rules that check if the values of multiple rules
clash (if the individual rule components are themselves valid). For
example the ‘min_val_larger_than_max_val’ rule does what it says on the
tin:

``` r

Schema(
  list(
    min_val = 5,
    max_val = 1
  ),
  error = TRUE
)
#> Error:
#> ! <fluffy::Schema> object is invalid:
#> - Schema validation failed with the following errors:
#> ├─ min_val: `min_val` must be smaller than `max_val`.
#> └─ max_val: `min_val` must be smaller than `max_val`.
```

### Data validation

Data validation in fluffy is undertaken with the `Validator` class,
which ingests a `Schema` and applies the rules within to the input data.

### Validation process

`Validator` walks through the `Schema` list object, matching data
elements by name or position and applying the rule-based behaviour.

#### Order of evaluation

The validation walk sequences along each schema node and recurses into
list elements - following this basic pattern:

``` r

recursive_walk <- function(lst) {
  for (i in seq_along(lst)) {
    if (!is.list(lst[[i]])) {
      # do rule...
    } else {
      # recurse into list node...
      lst[[i]] <- recursive_walk(lst[[i]])
    }
  }
  lst
}
```

This has implications if you want to access transformed data, so it is
important to consider when designing schemas (see below).

#### Referencing transformed elements

fluffy validation can access transformed data elements on the fly, so
any rules that use `.data` to access other data nodes will be accessing
the data state at that point of the schema walk, rather than the
original state of the data. See the following example:

``` r

s <- Schema(
  list(
    list(
      apply = "function(x, .data, ...) if (.data[[2]] == 1) x + 1"
    ),
    list(
      apply = "function(x, .data, ...) if (.data[[2]] == 0) x + 1"
    ),
    list(
      apply = "function(x, .data, ...) if (.data[[2]] == 1) x + 2"
    ),
    list(
      apply = "function(x, .data, ...) if (.data[[3]] == 2) x + 3"
    )
  )
)

Validator(c(0, 0, 0, 0), s)@data
#> [1] 0 1 2 3
```

The first element remains `0` as `.data[[2]]` had not been transformed
yet, whilst the third and fourth elements both change as the `.data`
elements they referenced had been transformed by the time of their
evaluation.

#### Errors

`Validator` objects also store an `@errors` property that highlights
data validation errors. Like with `Schema`, this property also mirrors
the structure of the input schema list with `NULL` elements where the
schema is valid and error messages where the schema is invalid.

``` r

Validator(
  data = list(a = 1, b = 2),
  schema = list(
    type = "double",
    a = list(type = "character"),
    list(type = "array")
  )
)@errors
#> $type
#> [1] "Is not type `double`."
#> 
#> $a
#> $a$type
#> [1] "Is not type `character`."
#> 
#> 
#> [[3]]
#> [[3]]$type
#> [1] "Is not type `array`."
```

However, when `@error` is set to `TRUE` in the `Validator`, instead of
the schema paths being shown, instead they are converted to the matched
data positions. See the following example:

``` r

Validator(
  data = list(a = 1, b = 2),
  schema = list(
    type = "double",
    a = list(type = "character"),
    list(type = "array")
  ),
  error = TRUE
)
#> Error:
#> ! <fluffy::Validator> object is invalid:
#> - Data validation failed with the following errors:
#> ├─ type: Is not type `double`.
#> ├─ a
#> │ └─ type: Is not type `character`.
#> └─ [[2]]
#>   └─ type: Is not type `array`.
```

Hence, the message about ‘array’ shows for element `[[2]]` as that was
the data element it was matched to, as rule elements in the node are
removed before positional matching.

`Validator` short-circuits if the input `Schema` is invalid:

``` r

v <- Validator(1L, list(type = "not a type"))
v@errors
#> $valid_schema
#> [1] FALSE
v@Schema@errors
#> $type
#> [1] "`not a type` not found in allowed types."

Validator(1L, list(type = "not a type"), error = TRUE)
#> Error:
#> ! <fluffy::Validator> object is invalid:
#> - Schema validation failed with the following errors:
#> └─ type: `not a type` not found in allowed types.
```

#### Validating data from different sources

Putting it all together, you can flexibly validate data in R from a
myriad of different sources.

YAML -\> list -\> fluffy.

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
```

JSON -\> list -\> fluffy.

``` r

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
```

SPSS, SAV, Excel, etc. -\> data.frame -\> fluffy.

``` r

# rectangular data, from `readr` readme
# works for any data.frame data, e.g., sav, dta, xls, xlsx, csv, tsv, etc.
rect_schema <- list(
  type = "data.frame",
  chicken = list(type = "character", nzchar = TRUE),
  sex = list(coerce = "factor", levels = c("rooster", "hen")),
  eggs_laid = list(type = "integer", positive = TRUE),
  motto = list(type = "character", nzchar = TRUE)
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

fluffy can validate numerous kinds of non-empty R objects, with data
elements able to be validated if they can accessed with `[[`, for
example:

``` r

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
