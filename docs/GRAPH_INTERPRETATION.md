# Graph interpretation

Every graph is limited to a quantity the available inputs can support.

| Figure | What is calculated or supplied | What it does not prove |
|---|---|---|
| Drive-unit thermal demand | Instantaneous loss from the efficiency map, trailing 60-second mean, cumulative heat energy and two sustained design duties | Motor temperature or radiator adequacy |
| Propulsion hydraulic evidence | Darcy-Weisbach loss for six external hoses and fittings; one documented active-pump reference point; one separately supplied stopped-pump resistance curve | Complete loop loss, active pump curve or operating point |
| Radiator requirement sensitivity | Required air flow, core-face velocity and ideal counterflow UA versus assumed air temperature rise | Delivered fan flow, ram-air capture or achieved radiator performance |
| Battery sustained screen | Minimum `I^2R` heat from the 1 kHz ACR limit and allowable coolant temperature from the reconstructed base path | DC/electrochemical heat, transient cell temperature or delivered cooling |

The two-node motor/coolant temperature output remains available only as an
uncalibrated parameter sensitivity. It is excluded from the README figures
because its thermal capacitances, motor-to-coolant resistance and radiator UA
have not been identified from test data.

The cabin workbook result is a recovered partial sensible-load subtotal. It is
not a cooling-loop simulation and is therefore also excluded from the README
figures.

The framework does not plot heat generated against cooling delivered. The first
is calculated from operating losses; the second requires a selected radiator
performance map or prototype test. Until that evidence exists, the defensible
output is the cooling requirement, not a fabricated compensation trace.
