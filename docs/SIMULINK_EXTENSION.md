# Simulink extension

MATLAB remains the screening and regression layer. Simulink development is
performed loop by loop before any integration.

| Stage | Model | Status | Required evidence |
|---|---|---|---|
| 1 | Battery sustained requirements | Compiled Simulink screen | Current SVOLT evidence is sufficient for a lower-bound screen |
| 1 | Battery cells and cold plate | Blocked | DC resistance, heat test and cell-to-coolant response |
| 2 | Drive-unit thermal mass and coolant jacket | Compiled sensitivity model | Heat capacity and motor-to-coolant resistance remain uncalibrated |
| 2 | Pump operating point | Not modeled | Retain the documented point and inactive-resistance curve only; no additional curve is requested |
| 2 | Radiator/fan requirements | MATLAB design screen | Required airflow is reported; achieved core performance needs a selected-core map or test |
| 3 | Cabin thermal volume | Blocked | Complete solar, latent, ventilation and pull-down inputs |

The battery Simulink builder is in
`models/battery_requirements/build_battery_requirements_simulink.m`. It creates
an algebraic requirements screen, not a transient thermal plant. The propulsion
builder is in `models/propulsion_thermal_sensitivity/` and exposes its radiator
UA scenario as a model input.

See `MISSING_MODEL_INPUTS.md` before adding any physical components.

The deleted compressor allocation model should not be restored without a full
refrigerant map and physical feedback into coolant and cabin temperatures.
