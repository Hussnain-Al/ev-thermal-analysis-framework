# Drive-Cycle Thermal Method

For each configured time-speed trace, the framework:

1. reads time and vehicle speed;
2. calculates acceleration;
3. converts vehicle speed to wheel and drive-unit speed;
4. calculates road-load, inertia, and grade forces;
5. calculates requested wheel power and drive-unit torque;
6. checks the torque-speed and power-speed envelopes;
7. interpolates the integrated efficiency map;
8. exports DC-link power and drive-unit heat from the motor module;
9. passes the DC-link trace to the independent battery module;
10. calculates pack current, resistive heat and the lumped thermal state;
11. passes battery plate demand and cabin duty to the shared compressor module;
12. exports separate domain traces and one combined compressor decision file.

Cycle-average heat is useful for energy and sustained thermal duty. Cycle-peak heat is useful for short transient screening. Neither value alone defines a component; duration, thermal mass, control response, and boundary temperatures also matter.
