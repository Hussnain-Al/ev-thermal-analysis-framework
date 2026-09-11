# Component Data Guide

## Configuration ownership

| File | Editable scope |
|---|---|
| `config/vehicle_config.m` | Vehicle mass, wheel, gearing, road load, grade, cycles |
| `config/motor_heat_config.m` | Torque/power workbook and efficiency surface |
| `config/motor_cooling_config.m` | Two-node thermal assumptions, coolant, hoses, losses and pump point |
| `config/battery_cooling_config.m` | Cell capacity, ACR proxy, base path and SVOLT limits |
| `config/cabin_cooling_config.m` | Karachi ambient, hot-soak, humidity, setpoint, cabin duty |

`config/project_config.m` is the single configuration entry point and assembles
the four domain configurations with the vehicle and drive-cycle inputs.

## Data contracts

| Domain | File | Required content |
|---|---|---|
| Motor heat | `drive_unit_limits.xlsx` | Sheets `Torque RPM Curve` and `Power RPM Curve`, numeric columns A:B |
| Motor heat | `drive_unit_efficiency_map.csv` | `Speed_rpm,Torque_Nm,IntegratedEfficiency_pct` |
| Motor cooling | `inactive_pump_resistance_curve.csv` | Flow, passive pressure loss, digitization uncertainty |
| Motor cooling | `propulsion_radiator_geometry.csv` | Original core, tube and fin geometry |
| Cabin cooling | `Cabin_Cooling_Load_AutoRecovered.xlsx` | Original recovered surface-load calculation |
| Cabin cooling | `cabin_load_inputs.csv` | Derived surface, occupant and infiltration totals |

All CSVs are comma-delimited with one header row. `read_project_csv` rejects
missing, extra, ambiguous or nonnumeric fields before calculations start.

## Evidence rules

Use one of these labels for every input: measured, manufacturer, digitized,
reconstructed, assumed, or historical. A component geometry file is not a
performance map. A software regression establishes numerical consistency, not
physical validation.

The full audited mapping is in
[`../references/SOURCE_PROVENANCE.md`](../references/SOURCE_PROVENANCE.md).
