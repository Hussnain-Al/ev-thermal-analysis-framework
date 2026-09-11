# Contributing

Changes must preserve the five subsystem boundaries and explicit result
interfaces described in `docs/ARCHITECTURE.md`.

## Pull-request requirements

1. Do not add component constants inside `src/calculations/` or another module.
2. Document the schema and units of every new input table.
3. Add a regression or interface check for new calculation behaviour.
4. State whether new data are measured, manufacturer-provided, digitized, reconstructed, or assumed.
5. Do not commit third-party documents or branded drawings without redistribution rights.
6. Run the complete workflow from a clean MATLAB session:

```matlab
results = verify_framework;
```

The calculation should fail clearly when a required input is absent or outside a permitted interpolation range.
