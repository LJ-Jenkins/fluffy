# Registry

Create a `Registry` object that defines and stores rules for validating
data against a
[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md).

## Usage

``` r
Registry()

is.Registry(x)
```

## Arguments

- x:

  Object to be tested.

## Value

A `Registry` S7 object.

## Details

The `Registry` class serves as a central repository for all the rules
used in `fluffy` schema and data validation. It is passed to the
[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md) and
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md)
classes, which use the rules stored in the `Registry` to validate
schemas and data, respectively.

To see the available builtin rules, use the helper function
[`show_builtins()`](https://lj-jenkins.github.io/fluffy/reference/show_builtins.md),
which lists all the builtin rules in a `Registry`.

As `Registry` objects are automatically created in the `Schema`
constructor, which is in turn called in the `Validator` constructor, a
`Registry` does not need to be created separately to use `fluffy`'s
validation functionality. Custom rules can also be added to the
`Registry` within a `Schema` or `Validator` object. However, rule
addition will trigger re-validation of the given object, so for the
addition of many new rules, it is beneficial to create a `Registry`
object, add all the rules to it, and then pass it to the other classes.

For full details see the vignettes on [builtin
rules](https://lj-jenkins.github.io/fluffy/doc/validation-rules.md),
[data
validation](https://lj-jenkins.github.io/fluffy/doc/validating-data.md),
and [adding custom
rules](https://lj-jenkins.github.io/fluffy/doc/custom-rules.md).

## See also

[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md) and
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md)
constructors.
[add_rule](https://lj-jenkins.github.io/fluffy/reference/add_rule.md)
for adding rules to a `Registry`.

## Additional properties

- `@rule_names`:

  (Read-only) All rules, in order of evaluation. Derived from the
  combination of the `control`, `transform`, `validate`, and `finalize`
  rules.

- `@control_rules`:

  Rules that influence the control flow. These will be applied in the
  first pass when validating data.

- `@transform_rules`:

  Rules that transform data. These will be applied in the second pass
  when validating data.

- `@validate_rules`:

  Rules that validate data. These will be applied in the penultimate
  pass when validating.

- `@finalize_rules`:

  Rules that finalize validation. These will be applied in the last pass
  when validating, after all other rules have been applied. These rules
  will only apply if no previous rules for that schema node have failed.

- `@str_to_fn_rules`:

  Schema rules that are allowed to have string or function values, with
  string values being converted to functions automatically during schema
  validation.

- `@str_to_fn_converter`:

  Function that converts string values to functions for the
  `@str_to_fn_rules`.

- `@type_names`:

  (Read-only) Allowed type names. Derived from the keys of the
  `@type_map`.

- `@type_map`:

  Environment mapping type names to type definition functions. Can only
  be added to via
  [`add_type_rule()`](https://lj-jenkins.github.io/fluffy/reference/add_rule.md).

- `@coerce_names`:

  (Read-only) Allowed coercion names. Derived from the keys of the
  `@coerce_map`.

- `@coerce_map`:

  Environment mapping coercion names to coercion functions. Can only be
  added to via
  [`add_coerce_rule()`](https://lj-jenkins.github.io/fluffy/reference/add_rule.md).

- `@schema_rules`:

  Environment mapping schema rule names to schema validation functions.
  Can only be added to via
  [`add_rule()`](https://lj-jenkins.github.io/fluffy/reference/add_rule.md).

- `@cross_rule_names`:

  (Read-only) Schema cross rules. Derived from the keys of the
  `@cross_rules` environment.

- `@cross_rules`:

  Environment containing the schema cross rule functions (rules that
  check relationships between multiple schema rule values). Can only be
  added to via
  [`add_cross_rule()`](https://lj-jenkins.github.io/fluffy/reference/add_rule.md).

- `@validator_rules`:

  Environment mapping validator rule names to validator functions. Can
  only be added to via
  [`add_rule()`](https://lj-jenkins.github.io/fluffy/reference/add_rule.md).

## Examples

``` r
r <- Registry()
s <- Schema(list(type = "integer"), registry = r)

is.Registry(r)
#> [1] TRUE
```
