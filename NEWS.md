# fluffy (development version)

## New Features

* New `length` rule added to the `Registry`. This rule checks that the length of a data field is exactly equal to the value specified by the `length` schema field. This removes the need to specify both a `min_length` and `max_length` with the same value when enforcing an exact length. 

* New `length_and_min_length` and `length_and_max_length` cross rules added to the `Registry`. These rules check that the `min_length` and `max_length` rules are not specified when a `length` rule is present.

* The `coerce` rule now accepts functions with multiple arguments when passed directly to a `Schema` or `Validator`, allowing base `as.*()` functions to be used as `coerce` rules in schema definitions. However, only the field value is passed to the function; any additional arguments are ignored. Functions with multiple arguments still cannot be added to the `Registry@coerce_map`, as `add_coerce_rule()` enforces a strict one-argument function signature.

## Bug fixes

* Fixed the `allowed_type_mismatch` and `forbidden_type_mismatch` cross rules so that they use the `Registry@type_map` to obtain the function used for type checking when `type` is a string, and use the supplied function directly when `type` is a function. Previously, function-valued `type` fields caused an error, while character-valued `type` fields could result in incorrect type checking because the class of the `allowed`/`forbidden` field was compared directly with the `type` field. This could produce false positives, such as an integer `allowed`/`forbidden` field being flagged as a type mismatch when `type` was "numeric".

* Fixed incorrect argument-count checking for the `type`, `predicate`, and `apply` rules.

# fluffy 1.0.0

* Initial CRAN submission.
