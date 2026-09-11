# Component Data Guide

## Configuration ownership

| File | Editable scope |
|---|---|
| `config/vehicle_config.m` | Vehicle mass, wheel, gearing, road load, grade, cycles |
| `config/motor_heat_config.m` | Torque/power workbook and efficiency surface |
| `config/motor_cooling_config.m` | Coolant, hoses, radiator boundaries, pressure drops, pump point |
| `config/battery_cooling_config.m` | Cell, pack, resistance, thermal network, cooling thresholds |
| `config/cabin_cooling_config.m` | Karachi ambient, hot-soak, humidity, setpoint, cabin duty |
| `config/shared_compressor_config.m` | Map point, refrigerant, voltage and allocation priority |

`config/project_config.m` is the single configuration entry point and assembles
the five subsystem configurations with the vehicle and drive-cycle inputs.

## Data contracts

| Domain | File | Required content |
|---|---|---|
| Motor heat | `drive_unit_limits.xlsx` | Sheets `Torque RPM Curve` and `Power RPM Curve`, numeric columns A:B |
| Motor heat | `drive_unit_efficiency_map.csv` | `Speed_rpm,Torque_Nm,IntegratedEfficiency_pct` |
| Motor cooling | `inactive_pump_resistance_curve.csv` | Flow, passive pressure loss, digitization uncertainty |
| Motor cooling | `propulsion_radiator_geometry.csv` | Original core, tube and fin geometry |
| Battery cooling | `battery_heat_exchanger_geometry.csv` | Original battery exchanger geometry |
| Cabin cooling | `cabin_load_inputs.csv` | Component load and recovered cabin boundaries |
| Shared compressor | `compressor_performance_map.csv` | RPM, evaporating temperature, capacity, input power, current, COP |
| Shared compressor | `compressor_candidates.csv` | Candidate rating and evidence condition |

All CSVs are comma-delimited with one header row. `read_project_csv` rejects
missing, extra, ambiguous or nonnumeric fields before calculations start.

## Evidence rules

Use one of these labels for every input: measured, manufacturer, digitized,
reconstructed, assumed, or historical. A component geometry file is not a
performance map. A software regression establishes numerical consistency, not
physical validation.

The full audited mapping is in
[`../references/SOURCE_PROVENANCE.md`](../references/SOURCE_PROVENANCE.md).
