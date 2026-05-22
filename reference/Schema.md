# Create a Schema Object

An S7 class that defines and validates a schema for the future
validation of R objects against it, using a
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md).

## Usage

``` r
Schema(schema, registry = Registry(), error = FALSE, ...)

is.Schema(x)
```

## Arguments

- schema:

  non-empty list defining the schema. Each leaf element to be validated
  must be named with rules that are registered in the schema rule
  registry (see
  [Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
  and
  [add_rule](https://lj-jenkins.github.io/fluffy/reference/add_rule.md)).
  Named elements must be unique at a given level of the list.

- registry:

  object of class
  [Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
  containing the schema and validator rules to use for schema
  validation. If not provided, the default registry with builtin rules
  will be used.

- error:

  single logical value. If `TRUE`, the constructor throws an error when
  the schema is invalid.

- ...:

  named arguments passed to internal error message formatting functions:
  `max_depth`, `max_width`, `max_rows`, and `UTF8` which control the
  truncation and printing of the error message when the schema
  validation fails. `max_` arguments accept integerish scalar values,
  and `UTF8` accepts a single logical value. Unnamed arguments or names
  other than the above will be ignored. Stored in the `error_print_opts`
  property.

- x:

  object to be tested.

## Value

An S7 `Schema` object with the following properties:

- `schema`:

  The input schema list, with strings converted to functions where
  applicable.

- `errors`:

  (Read only) A list mirroring the schema structure, with `NULL` for
  valid rules and character error messages for invalid ones.

- `Registry`:

  An object of class
  [Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
  containing the schema and validator rules used for validation.

- `.schema_cache`:

  (Internal, read only) An environment for caching schema validation
  results.

- `error`:

  Boolean; whether to error on invalid schemas.

- `error_print_opts`:

  A list of options for error message printing when `error = TRUE`.
  Options are `max_depth`, `max_width`, `max_rows`, and `UTF8`, which
  control the truncation and printing of the error message when
  validation fails. These options are also used by the Validator class
  that ingests the Schema.

- `valid`:

  (Read only) Boolean; `TRUE` if schema is valid, `FALSE` otherwise.

## Details

Each element of the input list represents a field with named rules
(e.g., `'type'`, `'required'`, `'min_val'`) that are checked against the
schema rule registry. Cross rules (e.g.,
`'min_val_larger_than_max_val'`, where `'min_val'` \< `'max_val'`) are
also evaluated when all constituent rules pass individually.

The schema is re-evaluated upon any change to the schema properties,
with the `@valid` property indicates whether the schema is valid (all
rules pass) or invalid (any rule fails). If invalid, when passed to a
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md)
the validation will fail immediately.

See the
[Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
class for details on the available rules and how to customise them. See
the
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md)
class for details on how to use a `Schema` to validate data.

For full details see the [validating data
vignette](https://lj-jenkins.github.io/fluffy/doc/validating-data.md).

## See also

[add_rule](https://lj-jenkins.github.io/fluffy/reference/add_rule.md)
for adding rules to a registry.

## Examples

``` r
# A valid schema
s <- Schema(list(
  name = list(type = "character", required = TRUE),
  age = list(type = "numeric", min_val = 0, max_val = 150)
))
s@valid # TRUE
#> [1] TRUE

# An invalid schema (type must be a string)
s <- Schema(list(name = list(type = 123)))
s@valid # FALSE
#> [1] FALSE
s@errors # error message
#> $name
#> $name$type
#> [1] "Must be a function or a string."
#> 
#> 

# To error on invalid schema
try(Schema(list(name = list(type = 123)), error = TRUE))
#> Error : <fluffy::Schema> object is invalid:
#> - Schema validation failed with the following errors:
#> └─ name
#>   └─ type: Must be a function or a string.
```
