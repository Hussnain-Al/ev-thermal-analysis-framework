# Changelog

## 4.4.1 — 2026-09-13

- Exported both supported Simulink block diagrams during the public MATLAB
  workflow and published the exact generated diagrams in the README.
- Added explicit diagram captions separating the algebraic battery requirements
  screen from the uncalibrated propulsion thermal sensitivity model.

## 4.4.0 — 2026-09-13

- Replaced raw-peak-only drive-cycle plots with one-second heat, a trailing
  60-second mean and cumulative heat energy.
- Replaced constant-case time traces with explicit sustained design-point bars.
- Removed the ideal `A_core v` ram-air comparison and every derived capture
  claim because neither represents installed core airflow.
- Added radiator face-velocity and ideal-UA sensitivity over a 5–15 C assumed
  air-temperature rise.
- Separated the calculated external-hose system curve from the supplied
  stopped-pump passive resistance evidence.
- Removed uncalibrated motor temperatures and the recovered cabin subtotal from
  the README's headline result figures.
- Renamed outputs so instantaneous peaks, requirements, assumptions and supplied
  evidence cannot be mistaken for validated component performance.

## 4.3.1 — 2026-09-13

- Interpreted the supplied radiator geometry as a 270 by 310 by approximately
  26 mm core with 26 by 2 mm external flat-tube dimensions.
- Kept the confirmed 20 mm internal diameter exclusively on the six external
  hoses; it is not assigned to individual radiator tubes.
- Added 0.2 mm tube-wall and 0.1 mm fin-thickness literature screening values
  from a tested automotive radiator, without using them to predict achieved UA.
- Removed unsupported installation-loss geometry and fan-curve requests.
- Renamed the zero-speed result as a required air-volume flow so it cannot be
  mistaken for a selected fan operating point.
- Retained the documented pump point and inactive resistance curve as the only
  available pump evidence without inventing a complete active Q-H curve.

## 4.3.0 — 2026-09-12

- Confirmed all six external hoses use 20 mm internal diameter and removed the
  unsupported component pressure-drop allowances from the hydraulic result.
- Replaced the former pump-shortfall verdict with a hose-only pressure
  requirement and remaining-head budget.
- Added first-pass radiator and fan requirements for sustained grade and
  low-speed hot-weather cases using the retained candidate core geometry.
- Added ideal face-flow upper bounds and zero-road-speed airflow requirements
  without assuming installation efficiency.
- Added the 83.5 kg three-in-one drive-unit mass and exposed its effective
  specific heat as an uncalibrated thermal assumption.
- Added the supplied controller rated and peak loss points as reference data;
  they are not added to the integrated three-in-one heat map.

## 4.2.0 — 2026-09-12

- Renamed the battery Simulink artifact as a requirements screen so it is not
  presented as a physical coolant-loop model.
- Added a separate two-node propulsion thermal sensitivity model driven by
  motor heat, ambient temperature and a radiator-UA scenario input.
- Added a model-input register separating searchable supplier data from
  vehicle-specific measurements.
- Kept all unsupported Simscape coolant, refrigeration and compressor outputs
  blocked.

## 4.1.0 — 2026-09-12

- Added a standalone Simulink builder for the battery sustained-load
  requirements model.
- Consolidated battery heat and allowable-coolant calculations into one shared
  function used by MATLAB and represented block-by-block in Simulink.
- Added a Simulink generation and compile check to public continuous
  integration.
- Kept transient cell temperature, coolant hydraulics, radiator, compressor and
  refrigeration calculations outside the battery model until evidence exists.

## 4.0.1 — 2026-09-12

- Replaced README previews with the exact MATLAB R2024b workflow artifacts.
- Removed the nonexistent private-PDF path from battery configuration.
- Corrected source-archive and battery-screen provenance statements.
- Made the pump conclusion follow the calculated coverage result.

## 4.0.0 — 2026-09-11

- Removed the shared-compressor module, data, plots, tests and verdicts.
- Replaced the battery drive-cycle temperature artifact with a sustained
  ACR-based heat floor and allowable-coolant-temperature screen.
- Added the SVOLT 55 C charge cutoff, 60 C absolute limit and supplier thermal
  reference cases without inventing a coolant setpoint.
- Added two-node drive-unit/coolant transients for NYCC, HWFET, sustained grade
  and low-speed hot-weather cases.
- Plotted the known partial-loop loss against the documented pump point.
- Made the recovered cabin Excel workbook an active, checked source.

## 3.1.0 — 2026-09-11

- Added a combined propulsion-loop decision table covering duty, coolant rise,
  radiator outlet, required `UA`, air flow and pump-head margin.
- Expanded the battery summary with heat and cooling energy, cooling-active
  time, temperature extrema, event times and temperature margin.
- Added propulsion thermal-requirement, cabin-load and shared-compressor plots.
- Revised motor and battery transient plots with comparable axes and extrema.
- Published every MATLAB-generated result plot in the README with rounded
  loop-level decision tables and explicit model-boundary notes.

## 3.0.0 — 2026-09-11

- Split configuration, data, execution and outputs into motor heat, motor
  cooling, battery cooling, cabin cooling and shared compressor domains.
- Removed battery parameters from the motor operating-point calculation;
  battery analysis now consumes an explicit time-aligned DC-link trace.
- Added one combined cabin/battery compressor decision file while preserving
  the independent upstream result files.
- Retained the original torque/power workbook and active digitized source data.
- Added an audited source manifest, including exclusions for the mismatched
  historical ADVISOR model and copyrighted/confidential source documents.
- Verified the included NYCC and HWFET numerical sequences point-for-point
  against the official EPA source files.
- Added a staged Simulink/Simscape extension and experimental-validation plan.
- Removed the unused v2 monolithic wrappers and duplicate calculation paths.
- Passed the complete modular workflow and regression suite in MATLAB R2024b.

## 2.0.5 — 2026-08-25

- Replaced automatic CSV delimiter detection with a single explicit reader
  that enforces comma delimiters, first-row headers and preserved names.
- Routed every calculation input CSV through the validated reader.
- Added full schema-import checks for every CSV used by `run_all`.
- Added `verify_framework` as the single full-run and regression-test entry
  point for desktop MATLAB, MATLAB Online and continuous integration.
- Confirmed the complete release with `verify_framework` in MATLAB Online.
- Updated repository documentation, citation metadata, data contracts and
  workflow links for the public v2.0.5 release.

## 2.0.4 — 2026-08-25

- Made inactive-pump curve import robust to equivalent MATLAB table-header
  spellings while retaining explicit unit, numeric, range and monotonicity
  validation.
- Added a regression test for normalized pump-curve column names.

## 2.0.3 — 2026-08-25

- Moved `system_config.m` to the project root so MATLAB Online resolves the
  configuration before any subfolder path initialization.
- Updated all user guidance and startup checks for the root-level interface.

## 2.0.2 — 2026-08-25

- Fixed clean startup in MATLAB Online by loading `system_config.m` from its
  physical configuration folder before running validation.
- Added a startup regression check to the sanity-test entry point.

## 2.0.1 — 2026-08-25

- Added equation-level comments to the drive-cycle, battery, coolant,
  hydraulic, radiator and compressor functions.
- Standardized the remaining drive-cycle error identifiers.
- Corrected the radiator boundary so its coolant drop equals the calculated
  drive-unit coolant rise; the radiator outlet is no longer an independent input.
- Corrected the pump-point screening to use a configured hot-loop coolant
  temperature and to report major, minor and component-loss contributions.
- Added a sustained battery base-path temperature check and identified the
  initial battery-to-plate compressor request with its time and temperature.
- Removed constant-C-rate battery cases from compressor sizing. Compressor
  capacity is now assessed only with time-aligned drive-cycle results.

## 2.0.0 — 2026-08-25

- Replaced component-specific configuration functions with one documented `system_config.m` interface.
- Renamed data files, examples, outputs, and functions with neutral component terminology.
- Added startup validation for configuration fields, file availability, table schemas, and cooling-loop dimensions.
- Added configurable drive cycles, compressor allocation priority, road grade, flow cases, coolant-property temperature, and pump comparison point.
- Changed cycle averages and compressor duty fractions to time-weighted integration so irregularly sampled scenarios are handled correctly.
- Removed branded drawings and component model names from the distributable repository.
- Added component-data contracts, a Simulink/Simscape extension plan, and GitHub Actions verification.
- Retained the original sample calculation behaviour as regression data.

## 1.7.0 — 2026-08-24

- Added transient urban and highway drive-cycle thermal calculations.
- Added integrated drive efficiency-map interpolation and compressor/pump screening outputs.
