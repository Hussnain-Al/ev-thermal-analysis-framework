# EV Thermal Analysis Framework

Version **2.0.5**

A reusable MATLAB framework for preliminary thermal and hydraulic assessment of battery-electric vehicles. The repository calculates:

- battery resistive heat and a lumped cell-to-coolant response;
- integrated drive-unit loss over time-based speed cycles;
- coolant flow, bulk temperature rise, and radiator duty requirements;
- coolant-loop pressure loss and pump operating-point margin;
- cabin sensible load and shared cabin/battery compressor capacity.

The calculation functions are independent of the sample vehicle. Vehicle, battery, coolant, pump, heat-exchanger, and compressor inputs are defined in one configuration file or loaded from documented tables.

## Requirements

- MATLAB R2022b or later recommended
- Base MATLAB only

Simulink, Simscape, and Simscape Fluids are not required for this release.

## Run the sample case

Open MATLAB in the repository root and run:

```matlab
results = run_all;
```

Run the regression and interface checks with:

```matlab
run(fullfile('tests','run_sanity_checks.m'));
```

Results are written to `outputs/` as CSV and PNG files.

## Release traceability

The technical report records the verified MATLAB **v1.5.1** result archive. This
repository is the subsequent **v2.0.5** code release: it retains the same core
drive-cycle equations, adds clearer interfaces and calculation comments, and
corrects downstream radiator, pump, battery-path, and compressor screening.
Run `run_all` and `tests/run_sanity_checks.m` in MATLAB before publishing a new
set of v2.0.5 result files. Generated outputs are not treated as source code.

## Configure another vehicle or component set

Start with [`system_config.m`](system_config.m) in the project root. It is the only MATLAB file intended for routine input changes.

1. Enter the vehicle mass, wheel size, reduction ratio, and road-load coefficients.
2. Enter the battery capacity, series-cell count, resistance model, thermal mass, and control thresholds.
3. Enter coolant properties, hose geometry, component pressure losses, and radiator boundary temperatures.
4. Add compressor candidates and the intended compressor-map operating point.
5. Replace component maps and scenario files in `data/` without changing the calculation functions.

The detailed field and table requirements are defined in [`docs/COMPONENT_DATA_GUIDE.md`](docs/COMPONENT_DATA_GUIDE.md).

Custom configurations can also be created programmatically:

```matlab
cfg = system_config;
cfg.vehicle.mass_kg = 2200;
cfg.battery.capacity_Ah = 150;
cfg.propulsionCooling.designFlow_Lmin = 24;
results = run_all(cfg);
```

Startup validation stops the analysis when a required field, file, or table column is missing.

## Model architecture

The repository follows four clear layers:

1. **Configuration** — component values, system boundaries, file locations, and scenarios.
2. **Component data** — efficiency maps, operating envelopes, compressor maps, pump resistance data, and load cases.
3. **Calculations** — heat generation, energy balance, pressure loss, map interpolation, and capacity checks.
4. **Reporting** — exported traces, summaries, plots, and regression checks.

This separation is consistent with the system-modeling approach described by MathWorks for EV thermal management: parameterize pumps, compressors, valves, cold plates, heat exchangers, and piping from component data; then evaluate their interaction under drive cycles and transient conditions. This repository implements the preliminary numerical layer in MATLAB and provides a clean input boundary for later Simulink or Simscape development.

Reference: [MathWorks — EV Thermal Management](https://www.mathworks.com/discovery/ev-thermal-management.html)

## Repository structure

```text
system_config.m                   User-editable system definition
data/
  cycles/                         Time-speed scenarios
  components/                     Component maps and reference curves
  cases/                          Vehicle and cabin load cases
src/
  calculations/                   Reusable engineering functions
  io/                             Explicit, schema-validated input readers
  validation/                     Configuration and table checks
examples/                         Domain-level analysis entry points
tests/                            Regression and interface checks
docs/                             Methods, data contracts, and extension guide
references/                       Evidence and standards guidance
outputs/                          Generated results
run_all.m                         Main entry point
```

## Input evidence

The included dataset is a neutral sample case. It preserves the calculation behaviour of the original study but does not identify a vehicle or component manufacturer. Replace sample component curves before using the framework for a real design decision.

Recommended evidence labels are:

- measured test data;
- manufacturer data;
- digitized reference data;
- reconstructed data;
- engineering assumption.

Do not combine these categories into an unqualified result.

## Engineering boundaries

- Battery heat uses a resistance proxy and does not represent a complete electrochemical heat model.
- Drive loss depends on the quality of the efficiency map and road-load model.
- Radiator `UA` is a requirement, not a prediction of a particular core.
- The hydraulic result is incomplete until all component pressure-drop curves and an active pump `Q-H` curve are available.
- Compressor capacity is valid only at comparable refrigerant boundary conditions.
- The framework is not a prototype-validation record or a standards-conformity assessment.

## License and third-party data

Original source code is released under the repository license. Third-party drawings and branded source documents are not included. Users are responsible for the right to use any component maps or test data they add to the repository.
