# Add Rules to a Registry

Add validator, schema, (schema) cross, type, or coerce rules to a
[Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md),
[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md), or
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md)
object.

## Usage

``` r
add_rule(
  obj,
  name,
  validator_fn,
  schema_fn = NULL,
  rule_type = c("validate", "control", "transform")
)

add_cross_rule(obj, name, rule_names, cross_fn)

add_type_rule(obj, type_name, type_fn)

add_coerce_rule(obj, coerce_name, coerce_fn)
```

## Arguments

- obj:

  Registry, Schema, or Validator object.

- name:

  string specifying the name of the rule to add. Rule names cannot be
  the same as any existing rule names.

- validator_fn:

  function that validates a data field against a schema field. Every
  validator rule function must return `NULL` or a named list. A `NULL`
  return indicates validation success with no transformed data or
  alteration to the control flow. A named list return can accept the
  following elements:

  - `data`: the (optionally transformed) data value to be reassigned and
    passed to subsequent rules. If not returned, the original data value
    is used.

  - `error`: a string error message if validation fails. If not
    returned, validation is assumed to have succeeded.

  - `continue`: boolean indicating whether to continue validating
    subsequent rules. If not returned, assumed to be `TRUE`.

- schema_fn:

  function to validate a schema field definition. If `NULL`, a default
  function that performs no validation is used. Schema validation
  functions should return `NULL` if the schema field is valid, and a
  string error message if invalid.

- rule_type:

  string specifying the type of rule to add. Must be one of `"control"`,
  `"transform"`, or `"validate"`.

- rule_names:

  character vector specifying the names of the existing schema rules
  that the cross rule will operate over. Must be of length 2 or more,
  and all names must be of existing schema rules in the Registry.

- cross_fn:

  function to validate schema field definitions across multiple schema
  rules. Schema cross functions should return `NULL` if the schema
  fields are valid, and a string error message if invalid.

- type_name, coerce_name:

  string specifying the name of the type/coerce rule value to add.

- type_fn, coerce_fn:

  function to validate/coerce a field value.

## Value

Invisibly returns the input object with the new rule added.

## Details

To be able to correctly pass the required arguments for the data/schema
validations, rule functions must have the following argument semantics:

Note: `field` and `schema_field` are positional, and thus can be called
anything, whilst `.self` (the object itself: `Schema` for schema rules,
`Validator` for validator rules) and `.data` (the full data in the walk)
are named arguments and must be named as such.

type/coerce rule functions:

- `function(field)`

schema/cross rule functions:

- `function(field, ...)`

- `function(field, .self, ...)` \| `function(field, .data, ...)`

- `function(field, .self, .data)`

validator rule functions:

- `function(field, schema_field, ...)`

- `function(field, schema_field, .self, ...)` \|
  `function(field, schema_field, .data, ...)`

- `function(field, schema_field, .self, .data)`

As [Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
uses environments to store rules, which are mutable, add_rule methods
copy the existing environment and the new rule into a new environment,
meaning that the original object is not modified. See examples.

## See also

[Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md),
[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md), and
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md)
classes.

## Examples

``` r
mySchema <- Schema(list(check_my_attr = 1L))
mySchema@errors # doesn't recognise rule
#> $check_my_attr
#> [1] "Unknown rule: `check_my_attr`."
#> 

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

# rule recognised and schema automatically re-validated
mySchema@errors
#> $check_my_attr
#> [1] "Must be length 1 character"
#> 

# validation works with the new rule
mySchema@schema$check_my_attr <- "Hi"
Validator(structure(1L, my_attr = "Hi"), mySchema)@valid # TRUE
#> [1] TRUE

# schema cross rules invalidate when constituent rules are invalid
mySchema <- add_cross_rule(
  obj = mySchema,
  name = "min_and_max_val_add_to_10",
  rule_names = c("min_val", "max_val"),
  cross_fn = function(schema_field, ...) {
    if (schema_field$min_val + schema_field$max_val == 10) {
      "min_val and max_val cannot add to 10."
    }
  }
)
mySchema@schema <- list(min_val = 2, max_val = 8)
mySchema@errors # cross rule error
#> $min_val
#> [1] "min_val and max_val cannot add to 10."
#> 
#> $max_val
#> [1] "min_val and max_val cannot add to 10."
#> 

r <- Registry()
r <- add_type_rule(r, "my_type", function(x) {
  inherits(x, "my_type")
})
s <- Schema(list(type = "my_type"), registry = r)
s@valid # TRUE
#> [1] TRUE
Validator(structure(1, class = "my_type"), s)@valid # TRUE
#> [1] TRUE

r <- add_coerce_rule(r, "my_type", function(x) {
  structure(x, class = c("my_type", class(x)))
})
s <- Schema(list(coerce = "my_type"), registry = r)
v <- Validator(1, s)
class(v@data) # "my_type" "numeric"
#> [1] "my_type" "numeric"

# environments are copied, so original registry is not modified
r <- Registry()
r2 <- add_type_rule(r, "my_type", function(x) x)
identical(r@type_map, r2@type_map) # FALSE
#> [1] FALSE
```
