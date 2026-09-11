# Methodology

## Motor heat

The motor module converts a time-speed cycle into wheel force, shaft speed,
torque and power. The original torque/power workbook defines the operating
envelope and the digitized integrated map defines efficiency. Energy balance
gives DC-link power and combined motor/inverter/reducer heat.

The same magnitude-based efficiency surface is still used for regeneration.
A separate measured regeneration map is required for validation.

## Motor cooling

The motor-cooling module receives only average and peak motor heat. Bulk coolant
rise follows `Q = m_dot Cp deltaT`. Radiator `UA` is a requirement calculated
from LMTD, not a prediction of the archived radiator geometry. Darcy-Weisbach
and fitting `K` losses define the coolant-loop system curve.

The documented pump point is a screening point. A final operating point needs
the complete active pump `Q-H` curve at the installed coolant temperature.

## Battery cooling

The battery module converts DC-link power to pack current using the battery's
own nominal voltage. Minimum resistive heat is `I^2R` per series cell. A lumped
cell thermal state removes heat through the reconstructed base resistance when
cooling is active.

The 0.40 mOhm value is an ACR limit at one temperature and state of charge. It
is not a complete DC resistance model, and the lumped state cannot predict
cell-to-cell gradients.

The recovered construction drawings, equivalent circuits and the exact model
simplification are shown in
[`BATTERY_THERMAL_MODEL.md`](BATTERY_THERMAL_MODEL.md).

## Cabin cooling

The cabin module reproduces the recoverable sensible-load subtotal and records
the Karachi ambient, hot-soak and humidity boundaries. It does not invent the
missing solar, latent, ventilation or transient pull-down terms.

The full load-path figure and the current model boundary are shown in
[`CABIN_COOLING_MODEL.md`](CABIN_COOLING_MODEL.md).

## Shared compressor

Only the shared-compressor module combines battery plate demand and cabin duty.
It interpolates the manufacturer R134a map inside its original axes, applies a
declared allocation priority, and reports capacity shortfall. This remains a
gross capacity balance until the condenser, heat exchangers, pressure losses,
refrigerant states and controls are modeled.

## Validation target

The future experiment should record synchronized electrical power, motor loss
or calorimetric heat, coolant inlet/outlet temperatures, flow, component
pressure drop, battery temperature, cabin temperature, compressor electrical
power and ambient conditions. Predictions should be compared with measurement
error and sensor uncertainty, not described as proven from agreement at one
point.
