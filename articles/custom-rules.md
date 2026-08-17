# Adding Custom Rules

``` r

library(fluffy)
```

Custom rules can be used to validate schemas and data in ways that the
[builtin
rules](https://lj-jenkins.github.io/fluffy/articles/validation-rules.md)
don’t cover. Rules are stored in `Registry` objects and thus custom
rules can be added to any instantiated fluffy class objects: `Registry`,
`Schema` or `Validator`.

Rules added to fluffy objects can be used to flexibly validate and
transform data, but they must follow the same structure as the builtin
rules. This structure is what allows the `Schema` and `Validator` to
apply them correctly. The following sections cover the structure of
custom rules and how to add them to fluffy objects.

### Custom rules

To add custom rules, `add_rule` (and variants) are used. Each new rule
requires a unique name, a transformation/validation function for the
data, a validation function for the schema value, and a rule type.

``` r

add_rule(
  obj,
  name,
  validator_fn,
  schema_fn = NULL,
  rule_type = c("validate", "control", "transform", "finalize")
)
```

See later sections for adding new type/coerce rules and cross rules.

#### Keywords

In fluffy rules, `.self`, `.schema` and `.data` are reserved keywords
that refer to the fluffy object the rule is being applied to and the
schema/data being validated, respectively.

`.self` is the fluffy object the rule is being applied to, so for schema
validation it is the `Schema` object and for data
transformation/validation it is the `Validator` object. This allows the
rule functions to access properties of the relevant fluffy object, such
as the `Registry` of rules.

`.schema` is used in the schema validation function to refer to the full
schema being validated, and `.data` is used in the data
transformation/validation function to refer to the full data being
validated. This allows the rule functions to access other fields in the
schema/data when operating on a particular field.

#### Rule function arguments

Schema validation functions are passed the schema field as a positional
argument, and then `.schema` and `.self` as named arguments. Therefore,
schema validation functions can be defined in these ways:

|  |  |  |
|:---|:---|:---|
| `function(field, ...)` | `function(field, .schema ...)` or `function(field, .self ...)` | `function(field, .schema, .self)` |

Data transformation/validation functions are passed the data field and
the schema field as positional arguments, respectively, and then `.data`
and `.self` as named arguments. Therefore, data
transformation/validation functions can be defined in these ways:

|  |  |  |
|:---|:---|:---|
| `function(field, schema_field, ...)` | `function(field, schema_field, .data ...)` or `function(field, schema_field, .self ...)` | `function(field, schema_field, .data, .self)` |

#### Schema validation function

The schema validation function checks the validity of the schema field
for the rule. It should return `NULL` if the schema field is valid, and
a character string (to be used as an error message) if it is invalid.

The following would be an example of a schema validation function that
checks that the schema field is a length 1 character:

``` r

schema_validation_fn <- function(field, ...) {
  if (!is.character(field) || length(field) != 1L) {
    "Must be a length 1 character."
  }
}
```

Schema validation is optional. If a function is not provided, the rule
will be added without any schema validation, and any schema value will
be accepted for the rule. In this case, the schema validation function
would simply be an empty function (this is the same as the
implementation of the builtin `default` rule):

``` r

allow_any_schema_fn <- function(field, ...) {}
```

#### Data transformation/validation function

The data transformation/validation function applies the rule to the
data. Unlike the schema validation function, a named list must be
returned, with the following named element(s) determining the behaviour:

``` r

return(list(error = ..., data = ..., continue = ...))
```

- `error`: character string of the error message and if returned,
  signals that the data is invalid. If not returned or `NULL`, the data
  is considered valid for that rule.
- `data`: the transformed data for the field. If not returned or `NULL`,
  the original data remains. If both `error` and `data` are returned,
  the data will be transformed but still be considered invalid.
- `continue`: a boolean to indicate whether to continue validating the
  rest of the schema rules in the node. This is used in the builtin in
  control rules that determine whether validation should proceed or not,
  but can be used in any rule. If not returned or `NULL`, it defaults to
  `TRUE`.

The following would be an example of a data transformation/validation
function that checks that the data field is a length 1 character,
pasting the schema field onto it if so, and erroring if not:

``` r

data_validation_fn <- function(data_field, schema_field, ...) {
  if (!is.character(data_field) || length(data_field) != 1L) {
    list(error = "Data must be a length 1 character.")
  } else {
    list(data = paste0(data_field, schema_field))
  }
}
```

An example of a builtin rule that alters control flow with `continue` is
the `required` rule. See the following example where the other rules in
the schema node do not error despite there being no data for the node,
as `required` returns `continue = FALSE` and thus stops validation of
the rest of the schema rules for that node:

``` r

Validator(
  data = list(a = 1),
  schema = list(
    b = list(
      required = FALSE,
      type = "character",
      min_length = 5L
    )
  )
)@valid
#> [1] TRUE
```

#### Rule type

The rule type determines when the rule is applied when the `Validator`
is run. Four separate passes are undertaken during data validation, with
rules being applied depending on their specified type in the associated
`Registry`:

``` r

r <- Registry()
r@control_rules # first pass
#> [1] "required" "default"
r@transform_rules # second pass
#> [1] "coerce" "apply"
r@validate_rules # third pass
#>  [1] "type"           "inherits"       "allowed"        "forbidden"     
#>  [5] "unique"         "positive"       "negative"       "finite"        
#>  [9] "allow_na"       "sorted"         "min_val"        "max_val"       
#> [13] "length"         "min_length"     "max_length"     "min_nrow"      
#> [17] "max_nrow"       "min_nchar"      "max_nchar"      "nzchar"        
#> [21] "regex"          "levels"         "ordered_levels" "dependency"    
#> [25] "dependencies"   "predicate"
r@finalize_rules # fourth pass
#> [1] "coerce_last" "apply_last"
```

The `rule_type` given must match one of these categories, and determines
if the custom rule is applied in the first, second, third, or fourth
pass. Custom rules do not need to strictly follow these category
definitions, but it is recommended.

The order in which rules within categories are run is determined by the
individual order of the associated `Registry` property, which can be
edited.

The ‘finalize’ pass behaves slightly differently to the others, in that
rules in this group are only applied if there are no errors from the
previous passes in that schema node.

### Custom type/coerce rules

`type` and `coerce` rules can be added more simply with `add_type_rule`
and `add_coerce_rule`. They expand the builtin `type` and `coerce`
rules, so the custom type/coerce rules will be applied alongside the
builtin ones.

These functions take the fluffy object, the name of the new schema
type/coerce value, and a function that takes one argument, in the same
vein as base R `is.*()` and `as.*()` functions. Note that the function
must take a single argument, as the `Registry` will check the function
signature and throw an error if it does not match. Functions that take
multiple arguments can be used when passed directly to a `Schema` or
`Validator`, but the additional arguments will be ignored.

``` r

add_type_rule(obj, type_name, type_fn)

add_coerce_rule(obj, coerce_name, coerce_fn)
```

``` r

s <- Schema(list(type = "my_type"))
s@valid
#> [1] FALSE
s@errors
#> $type
#> [1] "`my_type` not found in allowed types."

s <- add_type_rule(s, "my_type", function(x) isTRUE(class(x) == "my_type"))
s@valid
#> [1] TRUE

v <- Validator(1L, s)
v@valid
#> [1] FALSE
v@errors
#> $type
#> [1] "Is not type `my_type`."

s@schema <- list(coerce = "my_type", type = "my_type")
s@valid
#> [1] FALSE
s@errors
#> $coerce
#> [1] "`my_type` not found in allowed types."
#> 
#> $type
#> NULL

s <- add_coerce_rule(s, "my_type", function(x) structure(x, class = "my_type"))
s@valid
#> [1] TRUE

v <- Validator(1L, s)
v@valid
#> [1] TRUE
v@data
#> [1] 1
#> attr(,"class")
#> [1] "my_type"
```

### Custom cross rules

Cross rules operate on schema nodes that contain specified rules,
comparing the values or two or more of those rules to check for clashes.
`add_cross_rule` takes the fluffy object, the name of the new cross
rule, the name of the rules to operate on, and a function that checks
the schema values and returns `NULL` if valid or a character string
error message if invalid.

``` r

add_cross_rule(obj, name, rule_names, cross_fn)
```

The cross rule function takes the same arguments as the schema
validation function. However, the positional argument now represents a
schema node, which is a list, as opposed to a single schema field. To
implement the required behaviour, access the rule elements by name:

``` r

s <- Schema(list(min_length = 5, min_val = 5))

s <- add_cross_rule(
  s,
  name = "min_length_cannot_equal_min_val",
  rule_names = c("min_length", "min_val"),
  cross_fn = function(node, ...) {
    if (node$min_length >= node$min_val) {
      "min_length must be less than min_val."
    }
  }
)
s@valid
#> [1] FALSE
s@errors
#> $min_val
#> [1] "min_length must be less than min_val."
#> 
#> $min_length
#> [1] "min_length must be less than min_val."
```

### Examples

Example validate rule for checking a specific attribute matches the
schema.

``` r

mySchema <- Schema(list(check_my_attr = 1L))
mySchema@errors
#> $check_my_attr
#> [1] "Unknown rule: `check_my_attr`."

mySchema <- add_rule(
  obj = mySchema,
  name = "check_my_attr",
  validator_fn = function(data_field, schema_field, ...) {
    if (attr(data_field, "my_attr") != schema_field) {
      list(error = "Data doesn't match schema 'my_attr'.")
    }
  },
  schema_fn = function(schema_field, ...) {
    if (!is.character(schema_field) || length(schema_field) != 1L) {
      "Must be length 1 character"
    }
  },
  rule_type = "validate"
)

mySchema@errors
#> $check_my_attr
#> [1] "Must be length 1 character"
mySchema@schema$check_my_attr <- "Hi"

Validator(structure(1L, my_attr = "Hi"), mySchema)@valid
#> [1] TRUE
Validator(structure(1L, my_attr = 1L), mySchema, error = TRUE)
#> Error:
#> ! <fluffy::Validator> object is invalid:
#> - Data validation failed with the following errors:
#> └─ check_my_attr: Data doesn't match schema 'my_attr'.
```

Example transform rule which doubles the data value if it is 5.

``` r

s <- Schema(list(double_if_five_else_error = TRUE))
s@valid
#> [1] FALSE

s <- add_rule(
  s,
  name = "double_if_five_else_error",
  validator_fn = function(field, schema_field, ...) {
    if (schema_field) {
      if (field != 5) {
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
```
