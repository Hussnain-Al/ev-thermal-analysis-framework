# Result-file contract

| Module | Primary results | Meaning |
|---|---|---|
| Motor heat | `motor_heat_summary.csv`, `*_motor_heat_trace.csv`, `controller_loss_reference_used.csv` | Operating points, integrated-drive heat and controller-only reference points |
| Motor cooling | `motor_thermal_summary.csv`, `*_motor_thermal_trace.csv` | Two-node thermal response under exposed assumptions |
| Hydraulics | `loop_sensitivity.csv`, `pump_operating_point.csv` | Hose/fitting loss and remaining head at the documented pump point |
| Radiator design | `radiator_candidate_geometry.csv`, `radiator_design_requirements.csv` | Candidate core, ideal UA, idle fan-flow duty and ideal ram-air bound |
| Battery | `battery_sustained_screen.csv`, `battery_specification_limits.csv` | ACR-based heat floor and allowable coolant temperature |
| Cabin | `cabin_cooling_summary.csv`, `cabin_load_inputs_used.csv` | Independent recovered partial sensible load |

Generated plots:

- `motor_heat/motor_heat_traces.png`
- `motor_cooling/motor_thermal_response.png`
- `motor_cooling/loop_sensitivity.png`
- `motor_cooling/radiator_design_requirements.png`
- `battery_cooling/battery_c_rate_sweep.png`
- `cabin_cooling/cabin_load_breakdown.png`

There are no battery drive-cycle temperatures, cooling requests, compressor
allocations or combined battery/cabin verdicts.
