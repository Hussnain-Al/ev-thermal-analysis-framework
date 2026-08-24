# Data Directory

The data directory separates operating scenarios, component performance data, and application load cases.

## `cycles/`

Time-speed traces used by the transient vehicle calculation. The included urban and highway files are sample scenarios. Add or replace cycles through `cfg.cycles` in the root-level `system_config.m`.

## `components/`

- `drive_unit_limits.xlsx` — torque-speed and power-speed envelopes.
- `drive_unit_efficiency_map.csv` — integrated motor/inverter/reducer efficiency surface.
- `compressor_performance_map.csv` — refrigerating capacity and input power.
- `inactive_pump_resistance_curve.csv` — pressure loss through an inactive pump; not an active pump curve.
- `drive_unit_thermal_reference.csv` — optional thermal reference points for comparison.
- `heat_exchanger_geometry.csv` — geometry record only; not a performance map.

## `cases/`

- `vehicle_load_cases.csv` — discrete battery/vehicle screening conditions.
- `cabin_load_inputs.csv` — recovered sensible cabin-load terms.

## `sample_parameter_register.csv`

Records the source class and limitation of important sample inputs. Maintain an equivalent register for each new study.

File schemas are defined in `docs/COMPONENT_DATA_GUIDE.md`.
All CSV files are imported with an explicit comma delimiter, first-row column
names, fixed column count, and numeric-field validation. Do not change headers
without also updating the documented data contract.
