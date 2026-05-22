# Create a Registry Object

An S7 class that defines rules for validating data against a
[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md).

## Usage

``` r
Registry()

is.Registry(x)
```

## Arguments

- x:

  object to be tested.

## Value

An S7 `Registry` object with the following properties:

- `rule_names`:

  All rule names, in order of evaluation. Derived from
  `control`/`transform`/`validate` rules with `apply_last` added to the
  end.

- 'control_rules:

  Rules that influence the control flow. These will be applied in the
  first pass when validating data.

- 'transform_rules':

  Rules that transform data. These will be applied in the second pass
  when validating data.

- 'validate_rules':

  Rules that validate data. These will be applied in the penultimate
  pass when validating.

- 'finalize_rules':

  Rules that finalize validation. These will be applied in the last pass
  when validating, after all other rules have been applied. These rules
  will only apply if no previous rules for that node have failed.

- `str_to_fn_rules`:

  Schema rules that are allowed to have string or function values, with
  string values being converted to functions automatically during schema
  validation.

- `str_to_fn_converter`:

  A function that converts string values to functions for the
  `str_to_fn_rules`.

- `type_names`:

  A character vector of allowed type names, derived from the keys of the
  `type_map` environment.

- `type_map`:

  An environment mapping type names to type definition functions.

- `coerce_names`:

  A character vector of allowed coercion rule names, derived from the
  keys of the `coerce_map` environment.

- `coerce_map`:

  An environment mapping type names to coercion functions.

- `rule_names`:

  A character vector of all (non-cross) rule names.

- `schema_rules`:

  An environment containing the schema rule functions.

- `cross_rule_names`:

  A character vector of allowed schema cross rule names, derived from
  the keys of the `cross_rules` environment.

- `cross_rules`:

  An environment containing the schema cross rule functions (rules that
  check relationships between multiple schema rule values).

- `validator_rules`:

  An environment containing the validator rule functions.

## Details

The `Registry` class serves as a central repository for all the rules
used in schema and data validation for `fluffy` based workflows. It
includes builtin rules for common validation tasks and allows for the
addition of custom rules.

Registry objects are automatically created in `Schema` objects (which
are passed to `Validator` objects), and rules can be added to the
registry directly within those objects by using the rule-adding generic
functions. It is therefore not necessary to create a `Registry` object
separately if one does not wish.

However, `Schema` and `Validator` objects are automatically re-validated
when rules are added, so for the addition of many new rules, it is
beneficial to create a `Registry` object, add all the rules to it, and
then pass it to the other classes.

For full details see the helper function
[`show_builtins()`](https://lj-jenkins.github.io/fluffy/reference/show_builtins.md)
or the [rules
vignette](https://lj-jenkins.github.io/fluffy/doc/validation-rules.md).

## See also

[Schema](https://lj-jenkins.github.io/fluffy/reference/Schema.md) and
[Validator](https://lj-jenkins.github.io/fluffy/reference/Validator.md)
constructors.
[add_rule](https://lj-jenkins.github.io/fluffy/reference/add_rule.md)
for adding rules to a registry.

## Examples

``` r
r <- Registry()
s <- Schema(list(type = "integer"), registry = r)

is.Registry(r)
#> [1] TRUE
```
