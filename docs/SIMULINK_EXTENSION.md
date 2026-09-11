# Simulink extension

MATLAB remains the screening and regression layer. A future Simulink or
Simscape model should begin with the propulsion loop because its inputs and
validation measurements are independent of cabin refrigeration.

| Stage | Model | Required evidence |
|---|---|---|
| 1 | Drive-unit thermal mass and coolant jacket | Heat capacity and motor-to-coolant resistance |
| 1 | Pump and restrictions | Active pump curve and component pressure-drop tests |
| 1 | Radiator and fan | Heat-rejection map versus coolant and air flow |
| 2 | Battery cells and cold plate | DC resistance, heat test and cell-to-coolant response |
| 3 | Cabin thermal volume | Complete solar, latent, ventilation and pull-down inputs |

The deleted compressor allocation model should not be restored without a full
refrigerant map and physical feedback into coolant and cabin temperatures.
