# Missing model inputs

These inputs are required before the screening models can become physical
cooling-loop predictions. Generic internet values must not be substituted for
vehicle-specific measurements.

## Manufacturer or supplier data that may be found online

| Domain | Required input | Required form and unit | Suitable source |
|---|---|---|---|
| Battery | DC internal resistance | Ohm versus SOC, cell temperature and current direction | Exact SVOLT 134 Ah cell datasheet or test report |
| Battery | Cell heat capacity | J/K, or cell mass and specific heat versus temperature | Exact-cell supplier thermal report |
| Battery plate | Thermal and hydraulic map | Heat transfer and pressure drop versus coolant flow and inlet temperatures | Exact cold-plate supplier test report |
| Pump | Active operating curve | Pressure rise in kPa versus L/min at several speeds and coolant temperatures | Exact pump manufacturer curve |
| Radiator | Validation map | Heat rejection or UA versus coolant flow, air flow and inlet temperatures | Prototype test, validated correlation or CFD |
| Radiator | Hydraulic map | Coolant pressure drop in kPa versus L/min and temperature | Prototype test or validated core model |
| Coolant | Thermophysical properties | Density, viscosity, specific heat and conductivity versus temperature | Selected coolant manufacturer datasheet |
| Drive unit | Loss map | Motor/inverter/reducer loss or efficiency versus torque, speed and temperature | Exact drive-unit supplier numerical map |

Useful search strings must include the exact manufacturer and part number, for
example `TKU PCE L pump Q-H curve`, `SVOLT 134Ah LFP DCIR SOC temperature`, and
the exact radiator or cold-plate part number followed by `performance map`.

## Vehicle-specific information that requires design records or testing

| Domain | Required input | Unit | Why generic internet data is invalid |
|---|---|---:|---|
| Drive unit | Lumped thermal capacitance | J/K | Depends on the exact motor, inverter, reducer and coolant jacket |
| Drive unit | Motor-to-coolant thermal resistance | K/W | Depends on internal construction and installed flow |
| Coolant loop | Total coolant inventory | L or kg | Depends on vehicle routing and component volumes |
| Battery | Cell-to-cold-plate step response | Temperature and heat versus time | Depends on pad compression, contact area and assembly tolerances |
| Battery | Pack topology and flow distribution | Cell count, channel flow and branch balance | Depends on the production pack layout |
| Cabin | Leakage, solar and thermal-mass characterization | kg/s, W and J/K | Depends on the finished body, glazing, trim and sealing |

## Blocked model outputs

| Output | Blocking inputs |
|---|---|
| Battery transient temperature | DCIR, cell heat capacity and measured cell-to-plate response |
| Battery coolant flow and temperature | Cold-plate map, pump curve, radiator/chiller map and coolant inventory |
| Propulsion operating flow | Full active pump curve and candidate-radiator pressure-drop curve; motor/PDU drops are excluded by current scope |
| Validated motor/coolant temperatures | Identified thermal capacitances, motor-to-coolant resistance and radiator map |
| Cabin pull-down and compressor demand | Complete solar, latent, ventilation, thermal-mass and refrigerant-component data |

Until the listed evidence exists, the blocked outputs are not calculated.
