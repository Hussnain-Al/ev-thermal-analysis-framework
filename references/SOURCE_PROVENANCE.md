# Source Provenance

The calculation repository keeps reusable numerical inputs under `data/`.
Original project documents are retained locally under
`references/private_source_documents/` and excluded from Git because several
files contain vendor restrictions or a confidential marking.

## Active project evidence

| Original file | SHA-256 | Module | Use in the model | Status |
|---|---|---|---|---|
| `Torque Curves.xlsx` | `b2754378985acc4cb8dd657ffffb7032e3e1779af4e8050951130a0b532b7e71` | Motor heat | Original native torque-speed and power-speed charts; the committed workbook is byte-identical. | Active source |
| `125kw 3 in 1.pdf` | `2dd0de37d3b059185960a2b94c08e6138ace6ba16ecd94272c15decab2c183e7` | Motor heat and cooling | 125 kW integrated-drive ratings, efficiency contours, and winding-temperature reference cases. | Active digitized source; numerical map should be replaced by supplier data when available |
| `SVOLT 134Ah LFP Cell Specification (3).zh-CN.en (1).pdf` | `0fc47d3ab038cab54584a2045f9e04f448716be0e16ff8999f38812df9beb511` | Battery cooling | 134 Ah capacity, 3.2 V nominal voltage, 0.40 mOhm ACR limit, 2.420 kg mass, 60 C limit. | Active manufacturer evidence; ACR is only a heat-screening proxy |
| `HEAT TRANSFER PHENOMENA INSIDE A MODULE.pdf` | `8da01bd498a4a349a41f3aa4f97cbac9c9646a98c3692cb014e7eb792442e0cc` | Battery cooling | 3.10 K/W base path and 16.67 K/W inter-cell path. | Active reconstructed thermal network; not experimental validation |
| `Thermal_pad_data_sheet.pdf` | `3e10908a31f85319ffd3a217c4f4a2f9637e4e5e1d30dd24e6576f878f77c19d` | Battery cooling | Thermal-pad material reference, including 12.5 W/(m K) nominal conductivity. | Supporting manufacturer evidence |
| `Cabin Cooling Load(AutoRecovered).xlsx` | `7970276d972ee6856224057f24cff67981bda1ae5e0c0aa369c8759a282a2688` | Cabin cooling | Recovered body/glazing, occupant and infiltration sensible-load terms. | Active partial source; not a complete Karachi pull-down load |
| `WRDT18101-DM18A1 technical specification.pdf` | `7ccc6aeca2386860b96c6d9aa71950b2d77c501d9a5791bb5c12de7e380f7231` | Shared compressor | R134a capacity, power, current and COP table from 2000 to 6000 rpm. | Active manufacturer map |
| `TKU_PCE_L-English.pdf` | `6b7f3d1a0d2e11837f93eba07044e9797ed42d70daf27a8a3f9e26ca87d9b7f5` | Motor cooling | 20 L/min at 60 kPa screening point and inactive-pump resistance curve at 23 +/- 5 C. | Active manufacturer evidence; full active Q-H curve is missing |
| `Radiator ppt.pptx` | `e1e3ee3ff3884ae3f2c11b142480fdbb812551fb1e952347c490f1930f00b962` | Motor and battery cooling | Original propulsion and battery heat-exchanger geometry. | Active geometry only; no performance map |

## Preserved but not used as current-vehicle input

| Original file | Reason it is not active |
|---|---|
| `Motor Heat Generation NYCC.mat` | ADVISOR case for a 58 kW permanent-magnet motor and a 60 Ah NiMH battery, not the 125 kW LFP SUV. Its validation flags are zero. |
| `Heat generation estimation.pdf` | Earlier constant-efficiency Carsim estimates. Retained only as a historical baseline. |
| `cell load.xlsx` | Earlier constant C-rate calculation. Duty-cycle results are used for design screening. |
| `power demand1.xlsx` | Historical workbook with legacy assumptions and inconsistent load cases. |
| `TEMPERATUREsGFL 100Ah...xlsx` | Manufacturer discharge data for a 100 Ah cell, not the selected 134 Ah cell. |
| `The_Effect_of_Changes_in_Ambient_and_Coolant_Radia.pdf` | Copyrighted SAE paper. Cite the publisher record; do not redistribute the PDF. |

## Online primary references

| Reference | Use |
|---|---|
| [US EPA Dynamometer Drive Schedules](https://www.epa.gov/vehicle-and-fuel-emissions-testing/dynamometer-drive-schedules) | Official descriptions and one-hertz source files for NYCC and HWFET. The numerical sequences in the committed cycle files match the EPA files exactly. |
| [EPA HWFET source file](https://www.epa.gov/sites/default/files/2015-10/hwycol.txt) | Highway time-speed trace. |
| [EPA NYCC source file](https://www.epa.gov/system/files/other-files/2025-03/epa-new-york-city-cycle.txt) | Stop-start urban time-speed trace. |
| [SAE 2000-01-0579](https://doi.org/10.4271/2000-01-0579) | Radiator specific-dissipation sensitivity to inlet temperatures and controlled coolant flow. |
| [NREL Battery Pack Thermal Design](https://www.osti.gov/biblio/1304580) | Basis for combining thermal characterization, modeling and experimental validation. |
| [NASA POWER Data Access Viewer](https://power.larc.nasa.gov/docs/tutorials/data-access-viewer/quick-start/) | Future source for dated Karachi weather scenarios rather than treating one design ambient as a full climate record. |
| [MathWorks BEV thermal-management example overview](https://www.mathworks.com/videos/optimizing-a-battery-electric-vehicle-thermal-management-system-1743087942599.html) | Reference architecture for separating the electric powertrain, cabin, refrigerant circuit and coolant circuit before system-level coupling. |

Online charts and example models are referenced, not copied. Numerical data is
copied only from an official downloadable data file or from project evidence
whose role and limitation are recorded above.
