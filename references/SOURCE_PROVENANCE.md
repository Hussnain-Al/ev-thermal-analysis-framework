# Source Provenance

The calculation repository keeps reusable numerical inputs under `data/`.
Third-party source documents are not redistributed in the public repository.
This manifest records their original filenames, hashes, model roles and
limitations so the derivation can be audited against the owner's source archive.

## Active project evidence

| Original file | SHA-256 | Module | Use in the model | Status |
|---|---|---|---|---|
| `Torque Curves.xlsx` | `b2754378985acc4cb8dd657ffffb7032e3e1779af4e8050951130a0b532b7e71` | Motor heat | Original native torque-speed and power-speed charts; the committed workbook is byte-identical. | Active source |
| `125kw 3 in 1.pdf` | `2dd0de37d3b059185960a2b94c08e6138ace6ba16ecd94272c15decab2c183e7` | Motor heat and cooling | 125 kW integrated-drive ratings, efficiency contours, winding-temperature reference cases, and controller-only loss points of 1.580 kW rated and 3.218 kW peak. | Active digitized source; rated 60 kW at 125 Nm (4584 rpm) and peak 125 kW at 280 Nm (4263 rpm) fix the winding-calibration and peak-check points; controller points are retained as cross-checks and are not added to the integrated loss map |
| `SVOLT 134Ah LFP Cell Specification (3).zh-CN.en (1).pdf` | `0fc47d3ab038cab54584a2045f9e04f448716be0e16ff8999f38812df9beb511` | Battery cooling | 134 Ah, 0.40 mOhm ACR, 2C continuous discharge, 55 C charging cutoff and 60 C absolute limit. | Active manufacturer evidence; ACR is only a heat-floor proxy |
| `HEAT TRANSFER PHENOMENA INSIDE A MODULE.pdf` | `8da01bd498a4a349a41f3aa4f97cbac9c9646a98c3692cb014e7eb792442e0cc` | Battery cooling | 3.10 K/W base path. | Active reconstructed path; lateral paths are not used as external sinks |
| `Thermal_pad_data_sheet.pdf` | `3e10908a31f85319ffd3a217c4f4a2f9637e4e5e1d30dd24e6576f878f77c19d` | Battery cooling | T-Global TG-A1250: 12.5 W/(m K); 0.304 / 0.194 / 0.147 C in2/W at 10 / 30 / 50 psi. Sets thermal pad 1 and pad 2 resistances (register P02, P04). | Active manufacturer evidence |
| `Cabin Cooling Load(AutoRecovered).xlsx` | `7970276d972ee6856224057f24cff67981bda1ae5e0c0aa369c8759a282a2688` | Cabin cooling | Recovered body/glazing, occupant and infiltration sensible-load terms. | Active partial source; not a complete Karachi pull-down load |
| `TKU_PCE_L-English.pdf` | `6b7f3d1a0d2e11837f93eba07044e9797ed42d70daf27a8a3f9e26ca87d9b7f5` | Motor cooling | 20 L/min at 60 kPa screening point and inactive-pump resistance curve at 23 +/- 5 C. | Only available pump evidence; the passive curve is not re-labelled as active pump head |
| `lubemax-antifreeze-coolant-5050.pdf` | `9f95fe9f2b69e7aa08acb27fdc4147e3c66c575cf666b379eb5b3a95c7536084` | Motor and battery cooling | LubeMax Antifreeze/Coolant 50/50: ethylene glycol 50% v/v (ASTM D3306), boiling point 107 C unpressurized and 129.4 C with a 15 psi cap, freeze point -36.7 C. | Active supplier evidence for fluid type and limits; no thermophysical property table |
| `Radiator ppt.pptx` | `e1e3ee3ff3884ae3f2c11b142480fdbb812551fb1e952347c490f1930f00b962` | Motor cooling | 270 by 310 mm face, approximately 26 mm package depth, 31 flat tubes with 26 by 2 mm external cross-section and 2.8 mm fin pitch. | Unbuilt radiator candidate; the drawing does not specify tube-wall or fin-stock thickness and provides no performance map |
| `motor cooling.doc` | `4c7c9904f28f5f69853a032b9900bf4b0ecd305c77225604a32b4f1cf1177431` | Motor cooling | Supplier loop layout (pump, PDU/OBC/DCDC, MCU, motor, radiator; 20 mm hoses); MCU 13 kPa and motor 11 kPa at 16 L/min; PDU/OBC/DCDC water-resistance curve 2-16 L/min. | Active supplier evidence in `data/motor_cooling/component_pressure_drop.csv`; not corrected for coolant temperature |
| `DM18A1-B0423X-English.pdf` and `WRDT18101-DM18A1 technical specification.pdf` | `f1f00abf19d582371978e1ba0a4ef8d03832ccc3cea4e3bd70b2dfba97fbd278`, `7ccc6aeca2386860b96c6d9aa71950b2d77c501d9a5791bb5c12de7e380f7231` | Cabin cooling | R134a, 312 V: 2.9 kW at 6000 rpm (1.89 kW at 4000, 1.38 kW at 3000), 1.5 kW input, at 1.47 MPa(G) discharge and 0.196 MPa(G) suction. | Capacity reference on the cabin load; no compressor model |
| `power demand1.xlsx` | `6aac505d94f28e9d604bb751d20341fdc65afe3ace97e6754dda2b962d9b573f` | Motor heat | Sheet4 states 98% mechanical transmission efficiency (used as the reducer efficiency) and the archived L1-L7 battery heat (1.8 kW on L6 with 0.4 mOhm). | Reducer efficiency active; the load-case heat is a comparison baseline only |
| `TEMPERATUREsGFL 100Ah...xlsx` | `7d2f641c150a6a37e21b44260e511262eb7303edd6371d618b07c449cd00cdc7` | Battery cooling | Vendor 0.5C-3C discharge voltage and temperature of a 100 Ah LFP cell, resampled in `data/battery_cooling/gfl_100ah_rate_test.csv`. | Cross-check of the cell resistance only; a different cell, scaled by capacity |

## Preserved but not used as current-vehicle input

| Original file | Reason it is not active |
|---|---|
| `Motor Heat Generation NYCC.mat` | ADVISOR case for a 58 kW permanent-magnet motor and a 60 Ah NiMH battery, not the 125 kW LFP SUV. Its validation flags are zero. |
| `Heat generation estimation.pdf` | Earlier constant-efficiency Carsim estimates. Retained only as a historical baseline. |
| `cell load.xlsx` | Earlier constant C-rate workbook. It is excluded; the active battery module calculates a fresh sustained ACR-based screen from documented configuration values. |
| `The_Effect_of_Changes_in_Ambient_and_Coolant_Radia.pdf` | Copyrighted SAE paper. Cite the publisher record; do not redistribute the PDF. |

## Online primary references

| Reference | Use |
|---|---|
| [US EPA Dynamometer Drive Schedules](https://www.epa.gov/vehicle-and-fuel-emissions-testing/dynamometer-drive-schedules) | Official descriptions and one-hertz source files for NYCC and HWFET. The numerical sequences in the committed cycle files match the EPA files exactly. |
| [EPA HWFET source file](https://www.epa.gov/sites/default/files/2015-10/hwycol.txt) | Highway time-speed trace. |
| [EPA NYCC source file](https://www.epa.gov/system/files/other-files/2025-03/epa-new-york-city-cycle.txt) | Stop-start urban time-speed trace. |
| [SAE 2000-01-0579](https://doi.org/10.4271/2000-01-0579) | Radiator specific-dissipation sensitivity to inlet temperatures and controlled coolant flow. |
| [Gundem et al. 2021](https://doi.org/10.30939/ijastech..914901) | Experimental flat-tube automobile-radiator geometry: 2 by 26 mm tube outside dimensions, 0.2 mm tube wall and 0.1 mm fin thickness. The last two values are used only as screening assumptions for the unbuilt candidate. |
| [NREL Battery Pack Thermal Design](https://www.osti.gov/biblio/1304580) | Basis for combining thermal characterization, modeling and experimental validation. |
| [NASA POWER Data Access Viewer](https://power.larc.nasa.gov/docs/tutorials/data-access-viewer/quick-start/) | Future source for dated Karachi weather scenarios rather than treating one design ambient as a full climate record. |
| [MathWorks BEV thermal-management example overview](https://www.mathworks.com/videos/optimizing-a-battery-electric-vehicle-thermal-management-system-1743087942599.html) | Reference architecture for separating the electric powertrain, cabin, refrigerant circuit and coolant circuit before system-level coupling. |

Online charts and example models are referenced, not copied. Numerical data is
copied only from an official downloadable data file or from project evidence
whose role and limitation are recorded above.
