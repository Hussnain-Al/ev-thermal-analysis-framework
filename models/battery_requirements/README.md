# Battery requirements screen

This is not a coolant-loop model. It is a standalone requirements calculation
that stops at the battery-to-coolant boundary.

## Supported calculation

| Input | Output |
|---|---|
| Sustained C-rate | Current |
| Current, 0.571 mOhm DC resistance and peak entropic coefficient | Cell and pack heat |
| Cell heat and 1.03 K/W cell-to-coolant path | Required cell-to-coolant temperature difference |
| Required temperature difference and SVOLT limits | Maximum allowable coolant temperature |

The DC resistance is the 1 kHz ACR divided by 0.7. The entropic heat uses the
low-SOC peak. The path is a bottom-cooling build-up from the literature
register. All three come from `apply_literature_corrections`, and their
ranges are in [`docs/CORRECTIONS.md`](../../docs/CORRECTIONS.md). The model
computes the central estimate; the 5-95% band is computed in MATLAB by
`calculate_battery_requirements_screen`.

## Generate the Simulink model

Simulink is required. From the repository root:

```matlab
cfg = setup_project();
modelFile = build_battery_requirements_simulink(cfg,Overwrite=true);
open_system(modelFile);
```

The model has one input, `Sustained C-rate`, and six requirement outputs. It
contains no imposed coolant temperature, transient cell state, pump, radiator,
compressor or refrigeration circuit.

With Simulink available, compile-check the generated model using:

```matlab
run_battery_requirements_simulink_checks
```

## Simscape boundary

A physical cold-plate model is intentionally not generated yet. It requires:

- cell DCIR versus SOC and temperature;
- measured cell thermal capacity;
- validated cell-to-plate thermal response;
- cold-plate geometry and channel topology;
- coolant properties, inlet temperature and flow;
- plate heat-transfer and pressure-drop validation data.

Until those inputs exist, a Simscape temperature trace would be an assumed
scenario rather than a vehicle prediction.
