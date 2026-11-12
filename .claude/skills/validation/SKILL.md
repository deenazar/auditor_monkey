---
name: validation
description: Use for any feature that accepts user input or stores data.
---

# Validation

- Validate on the UI (instant, friendly message) AND in the data layer.
- Check required fields, types, ranges, formats, max lengths, dates and
  duplicates.
- Money: no negatives where invalid, correct decimals, stored as integer
  minor units (e.g. cents).
- Clear error messages; never crash on bad input.
