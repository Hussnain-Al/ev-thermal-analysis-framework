# Data Domains

| Folder | Contents |
|---|---|
| `common/cycles/` | EPA NYCC and HWFET numerical sequences |
| `motor_heat/` | Original native torque/power workbook and digitized efficiency map |
| `motor_cooling/` | Pump resistance, radiator geometry and motor thermal references |
| `battery_cooling/` | Battery load cases and battery heat-exchanger geometry |
| `cabin_cooling/` | Recovered cabin sensible-load inputs |
| `shared_compressor/` | DM18A1 R134a performance table and comparison candidates |

The active data tree contains reusable numerical inputs. Original vendor and
confidential documents remain in the ignored local reference folder. Their
hashes and use status are recorded in
[`../references/SOURCE_PROVENANCE.md`](../references/SOURCE_PROVENANCE.md).

Do not move a parameter into another subsystem merely because both subsystems
use its result. Cross-domain coupling belongs in `run_all.m` or the shared
compressor module.
