# Methodology

## Motor heat

Vehicle speed gives acceleration, wheel speed, drive-unit speed, road force,
grade force and wheel power. The original torque/power workbook defines the
operating envelope. A digitized integrated motor/inverter/reducer map gives
efficiency and drive-unit heat by energy balance.

NYCC and HWFET are supplemented by a 20-minute 10% grade at 40 km/h and a
30-minute 5% grade at 15 km/h, both at 45 C ambient. Drive schedules are
reported as one-second heat, trailing 60-second mean heat and cumulative heat
energy. The sustained cases are reported as constant design points rather than
as artificial flat transient traces.

## Motor and coolant transient

The two thermal states are:

\[
C_m\frac{dT_m}{dt}=\dot Q_{drive}-\frac{T_m-T_c}{R_{mc}}
\]

\[
C_c\frac{dT_c}{dt}=\frac{T_m-T_c}{R_{mc}}-UA\max(T_c-T_a,0)
\]

`R_mc` is calibrated on the supplier rated point: 143 C winding with 60 C
coolant at 60 kW. At base speed (4192 rpm) the efficiency map gives the
integrated loss; subtracting the 1.58 kW controller loss gives
`R_mc = 83 K / 2.51 kW = 0.0331 K/W`. `UA` is the Chang-Wang estimate for the
candidate core: 139.7 W/K at 3.0 m/s face velocity, 122.3 W/K fan-only at
2.0 m/s. `C_m` and `C_c` remain assumptions. Because the full integrated
loss crosses the winding resistance, the drive-unit node is an upper bound
on winding temperature. See [`CORRECTIONS.md`](CORRECTIONS.md).
The 83.5 kg three-in-one drive-unit mass is known. Its 45 kJ/K thermal
capacitance corresponds to an assumed effective specific heat of about
539 J/(kg K); the complete assembly is not treated as solid ADC12.

Darcy-Weisbach and fitting losses define the six-hose system curve. Motor,
controller, PDU and radiator pressure drops are excluded. The 60 kPa documented
pump reference is therefore compared only with the modeled hose requirement.
The supplied stopped-pump resistance curve is plotted separately as passive
loss evidence; it is not an active pump curve and cannot define an operating
point.

## Radiator and fan requirements

The retained 270 by 310 by approximately 26 mm core is treated as an unbuilt
design candidate. Its flat tubes have a 26 by 2 mm external cross-section; the
2 mm value is not interpreted as wall thickness. Literature values of 0.2 mm
tube wall and 0.1 mm fin thickness are stored as screening assumptions but are
not used to predict achieved `UA`.
For the sustained-grade and low-speed hot-weather duties, coolant outlet
temperature follows the coolant energy balance. Air mass flow follows:

\[
\dot m_a=\frac{\dot Q}{c_{p,a}(T_{a,out}-T_{a,in})}
\]

Required `UA` uses an ideal counterflow LMTD. Required air volume flow is divided
by candidate frontal area to obtain required core-face velocity. Both quantities
are requirements, not delivered performance. Air-temperature-rise sensitivity
from 5 to 15 C exposes the boundary-condition dependence. Vehicle speed is not
converted to core airflow because no installation or fan model is available.

## Battery sustained screen

The battery module is independent of drive cycles. For sustained C-rate `C`:

\[
I=134C,\qquad \dot Q_{cell}=I^2R_{DC}+I\,T_{ref}\left|\frac{dU}{dT}\right|_{peak}
\]

\[
T_{coolant,max}=T_{limit}-\dot Q_{cell}R_{cell\to coolant}
\]

`R_DC = 0.40/0.7 = 0.571 mOhm` at 25 C converts the SVOLT 1 kHz ACR to a DC
value. The entropic term uses the low-SOC peak of 0.37 mV/K. Both are held
at their conservative values. `R_cell-to-coolant = 1.32 K/W` follows the
project battery network R1-R6 (casing, pad 1, 3 mm base plate, pad 2,
channel wall, 400 W/(m2 K) over 4.8e-3 m2) with R1 recomputed from its
stated 0.8 mm aluminium, plus cell interior, base insulator and PET wrap. The
5-95% band comes from 1024 Halton samples over the register ranges. The
superseded ACR/3.10 K/W result is plotted for comparison. A lumped-cell
discharge transient is in `modules/literature_gap_fill`.

## Battery heat over the drive cycles

Pack current is `I = P_dc / V_pack` from the drive unit's DC-link power
(negative during regen), with `V_pack = 321 V`, the loaded voltage implied by
archived load cases L1-L7 (314 V for the highest-possible bound). SOC is
integrated from 90%. Expected heat per cell is
`I^2 R_DC(25 C) - I T dU/dT(SOC)`; highest possible heat per cell is
`I^2 R_DC,high + |I| T |dU/dT|peak`. The cycles are chosen with
`cfg.batteryCooling.cycleSelection`. A fixed loaded voltage is used instead
of an OCV curve; LFP voltage is flat between 10% and 90% SOC.

## Cabin load

The surface-load subtotal is read from the recovered Excel workbook and checked
against the derived input table. `audit_cabin_workbook` then recomputes each
row consistently (SCL with the shading coefficient, opaque doors, west SCL,
SI CLTD correction), giving 2.69 kW instead of the recorded 4.16 kW. The
cabin load itself comes from a heat-balance rebuild at 45 C:
sol-air conduction, glazing conduction and solar gain from ASHRAE clear-sky
irradiance, floor, occupants and fresh air with psychrometrics. The coincident
humidity is 44% RH (2015 heat-wave peak) or 25% RH (dry heat).

## Validation target

Future measurements should identify motor thermal capacitance,
motor-to-coolant resistance, radiator performance, coolant volume, flow and
pressure loss. Battery work requires DC resistance or calorimetric heat and a
measured cell-to-coolant thermal response.
