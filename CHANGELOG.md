# Changelog

## 3.0.0-rc1 — 2026-09-11

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
