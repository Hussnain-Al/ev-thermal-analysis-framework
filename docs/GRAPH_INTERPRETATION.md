# Graph interpretation

Every graph is limited to a quantity the available inputs can support.

| Figure | What is calculated or supplied | What it does not prove |
|---|---|---|
| Drive-unit thermal demand | Instantaneous loss from the efficiency map, trailing 60-second mean, cumulative heat energy and two sustained design duties | Motor temperature or radiator adequacy |
| Propulsion hydraulic evidence | Darcy-Weisbach loss for six external hoses and fittings; one documented active-pump reference point; one separately supplied stopped-pump resistance curve | Complete loop loss, active pump curve or operating point |
| Radiator requirement sensitivity | Required air flow, core-face velocity and ideal counterflow UA versus assumed air temperature rise | Delivered fan flow, ram-air capture or achieved radiator performance |
| Battery sustained screen | DC Joule plus peak entropic heat and allowable coolant temperature across the 0.458 K/W path, with a 5-95% band and the superseded result | Transient cell temperature or delivered cooling |
| Correction robustness | One-at-a-time tornado, combined worst case and 5-95% band for each correction | That the literature values are right for this vehicle; only that the conclusion survives their ranges |

The two-node motor/coolant output now uses a calibrated winding resistance and
an estimated core UA. Its thermal capacitances are still assumptions, so the
20- and 30-minute peaks depend on them. The drive-unit node is an upper bound
on winding temperature.

The cabin figure shows the workbook subtotal as recorded and as recomputed,
beside the heat-balance load for two humidity scenarios. It is a steady load,
not a cooling-loop simulation.

The framework does not plot heat generated against cooling delivered. The first
is calculated from operating losses; the second requires a selected radiator
performance map or prototype test. Until that evidence exists, the defensible
output is the cooling requirement, not a fabricated compensation trace.
