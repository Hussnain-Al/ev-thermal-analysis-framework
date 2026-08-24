# Contributing

Changes should preserve the separation between configuration, component data, calculations, and reporting.

## Pull-request requirements

1. Do not add component constants inside `src/calculations/`.
2. Document the schema and units of every new input table.
3. Add a regression or interface check for new calculation behaviour.
4. State whether new data are measured, manufacturer-provided, digitized, reconstructed, or assumed.
5. Do not commit third-party documents or branded drawings without redistribution rights.
6. Run:

```matlab
results = run_all;
run(fullfile('tests','run_sanity_checks.m'));
```

The calculation should fail clearly when a required input is absent or outside a permitted interpolation range.
