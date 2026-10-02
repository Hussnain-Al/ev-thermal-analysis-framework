# Literature gap fill

Version `4.5.0` adds a separate estimate layer for the outputs that
[`MISSING_MODEL_INPUTS.md`](MISSING_MODEL_INPUTS.md) blocks. Every number it
adds lives in
[`data/literature/literature_assumption_register.csv`](../data/literature/literature_assumption_register.csv)
with a central value, a low/high range, a source and the project input it
stands in for. The evidence-based results are unchanged; the gap-fill results
are written to `outputs/literature_gap_fill/` and labelled as estimates.

The MATLAB module is `modules/literature_gap_fill/run_literature_gap_fill.m`.
[`tools/gap_fill_reference.py`](../tools/gap_fill_reference.py) is an
independent Python implementation of the same equations; the preview figures
under `docs/images/gap_fill/` were rendered by it and the MATLAB regression
checks assert the same values.

## What the gap fill changes in the conclusions

| Gap | Literature estimate | What it contradicts in the current model |
|---|---|---|
| Battery cell-to-coolant path | 0.30 K/W for a bottom-cooled prismatic cell | The reconstructed 3.10 K/W is about 10 times higher. That single value creates the "2C needs sub-zero coolant" result. |
| Battery heat | DCIR = ACR/0.7 plus entropic heat | Entropic heat at low SOC (about 15 W per cell at 1C) exceeds the ACR Joule floor (7 W). The ACR result is not a floor at low SOC. |
| Battery transient | Lumped cell, 2.66 kJ/K | With 25 C chiller coolant even the reconstructed path stays below 48 C during a full 2C discharge. The steady-state screen ignores the 2.3 h thermal time constant. |
| Radiator achieved performance | Chang-Wang louver j-factor, e-NTU | Estimated UA is 110 to 185 W/K between 1.5 and 8 m/s. The two-node model assumes 665 W/K, about four times more. The 10% grade duty needs about 6.2 m/s face velocity, not the 2.97 m/s from the ideal-UA calculation. |
| Radiator pressure drop | Laminar flat-tube friction | About 0.6 kPa at 20 L/min, a small share of the 38 kPa head left after the hoses. |
| Winding resistance | Back-calculated from the supplier 143 C rated reference | 0.017 to 0.043 K/W depending on the unknown rated speed. The configured 0.015 K/W is below the whole range. |
| Cabin workbook | Row-by-row recomputation | The body/glazing rows are overstated by about 1.46 kW (see audit below). |
| Cabin load | Heat-balance rebuild | 4.3 kW (dry heat) to 5.2 kW (humid heat) steady, plus 0.6 to 2.4 kW extra for a 30-minute pull-down. |
| Climate | 45 C with 25% or 44% RH | 45 C at 70% RH has a 38 C dew point, above any dew point ever recorded. |

## Gap fill 1: drive-unit operating points

<img src="images/gap_fill/gap_drive_operating_points.png" width="900" alt="Drive-cycle operating points over the integrated efficiency map and heat-energy density">

No new assumption. Motor and inverter papers show the drive cycle as a
scatter or energy-density map on top of the efficiency contours, because it
shows *where* the heat comes from. Here, highway heat is concentrated at
5000-7000 rpm and below 50 Nm. The digitized map has torque rows at 0, 25 and
50 Nm, and the 0 Nm row is a flat 50% placeholder. Below 25 Nm the heat
therefore comes from interpolating toward that placeholder. The low-torque
rows of the map matter more to cycle heat than its peak-efficiency island.

## Gap fill 2: winding-to-coolant resistance

<img src="images/gap_fill/gap_motor_resistance_calibration.png" width="900" alt="Winding resistance implied by the supplier rated temperature point">

The supplier reference gives 143 C winding with 60 C coolant at rated
conditions. Assuming rated output is the 60 kW controller point and
subtracting the 1.58 kW controller loss gives the motor-plus-reducer loss.
That loss divided by the 83 K rise is the implied winding-to-coolant
resistance. The rated speed is not stated, so it is swept. LPTN studies plot
winding hot-spot against coolant temperature with the insulation-class limit,
and the right panel follows that form. The full integrated loss is pushed
through the winding path, so the solid lines are upper bounds.

## Gap fill 3: radiator achieved performance

<img src="images/gap_fill/gap_radiator_performance_map.png" width="900" alt="Estimated heat rejection and UA against face velocity for the candidate core">

Supplier radiator maps plot heat rejection against air face velocity, with
one curve per coolant flow, at a fixed inlet temperature difference. This
figure uses the same form and overlays the two sustained duties. Air side:
Chang and Wang (1997) generalized louvered-fin correlation with assumed louver
pitch 1.0 mm, angle 27 degrees and length 0.85 of the fin height. Coolant side:
laminar flow (Re about 550) in the 25.6 by 1.6 mm tube bore, Nu 6.45. Coolant-side
resistance is 30 to 45% of the total. A turbulator or dimpled tube would change
the result more than any louver assumption would.

The ideal-UA requirement and the estimated UA are not compared at the same
air flow. At 6.2 m/s the air rises less than 10 K, so a lower UA meets the
duty. Read the left panel for the duty check.

## Gap fill 4 and 5: battery heat, path and transient

<img src="images/gap_fill/gap_battery_heat_and_path.png" width="900" alt="Battery heat terms, thermal resistance budget and coolant envelope">

<img src="images/gap_fill/gap_battery_discharge_transient.png" width="900" alt="Cell temperature during constant-current discharge at two coolant temperatures">

Battery thermal papers show three things: the Bernardi heat terms against SOC,
a thermal-resistance stack, and cell temperature against time for several
C-rates at fixed coolant inlet temperatures. The two figures follow that
layout.

The resistance build-up uses the SVOLT listing geometry (220 x 44.6 x 112 mm,
2.42 kg), in-plane jelly-roll conductivity, a PET wrap, the project thermal pad
(12.5 W/(m K)) and a cold-plate film coefficient. If the cell stands on its
220 mm face instead, the base area halves and the interior path doubles. The
total is then about 0.9 K/W, still a third of 3.10 K/W. Check whether the 3.10 K/W reconstruction
summed parallel paths in series, or used pad conductivity in place of a
contact conductance.

The radiator-only panel is the decision-relevant one for Karachi. Without a
chiller the coolant cannot fall below ambient, and at 2C the cell reaches the
55 C charge cutoff during the discharge.

## Gap fill 6: cabin workbook audit and heat-balance rebuild

<img src="images/gap_fill/gap_cabin_heat_balance.png" width="900" alt="Cabin workbook audit, heat-balance load breakdown and pull-down capacity">

The audit keeps every workbook input and recomputes each row:

- Glazing and door rows use `Q = U A SCL`. SCL is a solar cooling load in
  W/m2 and multiplies the shading coefficient, not `U`. Doors are opaque and
  take no SCL.
- The west rows repeat the east `Q` values even though their SCL is 112
  instead of 52.
- The CLTD correction `(78 - ti) + (tm - 85)` is the Fahrenheit form, but it is
  applied with 23 C and 38 C. The table CLTDs are Fahrenheit differences used
  as kelvin.
- The floor uses a roof CLTD (90 F) and contributes 1.42 kW, 42% of the
  subtotal.
- The workbook's outdoor temperature is 38.1 C, not the 45 C design boundary.

Fayazbakhsh and Bahrami (SAE 2013-01-1507) present cabin load as a stacked
breakdown by source, plus a pull-down transient. The rebuild uses that
breakdown with the workbook areas and U-values, ASHRAE clear-sky irradiance
for 15:00 on 21 June at 24.9 N, sol-air temperatures and fresh-air
psychrometrics. The pull-down panel shows mean capacity against target time
for three interior thermal masses. That mass is the least certain input.

## How to retire each assumption

| Register rows | Replace with |
|---|---|
| R01-R03, R06 | Louver drawing of the selected core, or a supplier heat-rejection map |
| B01-B02 | HPPC DCIR at 0, 25 and 45 C for the SVOLT cell |
| B10-B19 | Measured cell-to-plate step response (one heated cell on the plate) |
| B20-B21 | Cell mass and calorimetric specific heat |
| M01 | Rated speed and torque for the 143 C winding reference |
| C10-C25 | Soak and pull-down test of the vehicle, or a calibrated cabin CFD |
| K02-K03 | NASA POWER or PMD hourly records for Karachi, using coincident humidity |

## Sources

- Chang, Y.-J. and Wang, C.-C. (1997). A generalized heat transfer correlation
  for louver fin geometry. *Int. J. Heat Mass Transfer* 40(3), 533-544.
- Shah, R.K. and London, A.L. (1978). *Laminar Flow Forced Convection in
  Ducts*. Academic Press.
- Fayazbakhsh, M.A. and Bahrami, M. (2013).
  [Comprehensive Modeling of Vehicle Air Conditioning Loads Using Heat Balance Method](https://saemobilus.sae.org/content/2013-01-1507).
  SAE 2013-01-1507.
- ASHRAE Handbook Fundamentals: clear-sky model, occupant heat gains,
  glycol properties.
- [Battery Design: DCIR of a cell](https://www.batterydesign.net/battery-cell/dcir-of-a-cell/)
  (ACIR about 70% of 10 s DCIR).
- [Battery Design: thermal management and TIM](https://www.batterydesign.net/thermal/).
- [Entropic coefficient measurement for LFP](https://arxiv.org/pdf/2111.01776)
  and published LFP/graphite entropic profiles for the dU/dT shape.
- [Ministry of Climate Change: Karachi heat wave technical report, June 2015](https://mocc.gov.pk/SiteImage/Misc/files/Final%20Heat%20Wave%20Report%203%20August%202015.pdf)
  (44.8 C with a 66 C heat index).
- [SVOLT 134Ah cell listing](https://www.evlithium.com/LiFePO4-Battery/svolt-134ah-lifepo4-battery-cell.html)
  (dimensions and mass; confirm against the cell drawing).
