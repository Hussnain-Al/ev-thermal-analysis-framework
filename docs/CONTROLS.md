# Thermal management controls

The closed-loop system model (`src/calculations/simulate_system_thermal.m`,
run by `modules/system_thermal`) and its Simscape twin
(`models/system_thermal`) carry the same controller. This page explains what
each part does, how its gains are chosen and what it shows.

## Architecture

| Loop | Measured | Actuator | Law |
|---|---|---|---|
| Cabin | Cabin air temperature | Evaporator duty | PI, set point 25 C |
| Battery coolant (inner) | Battery coolant temperature | Chiller duty | PI, set point from the outer loop |
| Cell temperature (outer) | Mean cell temperature | Battery coolant set point | Proportional, 30 C nominal, floor 20 C |
| Compressor arbitration | Mean cell temperature | Which loop is served first | Relay with hysteresis, 50 C on and 48 C off |
| BMS derating | Mean cell temperature | Discharge and regen power | Linear ramp, discharge 50-58 C, regen 45-53 C |
| Motor derating | Winding temperature | Traction power | Linear ramp, 150-170 C |

The plant is five lumped thermal nodes: cabin, cells, battery coolant and
plates, motor winding, and propulsion coolant. The drive cycle sets the
requested DC power and the motor and controller losses each second. The
compressor is a capacity at the DM18A1 rating condition, so the controllers
command duties (W), not compressor speed.

## Tuning: lambda (IMC) method

Both PI loops act on a first-order thermal plant. Around its operating point
each loop is

```text
C dT/dt = -u + G (T_drive - T)
```

where `u` is the cooling duty, `C` the node capacitance and `G` the
conductance that pulls the node toward its driving temperature. From `u` to
`T` this is `-1/(C s + G)`, a single pole at `-G/C`.

With the PI `u = Kp e + Ki ∫e dt` on the error `e = T - T_set`, choosing

```text
Ti = Kp/Ki = C/G     (the integral time cancels the plant pole)
Kp = C/lambda
Ki = G/lambda
```

makes the open loop `1/(lambda s)` and the closed loop `1/(lambda s + 1)`:
a first-order response with time constant `lambda`, no overshoot and no
steady-state error. Only `lambda` is a design choice; the gains follow from
the plant (`out.controllerGains`, `controller_gains.csv`):

| Loop | C | G | lambda | Kp | Ki |
|---|---:|---:|---:|---:|---:|
| Cabin | 40 kJ/K (interior mass) | 95.6 W/K (slope of the heat-balance load at 25 C) | 60 s | 667 W/K | 1.59 W/(K s) |
| Battery coolant | 19.3 kJ/K (BOM plates plus coolant) | 104.5 W/K (1/R, cells to coolant) | 60 s | 322 W/K | 1.74 W/(K s) |

The cabin plant gain comes from the same heat-balance model that sets the
load, evaluated at 24 and 26 C, so a change to the cabin model retunes the
controller.

## Anti-windup: back-calculation

During the pull-down the cabin loop asks for far more than the compressor
can give, and when the battery has priority it gets less than it asks for.
A plain integrator keeps integrating through that and overshoots afterwards.
An earlier version clamped the integrator to [0, capacity]; the cabin then
sat 0.4 K under its set point for minutes after the pull-down, because the
integrator held a full-capacity value it had to unwind slowly.

The integrator is now driven by

```text
dI/dt = Ki e + (u_delivered - u_unsaturated) / Ti
```

so whenever the loop gets less than it asks for, the integrator is pulled
back to what is achievable. The tracking time is the integral time `Ti`, the
usual choice. With it the cabin holds 25.0 C (within 0.03 K) after the
pull-down on every cycle.

## Cascade on cell temperature

A fixed 30 C coolant set point cannot hold L6: the cells settle near 54 C,
because the cell-to-coolant path (0.0096 K/W for the pack) limits the heat
flow, not the compressor. The outer loop lowers the coolant set point as the
cells warm:

```text
T_set,coolant = clamp(30 - 2 (T_cell - 40), 20, 30)   [C]
```

The inner loop is fast (lambda 60 s); the cells respond with the pack time
constant `C_cell R_pack` = 287 kJ/K x 0.0096 K/W = about 2750 s. The factor of
about 45 between them is what lets the two loops be designed separately. The
20 C floor is a condensation limit: the 45 C / 44% RH design day has a 30 C
dew point, so colder coolant risks water in a pack that is not sealed and
dried.

## Compressor priority

Normally the cabin is served first and the chiller gets what is left. From
50 C cell (5 K under the 55 C charge cut-off) the chiller is served first
until the cells are back at 48 C. The 2 K hysteresis stops the priority
flipping every few seconds near the threshold.

## Derating

The BMS limits are the SVOLT operating limits with margins: discharge power
falls linearly from 100% at 50 C to zero at 58 C (2 K under the 60 C limit);
regen falls from 45 C to zero at 53 C (2 K under the 55 C charge cut-off).
The motor falls from 150 C winding (the hot-spot target) to zero at 170 C
(10 K under the class H limit). The applied factor is the smaller of the BMS
and motor factors. The model has no driver that slows down when power is cut,
so the undelivered traction power is reported instead.

## What the closed loop shows

| | DM18A1, 2.9 kW | Recommended, 7.57 kW |
|---|---|---|
| Cabin | Never within 2 K of 25 C; 38 C on most cycles, 72 C on L6 | Within 2 K after 6.5 min; holds 25.0 C |
| L6 cells | 50.7 C peak, with priority for 21 min of 30 and 2.1% of traction energy not delivered | 49.7 C peak; no derating; coolant set point down to 20 C |
| Mean compressor use on L6 | 100% | 98% |
| HWFET regen | Cut to 78% when the cells pass 46.8 C | 98% |

The small compressor can protect the cells only by giving up the cabin, which
is the trade the priority logic makes explicit. The recommended size runs at
98% on L6, so it is just enough.

## How it is checked

- `tests/run_sanity_checks.m` checks that the gains equal `C/lambda` and
  `G/lambda`, that the cabin ends within 0.05 K of its set point, that the
  cascade stays above its floor, and the L6 priority time, unmet energy and
  peak temperatures.
- `tests/run_system_thermal_simscape_checks.m` builds the Simscape model with
  the same controllers in Simulink blocks (Integrator, Relay, Switch, 1-D
  Lookup Table) and simulates all five cycles with a variable-step solver. It
  matches the 1 s MATLAB model within 0.22 K, 0.03 points of SOC and 0.023 on
  the derate factor, so the controller does not depend on how it is
  integrated.

## Limits

- The compressor is a capacity, not a speed-controlled machine with an
  evaporator and an expansion valve, so compressor and refrigerant dynamics
  are not modelled.
- The controllers are continuous, with no sensor lag, noise or sample time.
  Real ECUs run at 10-100 ms, far faster than these loops, so this matters
  little for lambda = 60 s.
- The PI loops are tuned on linearised plants. The cabin load is slightly
  nonlinear (latent load) and the battery loop sees the cells as a slow
  disturbance; the closed-loop results above include both.
- Derating scales the losses with the delivered power at the requested
  operating point's efficiency.
