# Component Data Guide

This document defines the minimum data required to replace the sample vehicle or components without editing the calculation functions.

All framework CSV files must be comma-delimited with the required names in the
first row. `read_project_csv` rejects missing, extra, ambiguous, or nonnumeric
fields before an analysis begins.

## Driving inputs and calculated responses

The framework keeps imposed conditions separate from calculated quantities:

| Category | Examples | Role in the model |
|---|---|---|
| Driving input | Time-speed cycle, ambient temperature, road grade, cabin load | Imposed boundary or demand that initiates the calculation. |
| Component input | Mass, wheel diameter, reduction ratio, efficiency map, resistance, coolant properties | Describes the vehicle or selected component. |
| Intermediate state | Acceleration, wheel force, shaft speed, torque, Reynolds number, coolant mass flow | Calculated quantity used by the next equation. |
| Calculated response | Drive-unit heat, battery heat, cell temperature, pressure loss, required UA, capacity margin | Result used for design screening. |

The main cause-and-effect chain is:

```text
speed cycle -> acceleration and shaft speed -> force, power and torque
-> mapped efficiency -> drive-unit heat and battery current
-> battery heat and coolant demand -> radiator, pump and compressor checks
```

## Vehicle

Edit `cfg.vehicle` in the root-level `system_config.m`.

| Field | Unit | Description |
|---|---:|---|
| `mass_kg` | kg | Test mass used for longitudinal inertia. |
| `wheelDiameter_m` | m | Loaded rolling diameter. |
| `gearRatio` | — | Motor speed divided by wheel speed. |
| `roadLoadA_N` | N | Constant term in `F = A + Bv²`. |
| `roadLoadB_N_per_ms2` | N/(m/s)² | Speed-squared road-load term. |
| `grade_pct` | % | Constant road grade for the scenario. |
| `regenEnabled` | logical | Enables regenerative-braking loss calculation. |

Use measured coast-down coefficients when possible. If only `CdA` and rolling-resistance data are available, convert them into a consistent road-load model before running the analysis.

## Battery

Edit `cfg.battery`.

The minimum heat model uses:

```text
cell heat = current² × resistance proxy
pack heat = cell heat × series-cell count
```

`resistanceProxy_Ohm` can be a DC resistance, a fitted effective resistance, or an AC-resistance screening value. Record which one is used. A complete model should later include state-of-charge, temperature, ageing, and reversible heat effects.

## Integrated drive unit

Replace:

- `data/components/drive_unit_limits.xlsx`
- `data/components/drive_unit_efficiency_map.csv`

The workbook must contain:

| Sheet | Columns |
|---|---|
| `Torque RPM Curve` | motor speed in rpm, maximum torque in N·m |
| `Power RPM Curve` | motor speed in rpm, maximum mechanical power in kW |

The efficiency CSV must contain:

```text
Speed_rpm,Torque_Nm,IntegratedEfficiency_pct
```

Use an integrated map when the motor, inverter, and reducer losses are already combined. Do not add those losses again as separate constants.

## Compressor

Replace `data/components/compressor_performance_map.csv`.

Required columns:

```text
RPM,EvaporatorTemperature_C,CoolingCapacity_kW,InputPower_kW,Current_A
```

All rows must use comparable condensing temperature, superheat, subcooling, refrigerant, and supply voltage. The code prohibits extrapolation beyond the provided rpm and evaporating-temperature axes. A final selection also requires high-ambient condenser and installation effects.

Add comparison candidates to `cfg.hvac.compressorCandidates`. Candidate capacity must be evaluated at a defensible operating point; catalogue maximum capacity is not interchangeable with installed capacity.

## Coolant and pump

Enter coolant density, dynamic viscosity, and specific heat in `cfg.coolant` for every temperature to be evaluated.

Define hose segments and fitting counts in `cfg.coolingLoop`. Add known component pressure drops to `componentDrop_kPa_atReference` and identify their reference flow. The current model applies square-law scaling to these component losses.

Set the pump comparison point in:

```matlab
cfg.pump.referenceFlow_Lmin
cfg.pump.minimumHead_kPa
cfg.pump.checkTemperature_C
```

This point is only a screening check. Final selection requires the full active pump `Q-H` curve and its intersection with the system curve.

The optional inactive-pump series-flow curve uses:

```text
Flow_Lmin,Flow_Lh,InactivePumpResistance_kPa,DigitizationUncertainty_kPa,EvidenceStatus
```

It represents passive restriction through a non-running pump. It is not an
active pump head curve and must not be added to normal active-pump head.

## Heat exchanger and radiator

The code calculates required thermal conductance:

```text
UA = thermal duty / log-mean temperature difference
```

Enter the radiator coolant inlet and the air inlet/outlet screening temperatures in `cfg.propulsionCooling`. The code calculates radiator coolant outlet from the same coolant energy balance used for the drive-unit temperature rise. To confirm a particular radiator, add its measured or manufacturer-provided heat-rejection, airflow, fan, and coolant pressure-drop maps.

## Drive cycles

Each cycle file must contain time in seconds and vehicle speed in miles per hour. Add the cycle to `cfg.cycles` with:

- `Name` — display name;
- `FileStem` — output filename prefix;
- `File` — absolute or repository-relative resolved path.

The framework accepts any number of cycles.
