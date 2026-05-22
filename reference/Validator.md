# Create a Validator Object

An S7 class that validates R objects against a
[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md). The
`Validator` takes a `schema` (an object of class `Schema` or a `list`
that can be converted to a `Schema`) and validates input `data` against
the rules defined in the `schema`.

## Usage

``` r
Validator(data, schema, error = FALSE)

is.Validator(x)
```

## Arguments

- data:

  Any R object. If using a nested schema, the object must have the `[[`
  method implemented.

- schema:

  [Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md)
  object or a non-empty `list` defining the schema. See the
  [Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md)
  constructor for details on the schema structure and rules.

- error:

  single logical value. If `TRUE`, an error is thrown when the
  validation fails.

- x:

  object to be tested.

## Value

An S7 `Validator` object with the following properties:

- `data`:

  The validated input data, with any changes that were made during
  validation.

- `Schema`:

  An object of class
  [Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md).
  This also contains the
  [Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
  used for validation, which can be accessed via `@Schema@Registry`.

- `errors`:

  (Read only) A list mirroring the data or schema structure (depending
  on `match_schema` and `match_data`), with `NULL` for valid fields and
  character error messages for invalid ones. Extra fields showing
  missigness may be present when both `match_schema` and `match_data`
  are `TRUE`.

- `.validator_cache`:

  (Internal, read only) An environment for caching validation results.

- `error`:

  Boolean; whether to error upon failure (invalid data or schema).

- `valid`:

  (Read only) Boolean; `TRUE` if schema is valid and all data validation
  rules pass, `FALSE` otherwise (invalid data or schema).

## Details

The validation process checks each field in the `schema` against the
data, creating an errors list that mirrors the schema structure with
`NULL` for valid fields and character error messages for invalid fields.

These validation results are stored in the `@errors` property, and the
overall validity is indicated by the `@valid` property. If the `@error`
property/argument is set to `TRUE`, any validation failure will result
in an error being thrown. To customise the truncation of error messages,
see the `@Schema@error_print_opts` property.

The `Validator` is re-evaluated upon any change to the object
properties. If an invalid schema is provided, the validation will fail
immediately with the validation error indicating that the schema is
invalid. To see the errors in the schema validation, see the
`Validator@Schema@errors` property.

See the
[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md) class
for details on the schema class structure, and the
[Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
class for details on the available validation rules.

For full details see the [validating data
vignette](https://lj-jenkins.github.io/fluffy/doc/validating-data.md).

## See also

[add_rule](https://lj-jenkins.github.io/fluffy/reference/add_rule.md)
for adding rules to a registry.

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
```
