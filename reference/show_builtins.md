# Show fluffy builtin rules

Helper to show the builtin rules in a Registry, and their behaviour.

## Usage

``` r
show_builtins(rules = c("all", "validation", "cross"))
```

## Arguments

- rules:

  Which builtin rules to show. `"validation"` for the standard
  schema/data validation rules, `"cross"` for the cross rules that check
  for consistency between rules, or `"all"` to show both.

## Value

List of data.fames if `rules = "all"`, otherwise a single data.frame,
with information on the builtin rules for the rule type specified. The
data.frame(s) have an attached class `fluffy_rule_info`.

## Note

The `fluffy_rule_info` class has a custom print method that formats the
data.frame(s) in a more readable way. The output of this function is
only intended to be used for display/interactive purposes.

## See also

[Registry](https://lj-jenkins.github.io/fluffy/reference/Registry.md)
and
[add_rule](https://lj-jenkins.github.io/fluffy/reference/add_rule.md).

## Examples

``` r
show_builtins()
#> $validation_rules
#> +--------------+----------------------+----------------------+----------------------+
#> |Rule          |Schema operation      |Data operation        |Control flow          |
#> |--------------|----------------------|----------------------|----------------------|
#> |              |Checks schema valu ...|Checks/transforms  ...|Stops other rules if: |
#> |--------------|----------------------|----------------------|----------------------|
#> |required      |boolean.              |exists.               |FALSE and element  ...|
#> |default       |non-empty.            |exists and inserts ...|default is used.      |
#> |apply         |function or a vali ...|applies function.     |                      |
#> |coerce        |1 arg function or  ...|coerces.              |                      |
#> |type          |1 arg function or  ...|type.                 |                      |
#> |inherits      |character vector.     |inherits from spec ...|                      |
#> |allowed       |non-empty vector.     |only values in all ...|                      |
#> |forbidden     |non-empty vector.     |no values in forbi ...|                      |
#> |unique        |TRUE.                 |no duplicates.        |                      |
#> |positive      |TRUE.                 |is positive (or zero).|                      |
#> |negative      |TRUE.                 |is negative (or zero).|                      |
#> |finite        |TRUE.                 |is finite.            |                      |
#> |allow_na      |TRUE.                 |no NA values.         |                      |
#> |min_val       |finite numeric value. |values at least mi ...|                      |
#> |max_val       |finite numeric value. |values at most max ...|                      |
#> |min_length    |positive integeris ...|length at least mi ...|                      |
#> |max_length    |positive integeris ...|length at most max ...|                      |
#> |min_nrow      |positive integeris ...|nrow at least min_ ...|                      |
#> |max_nrow      |positive integeris ...|nrow at most max_nrow.|                      |
#> |min_nchar     |positive integeris ...|nchar at least min ...|                      |
#> |max_nchar     |positive integeris ...|nchar at most max_ ...|                      |
#> |nzchar        |boolean.              |no empty strings.     |                      |
#> |regex         |string.               |matches regex pattern.|                      |
#> |labelled      |boolean.              |is labelled (has l ...|                      |
#> |levels        |character vector.     |has levels matchin ...|                      |
#> |ordered_levels|character vector.     |has levels matchin ...|                      |
#> |dependency    |character vector,  ...|dependency field p ...|                      |
#> |dependencies  |list of character  ...|dependency fields  ...|                      |
#> |predicate     |function or a vali ...|satisfies predicat ...|                      |
#> |apply_last    |function or a vali ...|applies function i ...|                      |
#> |coerce_last   |1 arg function or  ...|coerces if no erro ...|                      |
#> +--------------+----------------------+----------------------+----------------------+
#> 
#> $cross_rules
#> +---------------------------------+-----------------------------------------------+
#> |Cross rule                       |Schema operation                               |
#> |---------------------------------|-----------------------------------------------|
#> |                                 |Checks in a schema node that:                  |
#> |---------------------------------|-----------------------------------------------|
#> |dependency_and_dependencies      |dependency and dependencies rules aren't bo ...|
#> |required_and_default             |if required is TRUE that a default value is ...|
#> |positive_and_negative            |positive and negative rules aren't both pre ...|
#> |min_val_larger_than_max_val      |min_val is smaller than max_val.               |
#> |min_length_larger_than_max_length|min_length is smaller than max_length.         |
#> |min_nrow_larger_than_max_nrow    |min_nrow is smaller than max_nrow.             |
#> |min_nchar_larger_than_max_nchar  |min_nchar is smaller than max_nchar.           |
#> |allowed_and_forbidden_overlap    |values in allowed and forbidden do not overlap.|
#> |allowed_type_mismatch            |values in allowed are of the type specified ...|
#> |forbidden_type_mismatch          |values in forbidden are of the type specifi ...|
#> +---------------------------------+-----------------------------------------------+
#> 
```
