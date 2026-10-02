# System thermal Simscape model

`build_system_thermal_simscape` builds the coupled cabin and battery loops of
`modules/system_thermal` as a Simscape thermal network (foundation library),
with the compressor allocation in Simulink. CI builds it, simulates the L6
cycle with the DM18A1 (2.9 kW) and the recommended compressor (9.19 kW), and
requires every temperature to match the MATLAB model
(`simulate_system_thermal`) within 1 K. The current match is within 0.04 K.

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
| Battery heat | Controlled Heat Flow Rate Source | Drive-cycle trace from `battery_cooling` |
| Cabin net heat | Controlled Heat Flow Rate Source | Heat-balance load at cabin temperature minus evaporator duty |
| Chiller | Controlled Heat Flow Rate Source | Chiller duty, extracted from the coolant |
| Compressor allocation | Simulink | Each loop asks for its load plus 1 kW/K toward its set point (cabin 25 C, battery coolant 30 C); both are scaled by the same factor when the sum exceeds the capacity |

Requires Simulink and Simscape (no Simscape Fluids). The refrigerant circuit
is not modelled: the compressor is a capacity at the DM18A1 rating
condition. The propulsion loop has its own radiator and is modelled by
`propulsion_thermal_sensitivity`.
