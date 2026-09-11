# Motor operating-case method

For every time-speed case, the framework calculates acceleration, road and
grade forces, wheel power, motor speed and torque, operating-envelope status,
integrated efficiency and drive-unit heat.

The standard EPA NYCC and HWFET schedules are retained. Two constant-speed
hot-weather screens are added because regulatory cycles do not represent the
project's sustained propulsion thermal cases:

| Case | Speed | Grade | Duration | Ambient |
|---|---:|---:|---:|---:|
| Sustained grade | 40 km/h | 10% | 1200 s | 45 C |
| Low-speed hot-weather grade | 15 km/h | 5% | 1800 s | 45 C |

Each resulting heat trace feeds the two-node motor/coolant model directly.
