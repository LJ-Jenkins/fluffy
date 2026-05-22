# Schema error messages reflect schema structure after reordering

    Code
      Schema(list(type = "nope", min_length = "nope", a = list(type = "nope"), b = list(
        min_length = "nope", max_val = "nope"), x = list(type = "nope", positive = "nope"),
      list(type = "nope"), a = list(type = "nope"), min_length = "nope", list(type = "nope")),
      error = TRUE)
    Condition
      Error:
      ! <fluffy::Schema> object is invalid:
      - Schema validation failed with the following errors:
      ├─ type: `nope` not found in allowed types.
      ├─ min_length: Names must be unique at the same depth.
      ├─ min_length: Names must be unique at the same depth.
      ├─ a: Names must be unique at the same depth.
      ├─ b
      │ ├─ max_val: Must be a single, non-NA numeric value.
      │ └─ min_length: Must be a single, positive, non-NA integerish value.
      ├─ x
      │ ├─ type: `nope` not found in allowed types.
      │ └─ positive: Must be `TRUE`.
      ├─ [[7]]
      │ └─ type: `nope` not found in allowed types.
      ├─ a: Names must be unique at the same depth.
      └─ [[9]]
        └─ type: `nope` not found in allowed types.

# Validator accurately presents Schema errors

    Code
      Validator(1, list(type = "nope", min_length = "nope", a = list(type = "nope"),
      b = list(min_length = "nope", max_val = "nope"), x = list(type = "nope",
        positive = "nope"), list(type = "nope"), a = list(type = "nope"), min_length = "nope",
      list(type = "nope")), error = TRUE)
    Condition
      Error:
      ! <fluffy::Validator> object is invalid:
      - Schema validation failed with the following errors:
      ├─ type: `nope` not found in allowed types.
      ├─ min_length: Names must be unique at the same depth.
      ├─ min_length: Names must be unique at the same depth.
      ├─ a: Names must be unique at the same depth.
      ├─ b
      │ ├─ max_val: Must be a single, non-NA numeric value.
      │ └─ min_length: Must be a single, positive, non-NA integerish value.
      ├─ x
      │ ├─ type: `nope` not found in allowed types.
      │ └─ positive: Must be `TRUE`.
      ├─ [[7]]
      │ └─ type: `nope` not found in allowed types.
      ├─ a: Names must be unique at the same depth.
      └─ [[9]]
        └─ type: `nope` not found in allowed types.

# Validator data errors reflect perceived data structure, not schema structure

    Code
      Validator(data = list(1, a = "a", b = 10, x = -1), schema = list(type = "data.frame",
        min_length = 5, list(type = "character"), a = list(min_nchar = 2), b = list(
          min_length = 2, max_val = 5), list(positive = TRUE)), error = TRUE)
    Condition
      Error:
      ! <fluffy::Validator> object is invalid:
      - Data validation failed with the following errors:
      ├─ type: Is not type `data.frame`.
      ├─ min_length: Length must be at least 5.
      ├─ [[1]]
      │ └─ type: Is not type `character`.
      ├─ a
      │ └─ min_nchar: Char length(s) must be at least 2.
      ├─ b
      │ ├─ max_val: Value(s) must be at most 5.
      │ └─ min_length: Length must be at least 2.
      └─ [[4]]
        └─ positive: Value(s) must be positive (or zero).

# Unmatched data elements reflect perceived data structure

    Code
      Validator(data = list(1, a = "a", b = 10), schema = list(type = "data.frame",
        min_length = 5, list(type = "character"), a = list(min_nchar = 2), b = list(
          min_length = 2, max_val = 5), list(positive = TRUE), x = list(positive = TRUE),
        list(positive = TRUE)), error = TRUE)
    Condition
      Error:
      ! <fluffy::Validator> object is invalid:
      - Data validation failed with the following errors:
      ├─ type: Is not type `data.frame`.
      ├─ min_length: Length must be at least 5.
      ├─ [[1]]
      │ └─ type: Is not type `character`.
      ├─ a
      │ └─ min_nchar: Char length(s) must be at least 2.
      ├─ b
      │ ├─ max_val: Value(s) must be at most 5.
      │ └─ min_length: Length must be at least 2.
      ├─ [[4]]
      │ └─ positive: No data for field.
      ├─ x
      │ └─ positive: No data for field.
      └─ [[6]]
        └─ positive: No data for field.

# add_rule invalid args error messages are informative

    Code
      add_rule(r, "validator_fn_invalid_args", fn)
    Condition
      Error:
      ! Validator rule function arguments must be in one of the following forms:
      - `function(field, schema_field, ...)`
      - `function(field, schema_field, .self, ...)` |
         `function(field, schema_field, .data, ...)`
      - `function(field, schema_field, .self, .data)`

---

    Code
      add_rule(r, "validator_fn_used_.schema", function(x, .schema, ...) { })
    Condition
      Error:
      ! Validator rule functions cannot have a `.schema` argument.
      Did you mean to use `.data`?

---

    Code
      add_rule(r, "schema_fn_invalid_args", vfn, fn)
    Condition
      Error:
      ! Schema rule function arguments must be in one of the following forms:
      - `function(field, ...)`
      - `function(field, .self, ...)` |
         `function(field, .schema, ...)`
      - `function(field, .self, .schema)`

---

    Code
      add_rule(r, "schema_fn_used_.data", vfn, function(x, y, .data, ...) { })
    Condition
      Error:
      ! Schema rule functions cannot have a `.data` argument.
      Did you mean to use `.schema`?

---

    Code
      add_cross_rule(r, "cross_fn_invalid_args", c("type", "inherits"), fn)
    Condition
      Error:
      ! Schema cross rule function arguments must be in one of the following forms:
      - `function(node, ...)`
      - `function(node, .self, ...)` |
         `function(node, .schema, ...)`
      - `function(node, .self, .schema)`

---

    Code
      add_type_rule(r, "fn_invalid_args", function(x, y) x)
    Condition
      Error:
      ! `type_fn` must have exactly one argument (for the field value).

---

    Code
      add_coerce_rule(r, "fn_invalid_args", function(x, y) x)
    Condition
      Error:
      ! `coerce_fn` must have exactly one argument (for the field value).

