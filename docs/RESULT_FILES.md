# Result-file contract

`run_all.m` writes each subsystem only to its own output folder. Generated
files are disposable: their authoritative inputs remain under `config/` and
`data/`.

| Module | Primary result files | Meaning |
|---|---|---|
| Motor heat | `motor_heat_summary.csv`, `*_motor_heat_trace.csv` | Drive-cycle operating points and integrated-drive heat generation |
| Motor cooling | `radiator_requirement.csv`, `pump_operating_point.csv`, `loop_sensitivity.csv` | Coolant transport, radiator sizing and hydraulic screening |
| Battery cooling | `battery_cooling_summary.csv`, `*_battery_cooling_trace.csv` | Pack loss, lumped cell temperature and plate request |
| Cabin cooling | `cabin_cooling_summary.csv`, `cabin_load_inputs_used.csv` | Karachi cabin boundary and recovered partial sensible duty |
| Shared compressor | `shared_cooling_current_result.csv` | Combined cabin/battery capacity screen and present verdict |

The shared result contains one row per drive-cycle/compressor combination. It
copies completed upstream results; it does not recompute motor, battery or cabin
physics. The three `*ModelBoundary` columns state what remains outside the
current model, and `OverallScreeningPass` is true only when gross compressor
capacity and the battery cell-temperature screen both pass.

Plots remain module-specific:

- `motor_heat/motor_heat_traces.png`
- `motor_cooling/loop_sensitivity.png`
- `battery_cooling/battery_cooling_traces.png`

No combined plot is generated because the cabin input is presently a fixed,
partial sensible duty rather than a validated transient cabin-load trace.
