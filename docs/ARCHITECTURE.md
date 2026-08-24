# Software Architecture

## Execution flow

```mermaid
flowchart TD
  A[system_config] --> B[validation]
  B --> C[explicit data readers]
  C --> D[scenario and component calculations]
  D --> E[system checks]
  E --> F[CSV and figures]
  F --> G[regression tests]
```

`verify_framework.m` executes the complete analysis and regression checks.
`run_all.m` coordinates the engineering workflow but contains no component
ratings. Domain-level functions in `examples/` assemble reusable calculations
from `src/calculations/`. Project-controlled CSV inputs pass through
`src/io/read_project_csv.m`, which fixes the delimiter and validates the schema
before data reaches a calculation.

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

Add new vehicle or component data through the root-level `system_config.m` and
`data/`. Add new physics through a calculation function with a defined
input/output interface and a regression test. Do not put component constants
inside calculation functions.
