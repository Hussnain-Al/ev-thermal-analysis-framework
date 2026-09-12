# Simulink extension

MATLAB remains the screening and regression layer. Simulink development is
performed loop by loop before any integration.

| Stage | Model | Status | Required evidence |
|---|---|---|---|
| 1 | Battery sustained requirements | Builder added | Current SVOLT evidence is sufficient for a lower-bound screen |
| 1 | Battery cells and cold plate | Blocked | DC resistance, heat test and cell-to-coolant response |
| 2 | Drive-unit thermal mass and coolant jacket | Blocked | Heat capacity and motor-to-coolant resistance |
| 2 | Pump and restrictions | Blocked | Active pump curve and component pressure-drop tests |
| 2 | Radiator and fan | Blocked | Heat-rejection map versus coolant and air flow |
| 3 | Cabin thermal volume | Blocked | Complete solar, latent, ventilation and pull-down inputs |

The battery Simulink builder is in
`models/battery_loop/build_battery_loop_simulink.m`. It creates an algebraic
requirements model, not a transient thermal plant.

The deleted compressor allocation model should not be restored without a full
refrigerant map and physical feedback into coolant and cabin temperatures.
