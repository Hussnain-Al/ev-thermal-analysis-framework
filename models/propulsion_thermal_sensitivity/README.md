# Propulsion thermal sensitivity model

This standalone Simulink model receives an existing drive-unit heat trace and
integrates a two-node drive-unit/coolant energy balance.

## Inputs

| Input | Unit | Status |
|---|---|---|
| Drive-unit heat | kW | Calculated by the separate motor-heat module |
| Ambient temperature | C | Scenario boundary |
| Radiator UA | W/K | Unvalidated scenario input |

## States and outputs

- drive-unit lumped temperature;
- coolant-loop lumped temperature;
- motor-to-coolant heat transfer;
- radiator heat rejection.

The configured drive-unit thermal capacity, coolant-loop thermal capacity and
motor-to-coolant resistance are assumptions. Outputs are sensitivity results,
not temperature-limit predictions.

## Generate and check

```matlab
cfg = setup_project();
modelFile = build_propulsion_thermal_sensitivity_simulink( ...
    cfg,Overwrite=true);
open_system(modelFile);
run_propulsion_thermal_simulink_checks;
```

The motor-heat calculation remains a separate module so its heat trace can be
replaced by measured dynamometer data without changing this thermal model.
