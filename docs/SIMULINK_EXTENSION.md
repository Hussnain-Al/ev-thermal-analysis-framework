# Simulink and Simscape Extension

## Decision

Do not replace the MATLAB framework. Use it to freeze inputs, size components,
generate regression values and audit energy balances. Add Simulink/Simscape as
a second layer for coupled transient plant and control behavior.

## Recommended subsystem models

| Stage | Subsystem | Purpose | MATLAB interface |
|---|---|---|---|
| 1 | Integrated-drive thermal mass and jacket | Winding/housing temperature response | `motor_heat` trace |
| 1 | Propulsion coolant loop | Pump, restrictions, radiator and fan dynamics | `motor_cooling` requirements |
| 1 | Battery module and cold plate | Cell temperature distribution and coolant response | `battery_cooling` trace |
| 1 | Cabin thermal volume | Solar, occupant, infiltration and pull-down dynamics | `cabin_cooling` inputs |
| 2 | Shared R134a circuit | Compressor, condenser, two expansion branches and heat exchangers | `shared_compressor` map and load traces |
| 3 | Supervisory controls | Pump, fan, compressor speed and branch allocation | Module thresholds and limits |

Recommended products are Simulink, Simscape, Simscape Fluids and Simscape
Battery. The reference partition follows MathWorks' current BEV thermal example,
which separates the electric powertrain, driveline, refrigerant cycle, coolant
cycle and passenger cabin.

## Validation sequence

1. Match every Simulink subsystem to its MATLAB steady or transient regression.
2. Replace assumed coefficients with bench or vehicle measurements.
3. Validate components before validating the coupled system.
4. Add sensor uncertainty and compare error over complete drive cycles.
5. Freeze the validated parameter set separately from controller calibration.

The archived ADVISOR `.mat` file may be used to study file structure only. It
must not be used as the vehicle validation target because its motor and battery
do not match this project.
