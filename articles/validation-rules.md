# Builtin Validation Rules

``` r

library(fluffy)
```

fluffy has 30 validation rules and 10 cross rules.

### Validation rules

``` r

Registry()@rule_names
#>  [1] "required"       "default"        "coerce"         "apply"         
#>  [5] "type"           "inherits"       "allowed"        "forbidden"     
#>  [9] "unique"         "positive"       "negative"       "finite"        
#> [13] "allow_na"       "min_val"        "max_val"        "min_length"    
#> [17] "max_length"     "min_nrow"       "max_nrow"       "min_nchar"     
#> [21] "max_nchar"      "nzchar"         "regex"          "labelled"      
#> [25] "levels"         "ordered_levels" "dependency"     "dependencies"  
#> [29] "predicate"      "coerce_last"    "apply_last"
```

The builtin rules are categorised by their type: ‘control’, ‘transform’,
‘validate’ and ‘finalize’. When the `Validator` is run, rules are
applied in four passes according to these categories, with the
‘finalize’ pass being unique in that rules in this group only operate if
all rules in the schema node passed validation without error.

Rules within each category are applied in the order they appear in their
respective `Registry` property.

``` r

r <- Registry()
r@control_rules
#> [1] "required" "default"
r@transform_rules
#> [1] "coerce" "apply"
r@validate_rules
#>  [1] "type"           "inherits"       "allowed"        "forbidden"     
#>  [5] "unique"         "positive"       "negative"       "finite"        
#>  [9] "allow_na"       "min_val"        "max_val"        "min_length"    
#> [13] "max_length"     "min_nrow"       "max_nrow"       "min_nchar"     
#> [17] "max_nchar"      "nzchar"         "regex"          "labelled"      
#> [21] "levels"         "ordered_levels" "dependency"     "dependencies"  
#> [25] "predicate"
r@finalize_rules
#> [1] "coerce_last" "apply_last"
```

Each validation rule has two functions associated with it:

- A function that validates the given schema value.

``` r

Schema(list(type = 1L), error = TRUE)
#> Error:
#> ! <fluffy::Schema> object is invalid:
#> - Schema validation failed with the following errors:
#> └─ type: Must be a function or a string.
```

- A function that uses the schema value to validate data.

``` r

Validator(
  data = 1L,
  schema = list(type = "character"),
  error = TRUE
)
#> Error:
#> ! <fluffy::Validator> object is invalid:
#> - Data validation failed with the following errors:
#> └─ type: Is not type `character`.
```

### Cross rules

Cross rules operate within the `Schema`, checking that the values of two
or more schema rules don’t clash. They are not exhaustive, but apply to
a number of common scenarios.

``` r

Schema(
  list(
    min_length = 5,
    max_length = 1
  ),
  error = TRUE
)
#> Error:
#> ! <fluffy::Schema> object is invalid:
#> - Schema validation failed with the following errors:
#> ├─ min_length: `min_length` must be smaller than `max_length`.
#> └─ max_length: `min_length` must be smaller than `max_length`.
```

### Rule information

#### Validation rules

[TABLE]

#### Cross rules

[TABLE]

##### Note

To quickly see the builtin rules at the terminal, use
[`show_builtins()`](https://lj-jenkins.github.io/fluffy/reference/show_builtins.md).
