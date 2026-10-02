# System thermal Simscape model

`build_system_thermal_simscape` builds all three loops of
`modules/system_thermal` as Simscape thermal networks (foundation library),
driven by one drive cycle. The battery's electrical side (current, state of
charge, Joule and entropic heat) and the compressor sharing are Simulink
blocks. CI builds and simulates it on all five cycles with the recommended
compressor (9.19 kW) and on L6 with the DM18A1 (2.9 kW), and requires every
temperature and the state of charge to match the MATLAB model within 1.
The current match is within 0.13 K and 0.05 points of SOC.

```matlab
cfg = setup_project();
results = run_all(cfg);
build_system_thermal_simscape(cfg,results.systemThermal, ...
    CycleStem="project_l6_continuous_grade",Capacity_kW=9.19,Overwrite=true);
```

| Part | Blocks | Value |
|---|---|---|
| Cabin | Thermal Mass | 40 kJ/K, starts at the 80 C hot soak |
| Cells | Thermal Mass | 108 x 2.42 kg x 1100 J/(kg K) = 287 kJ/K, starts at 45 C |
| Battery coolant and plates | Thermal Mass | 15 kJ/K (register S01), starts at 45 C |
| Cell-to-coolant path | Thermal Resistance | 1.033 K/W / 108 cells = 0.0096 K/W |
| Battery heat | Controlled Heat Flow Rate Source | `I = P_dc / 321 V` from the cycle; SOC integrated from 90%; `108 (I^2 x 0.571 mOhm - I x 298 K x dU/dT(SOC))` |
| Drive unit and its coolant | Thermal Mass x 2, Thermal Resistance | 45 and 17.5 kJ/K, 0.0340 K/W, both start at 45 C |
| Drive-unit heat | Controlled Heat Flow Rate Source | Cycle trace from `motor_heat` |
| Radiator | Controlled Heat Flow Rate Source | `UA max(T_coolant - 45 C, 0)`, 139.7 W/K (122.3 W/K fan-only) |
| Cabin net heat | Controlled Heat Flow Rate Source | Heat-balance load at cabin temperature minus evaporator duty |
| Chiller | Controlled Heat Flow Rate Source | Chiller duty, extracted from the coolant |
| Compressor allocation | Simulink | Each loop asks for its load plus 1 kW/K toward its set point (cabin 25 C, battery coolant 30 C); both are scaled by the same factor when the sum exceeds the capacity |

Requires Simulink and Simscape (no Simscape Fluids). The refrigerant circuit
is not modelled: the compressor is a capacity at the DM18A1 rating
condition.
