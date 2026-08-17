# Schema

Create a `Schema` object that defines and validates a schema for the
future validation of R objects using a `Validator`.

## Usage

``` r
Schema(schema, registry = Registry(), error = FALSE, ...)

is.Schema(x)
```

## Arguments

- schema:

  Non-empty list defining the schema. Each leaf element to be validated
  must be named with rules that are registered in the schema rule
  registry (see
  [Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
  and
  [add_rule](https://lj-jenkins.github.io/fluffy/reference/add_rule.md)).
  Named elements must be unique at a given level of the list.

- registry:

  Object of class
  [Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
  containing the schema and validator rules to use for schema
  validation.

- error:

  Single logical value. If `TRUE`, the constructor throws an error when
  the schema is invalid.

- ...:

  Named arguments passed to internal error message formatting:
  `max_depth`, `max_width`, `max_rows`, and `UTF8` which control the
  truncation and printing of the error message when the schema
  validation fails. `max_*` arguments accept integerish scalar values,
  and `UTF8` accepts a single logical value. Unnamed arguments or named
  arguments other than the above will be ignored.

- x:

  Object to be tested.

## Value

A `Schema` S7 object.

## Details

The `Schema` class defines the structure and rules for validating data
using a `Validator`. It ingests the input schema list and then reorders
and validates the schema according to the
[Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md).
The resulting `@schema` property defines the validation behaviour and
data matching.

Each element of the input list represents a field with named rules
(e.g., `'type'`, `'required'`, `'min_val'`) that are checked against the
schema rule registry. Cross rules (e.g.,
`'min_val_larger_than_max_val'`, where `'min_val'` \< `'max_val'`) are
also evaluated when all constituent rules pass individually. See the
[Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
class for details.

The schema is re-evaluated upon any change to the schema properties,
with the `@valid` property indicating whether the schema is valid (all
rules pass) or invalid (any rule fails). If invalid, when passed to a
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md)
the validation will fail immediately.

For full details see the vignettes on [builtin
rules](https://lj-jenkins.github.io/fluffy/doc/validation-rules.md),
[data
validation](https://lj-jenkins.github.io/fluffy/doc/validating-data.md),
and [adding custom
rules](https://lj-jenkins.github.io/fluffy/doc/custom-rules.md).

## Note

The `coerce` rule may use functions with multiple arguments when passed
directly to a `Schema` or `Validator`. Only the field value is passed to
the function, and any additional arguments are ignored. Thus,
`as.numeric` is valid as a `coerce` rule in a schema definition, but
cannot be added to a `Registry`, which enforces a strict one-argument
function signature.

## See also

[add_rule](https://lj-jenkins.github.io/fluffy/reference/add_rule.md)
for adding rules to a `Registry`.
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md)
for validating data against a `Schema`.

## Additional properties

- `@schema`:

  The input schema list, with nodes reordered to match the order of the
  rules in the registry, and any strings converted to functions where
  applicable.

- `@errors`:

  (Read-only) A list mirroring the schema structure, with `NULL` for
  valid rules and character error messages for invalid rules.

- `@Registry`:

  An object of class
  [Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
  containing the schema and validator rules used for validation.

- `@.schema_cache`:

  (Read-only) An environment for caching schema validation results. Used
  to avoid redundant validation.

- `@error`:

  Boolean; whether to error on invalid schemas.

- `@error_print_opts`:

  A list of options for error message printing when `error = TRUE`.
  These options are also used by the `Validator` class that ingests the
  `Schema.` Defaults are

  - `max_depth = 10L`

  - `max_width = getOption("width")`

  - `max_rows = 30L`

  - `UTF8 = l10n_info()[["UTF-8"]]`

- `@valid`:

  (Read-only) Boolean; `TRUE` if schema is valid, `FALSE` otherwise.

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
