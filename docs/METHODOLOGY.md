# Methodology

## Motor heat

Vehicle speed gives acceleration, wheel speed, drive-unit speed, road force,
grade force and wheel power. The original torque/power workbook defines the
operating envelope. A digitized integrated motor/inverter/reducer map gives
efficiency and drive-unit heat by energy balance.

NYCC and HWFET are supplemented by a 20-minute 10% grade at 40 km/h and a
30-minute 5% grade at 15 km/h, both at 45 C ambient.

## Motor and coolant transient

The two thermal states are:

\[
C_m\frac{dT_m}{dt}=\dot Q_{drive}-\frac{T_m-T_c}{R_{mc}}
\]

\[
C_c\frac{dT_c}{dt}=\frac{T_m-T_c}{R_{mc}}-UA\max(T_c-T_a,0)
\]

`C_m`, `C_c`, `R_mc` and `UA` are exposed calibration assumptions. The model
reports temperatures and energy balance but issues no component pass/fail.
The 83.5 kg three-in-one drive-unit mass is known. Its 45 kJ/K thermal
capacitance corresponds to an assumed effective specific heat of about
539 J/(kg K); the complete assembly is not treated as solid ADC12.

Darcy-Weisbach and fitting losses define the six-hose system curve. Motor,
controller, PDU and radiator pressure drops are excluded. The 60 kPa documented
pump point is therefore compared only with the modeled hose requirement.

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

Required `UA` uses an ideal counterflow LMTD. At zero road speed the fan must
provide the complete required air volume flow. At vehicle speed, `A_core v`
is reported only as an ideal geometric face-flow bound. No installation-loss
or fan operating-point model is included.

## Battery sustained screen

The battery module is independent of drive cycles. For sustained C-rate `C`:

\[
I=134C,\qquad \dot Q_{cell}=I^2R_{ACR}
\]

\[
T_{coolant,max}=T_{limit}-\dot Q_{cell}R_{base}
\]

`R_ACR = 0.40 mOhm` is the only available resistance and is a minimum heat
proxy. The model uses the SVOLT 55 C charging cutoff and 60 C absolute limit.
It does not calculate transient cell temperature or delivered cooling.

## Cabin load

The surface-load subtotal is read from the recovered Excel workbook and checked
against the derived input table. The module then adds the recovered occupant
and infiltration terms. It remains an independent partial sensible-load result.

## Validation target

Future measurements should identify motor thermal capacitance,
motor-to-coolant resistance, radiator performance, coolant volume, flow and
pressure loss. Battery work requires DC resistance or calorimetric heat and a
measured cell-to-coolant thermal response.
