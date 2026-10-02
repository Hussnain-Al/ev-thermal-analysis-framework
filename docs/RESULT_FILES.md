# Result-file contract

| Module | Primary results | Meaning |
|---|---|---|
| Motor heat | `motor_heat_summary.csv`, `*_motor_heat_trace.csv`, `controller_loss_reference_used.csv` | Operating points, integrated-drive heat and controller-only reference points |
| Motor cooling | `motor_thermal_summary.csv`, `*_motor_thermal_trace.csv` | Two-node screen with calibrated winding resistance and estimated core UA; capacitances assumed |
| Hydraulics | `loop_sensitivity.csv`, `pump_operating_point.csv` | Hose/fitting system curve and remaining head at the documented reference point |
| Radiator design | `radiator_candidate_geometry.csv`, `radiator_design_requirements.csv`, `radiator_airside_sensitivity.csv` | Candidate core, required face velocity and ideal UA sensitivity; no delivered fan/core performance |
| Battery | `battery_sustained_screen.csv`, `battery_specification_limits.csv` | DC Joule plus entropic heat, allowable coolant temperature with 5-95% band, superseded ACR result |
| Cabin | `cabin_cooling_summary.csv`, `cabin_load_inputs_used.csv`, `cabin_workbook_audit.csv`, `cabin_heat_balance.csv` | Recorded and recomputed workbook subtotal, heat-balance load for two humidity scenarios |
| Literature gap fill | `literature_gap_fill/*.csv`, including `correction_robustness.csv` and `correction_sensitivity.csv` | Estimates from the literature register and the robustness test of each correction |

Generated plots:

- `motor_heat/motor_heat_traces.png`
- `motor_cooling/motor_thermal_response.png`
- `motor_cooling/loop_sensitivity.png`
- `motor_cooling/radiator_design_requirements.png`
- `battery_cooling/battery_c_rate_sweep.png`
- `cabin_cooling/cabin_load_breakdown.png`
- `literature_gap_fill/gap_*.png` (seven figures, see `LITERATURE_GAP_FILL.md` and `CORRECTIONS.md`)

The README and docs display publication copies of the passing MATLAB
workflow artifact (`matlab-results`, uploaded by the CI run). After a run that
changes a figure, copy it from the artifact into the docs path:

| Artifact file | Docs copy |
|---|---|
| `motor_cooling/motor_thermal_response.png` | `docs/images/results/motor_thermal_response.png` |
| `battery_cooling/battery_c_rate_sweep.png` | `docs/images/results/battery_c_rate_sweep.png` |
| `cabin_cooling/cabin_load_breakdown.png` | `docs/images/results/cabin_load_breakdown.png` |
| `literature_gap_fill/gap_*.png` (7 files) | `docs/images/gap_fill/` (same names) |

The `Publish MATLAB figures` workflow (`.github/workflows/publish-figures.yml`,
run manually from the Actions tab) regenerates them and commits these copies.

Version `4.5.0` changes all ten of these figures. The previous copies were
removed instead of left showing superseded results. The files under `docs/images/simulink/` contain user-captured MATLAB
Online model screenshots and readable vector views of the same topologies.

There are no battery drive-cycle temperatures, cooling requests, compressor
allocations or combined battery/cabin verdicts. The battery discharge
transient uses fixed coolant temperatures; it does not model the coolant loop.
