# Battery loop model

This folder contains the first standalone loop model. It deliberately stops at
the battery-to-coolant requirement boundary.

## Supported calculation

| Input | Output |
|---|---|
| Sustained C-rate | Current |
| Current and 0.40 mOhm ACR limit | Minimum cell and pack heat |
| Cell heat and reconstructed 3.10 K/W base path | Required cell-to-coolant temperature difference |
| Required temperature difference and SVOLT limits | Maximum allowable coolant temperature |

The ACR value is measured at 1 kHz, 25 C and 60% SOC. It is a lower-bound
resistance proxy, not DCIR. The base-path resistance is reconstructed and is
not experimentally validated.

## Generate the Simulink model

Simulink is required. From the repository root:

```matlab
cfg = setup_project();
modelFile = build_battery_loop_simulink(cfg);
open_system(modelFile);
```

The model has one input, `Sustained C-rate`, and six requirement outputs. It
contains no imposed coolant temperature, transient cell state, pump, radiator,
compressor or refrigeration circuit.

With Simulink available, compile-check the generated model using:

```matlab
run_battery_loop_simulink_checks
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
