# Methodology

## Vehicle and integrated drive

Vehicle speed is converted to wheel and drive-unit speed. Longitudinal force includes the configured road-load function, translational inertia, and road grade. Requested wheel torque and power are checked against the drive-unit limits.

The configured efficiency map gives integrated drive efficiency at each speed and torque point. During motoring:

```text
electrical input = mechanical output / efficiency
drive heat = electrical input - mechanical output
```

During regeneration, the same map is used as a screening approximation. Replace this with a separate regeneration-efficiency map when available.

## Battery

The minimum resistive model calculates `I²R` heat at cell level and multiplies by the series-cell count. A lumped thermal state estimates cell temperature and heat removal through the configured base thermal resistance. The result does not represent cell-to-cell temperature distribution.

## Coolant loop

Bulk coolant rise follows `Q = m_dot Cp deltaT`. Pipe pressure loss combines Darcy-Weisbach major loss and fitting `K` losses. Coolant properties vary by the configured temperature cases.

## Radiator

The code calculates required `UA` and air mass flow from the thermal duty and boundary temperatures. A particular heat exchanger is sufficient only when its performance map or test data meets those requirements.

## Compressor capacity

The compressor map is interpolated only within its provided axes. Capacity is allocated according to the configured priority. The result is a gross capacity comparison unless condenser, heat-exchanger, piping, and control losses are included in the source map or an explicit derating model.

## Evidence control

Classify inputs as measured, manufacturer-provided, digitized, reconstructed, or assumed. Report model outputs with the same evidence boundary. Passing a software regression test establishes calculation consistency; it does not validate the physical system.
