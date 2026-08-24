# Software Architecture

## Execution flow

```mermaid
flowchart TD
  A[system_config] --> B[validation]
  B --> C[scenario readers]
  C --> D[component calculations]
  D --> E[system checks]
  E --> F[CSV and figures]
  F --> G[regression tests]
```

`run_all.m` coordinates the workflow but contains no component ratings. Domain-level functions in `examples/` assemble reusable functions from `src/calculations/`.

## Physical-system boundary

```mermaid
flowchart TD
  A[Drive cycle] --> B[Vehicle longitudinal model]
  B --> C[Integrated drive unit]
  C --> D[Propulsion coolant loop]
  D --> E[Radiator and ambient air]
  B --> F[Battery electrical load]
  F --> G[Battery thermal model]
  G --> H[Battery coolant interface]
  H --> I[Shared refrigerant capacity]
  J[Cabin sensible load] --> I
```

The propulsion coolant loop is separate from the battery coolant/refrigerant branch. The model exchanges calculated heat duties between domains; it does not solve a full refrigerant state network.

## Extension rule

Add new vehicle or component data through `config/` and `data/`. Add new physics through a calculation function with a defined input/output interface and a regression test. Do not put component constants inside calculation functions.
