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

The motor-to-coolant resistance (0.0340 K/W) is calibrated on the supplier
143 C rated point. The drive-unit and coolant-loop thermal capacities remain
assumptions. The radiator UA input defaults to the candidate-core estimate
(139.7 W/K normal, 122.3 W/K fan-only). Outputs are screening results;
the drive-unit node is an upper bound on winding temperature.

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
