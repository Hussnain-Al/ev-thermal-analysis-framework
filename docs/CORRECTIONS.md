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
| Battery cell-to-coolant path | 0.458 K/W | 0.373-0.589 | 0.221-2.697 | 3.10 K/W | Superseded value is above the whole range | Holds at every extreme, narrowly at the worst case |
| Radiator UA, normal driving | 139.7 W/K | 125-161 | 93-201 | 665 W/K | Superseded value is above the whole range | Holds at every extreme |
| Winding-to-coolant resistance | 0.0331 K/W | not sampled | 0.0158-0.0514 | 0.015 K/W | Superseded value is below the whole range | Holds, narrowly at the low end |
| Cabin load, humid heat | 5.19 kW | 4.58-6.63 | 3.22-9.13 | 4.156 kW | Load exceeds the recorded subtotal | Holds within 5-95%, not at every extreme |

## 1. Battery cell-to-coolant path: 3.10 to 0.458 K/W

**Claim.** The path from cell to coolant is about seven times less resistive
than the reconstruction.

**Why 3.10 K/W fails.** With 3.10 K/W, a sustained 2C discharge would need
coolant at -29 C to keep the cell under 60 C. SVOLT rates the cell for 2C
continuous discharge at 25 C, so a pack built from it should not need coolant
below freezing. The value comes from the private source
`HEAT TRANSFER PHENOMENA INSIDE A MODULE.pdf` (see
[`SOURCE_PROVENANCE.md`](../references/SOURCE_PROVENANCE.md)). The repository
records the result but no element-by-element derivation that could be
checked.

**Derivation.** Series resistances for a cell cooled through its base:

| Element | Equation | Value (K/W) | Source |
|---|---|---:|---|
| Cell interior, mean | `H / (3 k A)` | 0.152 | SVOLT 220 x 44.6 x 112 mm; in-plane k 25 W/(m K) |
| Jelly roll to can base | `t / (k A)` | 0.153 | 0.3 mm polymer bottom insulator, 0.2 W/(m K) |
| Insulation film | `t / (k A)` | 0.076 | 0.15 mm PET, 0.2 W/(m K) |
| Thermal pad | `t / (k A)` | 0.008 | Project pad datasheet, 12.5 W/(m K), 1 mm |
| Cold-plate film | `1 / (h A)` | 0.068 | 1500 W/(m2 K) minichannel plate |
| **Total** | | **0.458** | |

The `H/(3kA)` term is the mean temperature rise of a slab with uniform heat
generation, an insulated top and a cooled base.

The jelly-roll-to-can-base row was missing from the first version of this
build-up (0.305 K/W). A defensibility review caught it: prismatic cans
carry a polymer insulator between the jelly roll and the base, and heat
cooled through the base must cross it.

**Robustness.** The worst combination gives 2.70 K/W. That includes the cell
standing on its narrow face (which halves the base area), the lowest
in-plane conductivity, a 0.5 mm insulator with a partial gas gap, the
thickest film, a 3 W/(m K) gap filler and a 800 W/(m2 K) plate. It stays
below 3.10 K/W, but only by 13%. So 3.10 K/W is not physically impossible;
it needs every element to be at its worst at once. The 5-95% band
(0.37-0.59 K/W) is the realistic spread. The largest single drivers are
orientation, the internal base insulator and the in-plane conductivity.

**What would overturn it.** A single-cell step test on the cold plate: apply a
known heat, record the cell and plate temperatures, and read the resistance
from the steady rise. A result above 1.7 K/W would mean an assembly defect
(air gap, uncompressed pad), not a property of the design.

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
Combined with the path samples, the allowable coolant temperature at 2C is
17.2-34.1 C (5-95%), against 27.7 C central and -29 C superseded.

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
| Max coolant for 60 C cell at 1C | 37.7 C | 48.5 C | 45.0-50.7 C (5-95%) |
| Max coolant for 60 C cell at 2C | -29.1 C | 27.7 C | 17.2-34.1 C (5-95%) |
| 10% grade, drive-unit peak after 20 min | 81.6 C | 98.55 C | Upper bound on winding |
| 10% grade, coolant peak after 20 min | 48.3 C | 53.9 C | |
| Low-speed grade, drive-unit peak after 30 min | 70.1 C | 84.3 C | Fan-only UA |
| Cabin subtotal from workbook | 4.16 kW | 2.69 kW | Deterministic audit |
| Cabin load at 45 C, humid heat | not calculated | 5.19 kW | 4.58-6.63 kW (5-95%) |

The battery result changes direction. Under the superseded inputs, 2C needed
refrigerated coolant below freezing. With the corrections, it needs coolant
below about 28 C (17-34 C across the band). A chiller can supply that;
ambient air at 45 C cannot. In the discharge transient, radiator-only coolant
at 50 C takes the cell to 60.0 C at 2C, exactly the absolute limit. The
decision that follows is "the battery loop needs a chiller in Karachi", not
"the cell cannot do 2C".

## Limits of the methods

A defensible result states where its method can be wrong and in which
direction. Each limit below was checked against the conclusions it could
affect.

| Method | Limit | Direction of error | Effect on the conclusion |
|---|---|---|---|
| Battery path build-up | 1-D series model; ignores lateral spreading into the cold plate and the plate's own wall | Underestimates the path slightly | Covered by the 800-3000 W/(m2 K) plate range; worst case still below 3.10 K/W |
| Battery path build-up | `H/(3kA)` gives the mean cell temperature; the core hot spot uses `H/(2kA)` | Core is about 0.08 K/W hotter than the mean | Limits apply to the measured surface or mean; add 0.08 K/W if the BMS limit is a core temperature |
| Battery path build-up | First version omitted the jelly-roll-to-can-base insulator | Underestimated the path by a third | Corrected in this version (0.305 to 0.458 K/W) |
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

## Remaining assumptions that were not corrected

The drive-unit (45 kJ/K) and coolant-loop (17.5 kJ/K) thermal capacitances
are still unidentified. They set how fast the two-node temperatures rise,
not where they settle. The 20- and 30-minute grade cases have not reached
steady state, so their peaks depend on these values. A coolant volume
measurement and one drive-unit warm-up test would identify both.
