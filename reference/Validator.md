# Validator

Create a `Validator` object that validates/transforms R objects using a
[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md).

## Usage

``` r
Validator(data, schema, error = FALSE)

is.Validator(x)
```

## Arguments

- data:

  An R object. If using a nested schema, the object must have a `[[`
  method.

- schema:

  [Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md)
  object or a non-empty `list` defining the schema. See the
  [Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md)
  constructor for details on the schema structure and rules.

- error:

  Single logical value. If `TRUE`, the constructor throws an error when
  validation fails.

- x:

  Object to be tested.

## Value

A `Validator` S7 object.

## Details

The `Validator` class validates/transforms data using a `Schema`. The
process checks each field in the schema against the data, applying the
rules specified. Any data element not present in the schema is ignored.
Validation is done in four passes, according to rule categories in the
[Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md):
`control`, `transform`, `validate`, and `finalize`.

Validation results are stored in the `@errors` property, and the overall
validity is indicated by the `@valid` property. If the `@error`
property/argument is set to `TRUE`, any validation failure will result
in an error being thrown. To customise the truncation of error messages,
see the
[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md)
`@error_print_opts` property. The (possibly) transformed data is stored
in the `@data` property.

The `Validator` is re-evaluated upon any change to the object
properties. If an invalid schema is provided, the validation will fail
immediately with the validation error indicating that the schema is
invalid. To see the errors in the schema validation, see the
`Validator@Schema@errors` property.

For full details see the vignettes on [builtin
rules](https://lj-jenkins.github.io/fluffy/doc/validation-rules.md),
[data
validation](https://lj-jenkins.github.io/fluffy/doc/validating-data.md),
and [adding custom
rules](https://lj-jenkins.github.io/fluffy/doc/custom-rules.md).

## See also

[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md) and
[Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
classes, and
[add_rule](https://lj-jenkins.github.io/fluffy/reference/add_rule.md)
for adding custom rules.

## Additional properties

- `@data`:

  The validated input data, with any changes that were made during
  validation.

- `@Schema`:

  An object of class
  [Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md)
  containing the schema used for validation, as well as the
  [Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md).

- `@errors`:

  (Read-only) A list mirroring the schema structure, with `NULL` for
  rules that pass and character error messages for rules that fail.

- `@.validator_cache`:

  (Read-only) An environment for caching validation results. Used to
  avoid redundant validation.

- `@error`:

  Boolean; whether to error upon failure (invalid data or schema).

- `@valid`:

  (Read-only) Boolean; `TRUE` if the schema is valid and all data
  validation rules pass, `FALSE`otherwise.

## Examples

``` r
v <- Validator(
  data = list(name = "Alice", age = 30),
  schema = list(
    name = list(type = "character", required = TRUE),
    age = list(type = "numeric", min_val = 0, max_val = 150)
  )
)
v@valid # TRUE
#> [1] TRUE

# Schema object can be given directly
s <- Schema(list(a = list(type = "numeric"), b = list(type = "character")))
v <- Validator(list("Hello", 42), s)
v@valid # FALSE
#> [1] FALSE
v@errors
#> $a
#> $a$type
#> [1] "No data for field."
#> 
#> 
#> $b
#> $b$type
#> [1] "No data for field."
#> 
#> 

# To error on invalid schema or data
try(Validator(list("Hello", 42), s, error = TRUE))
#> Error : <fluffy::Validator> object is invalid:
#> - Data validation failed with the following errors:
#> ├─ a
#> │ └─ type: No data for field.
#> └─ b
#>   └─ type: No data for field.

# Invalid schemas show their errors
try(Validator(list(42), list(type = 123), error = TRUE))
#> Error : <fluffy::Validator> object is invalid:
#> - Schema validation failed with the following errors:
#> └─ type: Must be a function or a string.

# Transforms data according to rules
v <- Validator(1, list(coerce = "character"))
v@data # "1"
#> [1] "1"
```
