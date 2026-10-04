# System thermal Simscape model

`build_system_thermal_simscape` builds all three loops of
`modules/system_thermal` as Simscape thermal networks (foundation library),
driven by one drive cycle. The battery's electrical side (current, state of
charge, Joule and entropic heat) and the thermal management controls (PI
loops, cascade, compressor priority, derating) are Simulink blocks; see
[`docs/CONTROLS.md`](../../docs/CONTROLS.md). CI builds and simulates it on all five cycles with the recommended
compressor (7.57 kW) and on L6 with the DM18A1 (2.9 kW), and requires every
temperature to match the MATLAB model within 1 K, the state of charge within
0.5 points and the derate factor within 0.1. The current match is within
0.22 K, 0.03 points and 0.023.

```matlab
cfg = setup_project();
results = run_all(cfg);
build_system_thermal_simscape(cfg,results.systemThermal, ...
    CycleStem="project_l6_continuous_grade",Capacity_kW=7.57,Overwrite=true);
```

| Part | Blocks | Value |
|---|---|---|
| Cabin | Thermal Mass | 40 kJ/K, starts at the 80 C hot soak |
| Cells | Thermal Mass | 108 x 2.42 kg x 1100 J/(kg K) = 287 kJ/K, starts at 45 C |
| Battery coolant and plates | Thermal Mass | 19.3 kJ/K (register S01: BOM plate mass plus 3 L coolant), starts at 45 C |
| Cell-to-coolant path | Thermal Resistance | 1.033 K/W / 108 cells = 0.0096 K/W |
| Battery heat | Controlled Heat Flow Rate Source | `I = f P_dc / 321 V` (f = derate factor); SOC integrated from 90%; `108 (I^2 x 0.571 mOhm - I x 298 K x dU/dT(SOC))` |
| Winding and propulsion coolant | Thermal Mass x 2, Thermal Resistance | 9.0 kJ/K (supplier heating curve) and 53.5 kJ/K, 0.0340 K/W, both start at 45 C |
| Motor loss, controller loss | Controlled Heat Flow Rate Source x 2 | Cycle traces from `motor_heat` times f: motor loss into the winding, controller loss into the coolant |
| Radiator | Controlled Heat Flow Rate Source | `UA max(T_coolant - 45 C, 0)`, 139.7 W/K (122.3 W/K fan-only) |
| Cabin net heat | Controlled Heat Flow Rate Source | Heat-balance load at cabin temperature minus evaporator duty |
| Chiller | Controlled Heat Flow Rate Source | Chiller duty, extracted from the coolant |
| Cabin PI | Gain, Integrator, Sum, Saturation | Kp 667 W/K, Ki 1.59 W/(K s) from lambda tuning (60 s); back-calculation anti-windup |
| Battery-coolant PI with cascade | as above, plus Bias, Gain, Saturation | Kp 322 W/K, Ki 1.74 W/(K s); set point 30 C lowered by 2 K per K of cell above 40 C, floor 20 C |
| Compressor priority | Relay, Switch, MinMax | Battery first from 50 C cell until 48 C; otherwise cabin first; the other loop gets what is left |
| Derating | 1-D Lookup Table, MinMax, Switch, Product | BMS discharge 50-58 C, regen 45-53 C, motor 150-170 C winding; scales the requested power and losses |

Requires Simulink and Simscape (no Simscape Fluids). The refrigerant circuit
is not modelled: the compressor is a capacity at the DM18A1 rating
condition.
