# Corrections and their defence

Version `4.5.0` replaces six inputs that did not hold up. Each correction
below is argued the same way:

1. **Claim**: what changes and in which direction.
2. **Why the superseded value fails**: the specific defect, not a preference.
3. **Derivation**: how the new value follows from project evidence plus the
   sourced literature register.
4. **Robustness**: whether the claim survives the assumption ranges, tested
   three ways (described below).
5. **What would overturn it**: the measurement that settles it.

Every superseded value remains in the configuration under `superseded` and
is plotted next to its replacement. Nothing is deleted from the record.

## How robustness is tested

Every literature value lives in
[`data/literature/literature_assumption_register.csv`](../data/literature/literature_assumption_register.csv)
with a central value, a low/high range and a source. Each correction is then
tested in `modules/literature_gap_fill`:

| Test | Question it answers | Method |
|---|---|---|
| One at a time | Which assumption matters most? | Move one register row to its low and high value, all others central (tornado bars) |
| Combined extreme | Can any combination overturn the claim? | Set every row to whichever end pushes the result toward the superseded value |
| 5-95% band | What is the plausible spread? | 1024 Halton samples over triangular (low, central, high) distributions |

The Halton sequence is deterministic, so the bands reproduce exactly on
every run without a random seed or the Statistics toolbox. The combined
extreme is deliberately pessimistic: it stacks every worst case at once.
A claim that survives it is robust to the stated ranges. A claim that
survives only the 5-95% band is reported as such.

<img src="images/gap_fill/gap_correction_robustness.png" width="900" alt="Tornado charts showing each correction against its assumption ranges and superseded value">

| Correction | Adopted | 5-95% | Combined extreme | Superseded | Claim | Verdict |
|---|---:|---:|---:|---:|---|---|
| Battery cell-to-coolant path | 1.322 K/W | 0.990-1.464 | 0.590-2.473 | 3.10 K/W | Superseded value is above the whole range | Holds at every extreme; also an arithmetic error in the source network |
| Radiator UA, normal driving | 139.7 W/K | 125-161 | 93-201 | 665 W/K | Superseded value is above the whole range | Holds at every extreme |
| Winding-to-coolant resistance | 0.0331 K/W | not sampled | 0.0158-0.0514 | 0.015 K/W | Superseded value is below the whole range | Holds, narrowly at the low end |
| Cabin load, humid heat | 5.19 kW | 4.58-6.63 | 3.22-9.13 | 4.156 kW | Load exceeds the recorded subtotal | Holds within 5-95%, not at every extreme |

## 1. Battery cell-to-coolant path: 3.10 to 1.32 K/W

**Claim.** The project's own battery network, evaluated correctly, gives
1.32 K/W, not 3.10 K/W.

**Why 3.10 K/W fails.** The value comes from the project battery network
(`docs/images/battery_single_cell_equivalent.png`,
`battery_three_cell_equivalent.png`):

`R_path,3 = 1.69 + 0.0224 + 3 mm/(154 x 8.4e-3) + 0.33 + 0.6 mm/(154 x 8.4e-3) + 1/(400 x 4.8e-3) = 3.1 K/W`

Two errors are visible in that line:

- **The terms do not add up to 3.1.** They sum to 2.57 K/W.
- **R1, the "cell aluminium casing", is entered as 1.69 K/W.** A 0.8 mm
  aluminium wall (k 155 W/(m K)) over the 8.4e-3 m2 base is
  `0.8e-3/(155 x 8.4e-3) = 0.0006 K/W`, about 2800 times smaller. No layer of
  the stated casing can produce 1.69 K/W.

**Derivation.** Every term the network defines is kept with its own geometry
and values. R1 is recomputed from its stated thickness. The cell-internal
terms the network leaves out are added from literature:

| Element | Value (K/W) | Source |
|---|---:|---|
| Cell interior, mean `H/(3kA)` | 0.178 | 112 mm height, in-plane k 25 W/(m K), 8.4e-3 m2 base (network area) |
| Jelly roll to can base | 0.179 | 0.3 mm polymer insulator, 0.2 W/(m K) |
| Insulation film | 0.089 | 0.15 mm PET, 0.2 W/(m K) |
| R1 cell casing | 0.0006 | Network: 0.8 mm aluminium, recomputed |
| R2 thermal pad 1 | 0.022 | Network value |
| R3 module base plate | 0.002 | Network: 3 mm aluminium |
| R4 thermal pad 2 | 0.330 | Network value |
| R5 channel wall | 0.0005 | Network: 0.6 mm aluminium |
| R6 coolant convection | 0.521 | Network: h = 400 W/(m2 K) over 4.8e-3 m2 channel contact |
| **Total** | **1.322** | |

The network areas also fix the cell geometry used here: the 8.4e-3 m2 base
and 0.0224 m2 side imply a 200 x 42 x 112 mm cell standing upright. That
replaces the seller listing (220 x 44.6 x 112 mm) and removes orientation as
an uncertainty.

**What the derivation shows.** Thermal pad 2 and the channel convection are
64% of the path. They are design choices, not cell properties. A wider
channel contact (4.8e-3 to 8.4e-3 m2) and a thinner pad 2 are the levers.

**Robustness.** The combined extreme is 0.59-2.47 K/W and the 5-95% band is
0.99-1.46 K/W, so 3.10 K/W is above the whole range. The claim no longer
rests on the range, though: the sum error and the R1 unit error are
arithmetic and need no assumption.

**What would overturn it.** A single-cell step test on the module: apply a
known heat to one cell and read the resistance from the steady rise between
the cell base and the coolant.

## 2. Battery heat: ACR floor to DC resistance plus entropic heat

**Claim.** The 1 kHz ACR underestimates DC heat, and LFP cells add
reversible (entropic) heat that the screen ignored.

**Why ACR alone fails.** 1 kHz ACR excludes charge-transfer and diffusion
resistance, which act over the seconds-to-minutes timescales of driving. A
common rule of thumb puts ACR at about 70% of the 10 s DCIR. LFP/graphite
cells also have a negative entropic coefficient at low SOC (about -0.37 mV/K
near 5% SOC). That adds `-I T dU/dT`, about 15 W per cell at 1C, which is
more than the ACR Joule heat (7 W).

**Derivation.** `R_DC = 0.40 / 0.7 = 0.571 mOhm` at 25 C. The screen holds
both terms at their conservative values: 25 C resistance (resistance falls
as the cell warms) and the low-SOC entropic peak.

**Robustness.** The ACR/DCIR ratio range 0.5-0.9 gives 0.44-0.80 mOhm.
Combined with the path samples, the allowable coolant temperature at 1C is
22.5-35.1 C (5-95%), against 26.9 C central and 37.7 C superseded.

**What would overturn it.** HPPC pulses at 0, 25 and 45 C give DCIR directly;
an entropic coefficient measurement (OCV against temperature at several
SOC) gives `dU/dT` for this cell.

## 3. Radiator UA: 665 / 300 to 140 / 122 W/K

**Claim.** The candidate core cannot reach the UA the two-node model
assumed.

**Why 665 W/K fails.** It was a calibration guess with no geometry behind
it. The ideal-UA requirement for the 10% grade is 205 W/K. The model assumed
three times that, so it showed rejection the core cannot deliver.

**Derivation.** The candidate's own geometry (31 flat tubes, 2.8 mm fin pitch,
8 mm fins, 26 mm depth). Air side: the Chang and Wang (1997) louvered-fin
j-factor, with louver pitch, angle and length taken from the correlation's
database range. Fin efficiency for straight fins. Coolant side: laminar
flow (Re about 550) in the 25.6 by 1.6 mm bore, Nu 6.45 from Shah and London.
Combined by crossflow e-NTU. Normal driving is evaluated at 3.0 m/s face
velocity and fan-only at 2.0 m/s.

**Robustness.** The most favourable combination still gives 201 W/K: all
louver values at their best, Nu 7.28, +15% correlation scatter and 5 m/s face
velocity. That is a third of 665 W/K. At the adopted values the louver
Reynolds number is about 150 (fan-only) and 225 (normal driving), inside the
correlation's 100-3000 range. Only the corner of 1.5 m/s with 0.8 mm louver
pitch falls slightly below 100.

**What would overturn it.** A supplier heat-rejection map or a wind-tunnel
test of the selected core. A turbulator or dimpled tube would raise the
coolant-side coefficient, which is 30-45% of the total resistance.

## 4. Winding-to-coolant resistance: 0.015 to 0.0331 K/W

**Claim.** The supplier's own data imply a higher winding-to-coolant
resistance than assumed.

**Why 0.015 K/W fails.** It was an unexplained calibration value. The
supplier reports 143 C winding with 60 C coolant at the rated point. At
0.015 K/W, that 83 K rise would need 5.5 kW of motor loss. The efficiency
map gives about 2.5 kW at 60 kW output near base speed.

**Derivation.** `R = 83 K / (integrated loss - controller loss)` at 60 kW. The
integrated loss comes from the efficiency map at base speed (4192 rpm, the
corner of the supplied torque curve). The controller loss is the supplied
1.58 kW.

**Robustness.** The rated speed is not stated, so it is swept from 3000 to
9000 rpm. Together with a ±20% controller-loss uncertainty, the range is
0.0158-0.0514 K/W. The low end barely clears 0.015 K/W, so the claim
holds, but only narrowly if the rated point were at 3000 rpm. This value is
a hot-spot resistance. Pushing the full integrated loss (including the
inverter and reducer) through it makes the drive-unit temperature an upper
bound on the winding.

**What would overturn it.** The rated speed and torque behind the 143 C figure,
or a thermocouple step test on the stator.

## 5. Cabin load: workbook audit and heat-balance rebuild

**Claim.** The recovered workbook subtotal is mis-computed. A complete
heat balance at 45 C gives a higher load.

**Why the workbook fails.** Five independent defects, each visible in the
spreadsheet cells:

| Defect | Rows | Effect |
|---|---|---|
| `Q = U A SCL`: SCL multiplied by U instead of the shading coefficient | All glazing and doors | Dimensionally wrong |
| Doors given a solar cooling load | Doors | Opaque surfaces take conduction only |
| West rows copy the east Q values | West glazing and doors | West SCL is 112, not 52 |
| Fahrenheit CLTD correction `(78-ti)+(tm-85)` used with Celsius temperatures | All opaque rows | Wrong correction; table CLTDs used as kelvin |
| Floor given a roof CLTD (90 F) | Floor | 1.42 kW, 42% of the subtotal |

Recomputing every row with the workbook's own inputs gives 1.87 kW instead
of 3.34 kW for body and glazing, so the corrected subtotal is 2.69 kW, not
4.16 kW. The workbook's outdoor temperature is also 38.1 C, not the 45 C
design boundary. The workbook file is not edited (it is hashed source
evidence); `audit_cabin_workbook` performs the recomputation.

**Derivation.** The heat-balance structure of Fayazbakhsh and Bahrami (SAE
2013-01-1507), using the workbook areas and U-values: sol-air conduction,
glazing conduction, transmitted and absorbed solar (ASHRAE clear-sky
irradiance for 15:00 on 21 June at 24.9 N), road-side floor, occupant
sensible and latent heat, fresh-air sensible and latent heat, and internal
gains. The result is 4.31 kW in dry heat and 5.19 kW in humid heat.

**Robustness.** The claim holds within the 5-95% band (4.58-6.63 kW, all
above 4.16 kW) but not at the combined extreme (3.22 kW). The fresh-air rate
dominates the spread: 2.5-10 L/s per occupant moves the load by 2.8 kW.
The audit findings do not depend on any assumption.

**What would overturn it.** A measured fresh-air rate for the HVAC recirculation
setting, then a soak and pull-down test.

## 6. Design humidity: 70% to 44% RH at 45 C

**Claim.** 45 C at 70% RH cannot occur.

**Why it fails.** That pairing has a 38.3 C dew point. The highest dew point
ever recorded is about 35 C.

**Derivation.** The June 2015 Karachi heat wave peaked at 44.8 C with a 66 C
heat index (Ministry of Climate Change technical report). The Rothfusz
heat-index equation inverts this to 44% RH, a 30 C dew point. A 25% RH dry-heat
case brackets the other side.

**What would overturn it.** Hourly coincident temperature and humidity records
for Karachi (PMD or NASA POWER), used to pick a design condition by
exceedance frequency.

## Consequences for the results

| Result | Superseded | Corrected | Spread |
|---|---:|---:|---|
| Max coolant for 60 C cell at 1C | 37.7 C | 26.9 C | 22.5-35.1 C (5-95%) |
| Max coolant for 60 C cell at 2C | -29.1 C | -33.4 C | -47.3 to -9.1 C (5-95%) |
| Sustained C-rate at the project's 30 C coolant | 1.16C | 0.93C | |
| 10% grade, drive-unit peak after 20 min | 81.6 C | 98.55 C | Upper bound on winding |
| 10% grade, coolant peak after 20 min | 48.3 C | 53.9 C | |
| Low-speed grade, drive-unit peak after 30 min | 70.1 C | 84.3 C | Fan-only UA |
| Cabin subtotal from workbook | 4.16 kW | 2.69 kW | Deterministic audit |
| Cabin load at 45 C, humid heat | not calculated | 5.19 kW | 4.58-6.63 kW (5-95%) |

With the corrected path and heat, the pack cannot sustain 2C at any
practical coolant temperature, and at the project's 30 C design coolant it
sustains about 0.93C. That covers the drive cycles and the 10% grade
(0.72C), but not archived load case L6 (1.52C mean). The design question is
the channel and pad 2, not the cell.

## Limits of the methods

A defensible result states where its method can be wrong and in which
direction. Each limit below was checked against the conclusions it could
affect.

| Method | Limit | Direction of error | Effect on the conclusion |
|---|---|---|---|
| Battery path build-up | 1-D series model; ignores lateral spreading in the base plate beyond the channel contact | Overestimates the path slightly | Conservative; the inter-cell paths (16.67 K/W each) carry no net heat when neighbouring cells are equally loaded |
| Battery path build-up | `H/(3kA)` gives the mean cell temperature; the core hot spot uses `H/(2kA)` | Core is about 0.09 K/W hotter than the mean | Limits apply to the measured surface or mean; add 0.08 K/W if the BMS limit is a core temperature |
| Battery path build-up | Earlier versions used literature plate values and omitted the project's base plate and pad 2 | Underestimated the path by a factor of three | Corrected: the path now follows the project network (1.32 K/W) |
| DC resistance | ACR/0.7 is a rule of thumb from one practitioner source | Unknown sign | Range 0.5-0.9 is carried in the 5-95% band |
| Entropic heat | Uses the low-SOC peak for every sustained C-rate and for charging | Overestimates heat at mid SOC; over-conservative for charging | Conservative; the 55 C charge line is pessimistic |
| Entropic profile | Generic LFP/graphite shape, not measured on this cell | Unknown sign | Only the peak magnitude enters the screen |
| Winding calibration | Supplier point measured at 8 L/min; model runs at 20 L/min | Overestimates R at 20 L/min | Conservative for winding temperature |
| Winding calibration | Reducer loss counted as winding-path loss | Underestimates R | Partly offsets the line above; covered by the 3000-9000 rpm sweep |
| Winding calibration | Assumes the 143 C rated rise is a steady state | Unknown until the duration is confirmed | Disclosed as an open input |
| Radiator estimate | Chang-Wang correlation assumes louvered fins; the drawing does not say | If the fins are plain, the UA is lower | Strengthens the claim that 665 W/K is unreachable |
| Radiator estimate | Face velocities of 2-3 m/s are screening values, not measurements | Unknown sign | Even 8 m/s with every favourable value, including +15% correlation scatter, gives 226 W/K |
| Cabin heat balance | Single steady hour (15:00), lumped cabin, no seat or trim storage in the steady load | Unknown sign | Fresh-air rate dominates the spread; the claim holds only within the 5-95% band |
| Cabin pull-down | Mean energy over the pull-down, not a transient simulation | Underestimates the initial peak | Shown as a range over thermal mass, not a compressor size |
| Workbook audit | Recomputes the workbook's own building-CLTD method, which is not a vehicle method | None for the audit | The audit shows the arithmetic errors; the heat balance replaces the method |
| Humidity | Rothfusz heat-index inversion is extrapolated at 66 C heat index | About +/-6% RH | Register range 40-50% RH; the 70% RH rejection does not depend on it |
| Uncertainty bands | Triangular distributions assumed independent | Correlated inputs would widen or narrow the band | Claims are also tested at the combined extreme, which needs no distribution |

## Project data that had not been used

A review of every file in the repository and its history found project
evidence the earlier versions of this layer ignored:

| Source | Data | Use now |
|---|---|---|
| Battery network figures (`docs/images/battery_*`) | Pack layer stack, areas, pad 2, channel h and contact area | Battery path (section 1) |
| Archived load cases L1-L7 (git history) | Motor power and pack current per case | Pack voltage under load, 314-336 V (mean 321 V) instead of 345.6 V nominal |
| Archived load case L6 | 8% continuous grade, full 350 kg load, 61.5 kW at the wheel | New operating case (85.2 km/h, solved from road load) |
| Archived DM18A1 compressor | 3.63 kW at 4 C evaporating, R134a | Reference line on the cabin load |
| Archived battery config | 30 C coolant, cooling on at 35 C, 900 J/(kg K) cell specific heat | 30 C used as the design coolant check; 900 J/(kg K) is now the low end of the register range |

The supplier PDFs themselves (SVOLT, 125 kW drive unit, pump, radiator,
thermal pad) are not in the repository; only the values recorded in
`references/SOURCE_PROVENANCE.md` and the derived CSVs are.

## Checks against the project's own references

`modules/literature_gap_fill` writes `reference_checks.csv`:

| Check | Reference | Model | Finding |
|---|---:|---:|---|
| Drive unit after 30 s at 125 kW peak, from 60 C | 103 C (supplier) | 69.2 C | The two-node model is too slow for 30 s peaks. Use it for minutes-long duties only |
| Winding thermal capacitance | 9.8 kJ/K implied by the supplier peak | 45 kJ/K assumed | The lumped value is the whole unit; the winding behaves like about a fifth of it |
| Cell rise, 1C for 600 s (adiabatic) | SVOLT limit 15 C | 2.1 C | Consistent; reaching the limit would need 3.7 mOhm, so it does not test the resistance |
| Cell rise, 3C for 30 s (adiabatic) | SVOLT limit 10 C | 1.0 C | Consistent; not a discriminating test |
| Cabin load, humid heat | DM18A1 3.63 kW | 5.19 kW | The archived compressor is below the cabin load before any battery chiller duty |

The compressor finding is the most consequential. On L6 the battery adds
2.5-6.2 kW of chiller duty on top of the cabin, so cabin plus battery reaches
7.6-11.4 kW against 3.63 kW.

## Remaining assumptions that were not corrected

The drive-unit (45 kJ/K) and coolant-loop (17.5 kJ/K) thermal capacitances
are still unidentified. They set how fast the two-node temperatures rise,
not where they settle. The 20- and 30-minute grade cases have not reached
steady state, so their peaks depend on these values. A coolant volume
measurement and one drive-unit warm-up test would identify both.
