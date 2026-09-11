# Result-file contract

`run_all.m` writes each subsystem only to its own output folder. Generated
files are disposable: their authoritative inputs remain under `config/` and
`data/`.

| Module | Primary result files | Meaning |
|---|---|---|
| Motor heat | `motor_heat_summary.csv`, `*_motor_heat_trace.csv` | Drive-cycle operating points and integrated-drive heat generation |
| Motor cooling | `motor_cooling_current_result.csv`, `pump_operating_point.csv`, `loop_sensitivity.csv` | Duty, coolant rise, radiator sizing and hydraulic screening |
| Battery cooling | `battery_cooling_summary.csv`, `*_battery_cooling_trace.csv` | Pack loss, cooling request, temperature extrema, energy and active time |
| Cabin cooling | `cabin_cooling_summary.csv`, `cabin_load_inputs_used.csv` | Karachi cabin boundary and recovered partial sensible duty |
| Shared compressor | `shared_cooling_current_result.csv` | Combined demand, capacity, allocation, shortfall and present verdict |

The shared result contains one row per drive-cycle/compressor combination. It
copies completed upstream results; it does not recompute motor, battery or cabin
physics. The three `*ModelBoundary` columns state what remains outside the
current model, and `OverallScreeningPass` is true only when gross compressor
capacity and the battery cell-temperature screen both pass.

Plots remain module-specific:

- `motor_heat/motor_heat_traces.png`
- `motor_cooling/motor_cooling_requirements.png`
- `motor_cooling/loop_sensitivity.png`
- `battery_cooling/battery_cooling_traces.png`
- `cabin_cooling/cabin_load_breakdown.png`
- `shared_compressor/shared_compressor_capacity.png`

Reference copies from the verified MATLAB R2024b workflow are committed under
`docs/images/results/` and displayed with rounded decision tables in the main
README. Files under `outputs/` remain generated artifacts and are rebuilt by
`verify_framework`.

The shared-compressor plot combines the fixed recovered cabin subtotal with the
transient battery plate request only for gross capacity screening. It is not a
refrigerant-cycle simulation or a validated transient cabin-load result.
