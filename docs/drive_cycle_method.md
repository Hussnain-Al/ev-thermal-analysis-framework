# Drive-Cycle Thermal Method

For each configured time-speed trace, the framework:

1. reads time and vehicle speed;
2. calculates acceleration;
3. converts vehicle speed to wheel and drive-unit speed;
4. calculates road-load, inertia, and grade forces;
5. calculates requested wheel power and drive-unit torque;
6. checks the torque-speed and power-speed envelopes;
7. interpolates the integrated efficiency map;
8. calculates drive-unit heat, battery power, current, and resistive heat;
9. updates the lumped battery thermal state;
10. compares battery and cabin cooling demand with compressor candidates;
11. exports full transient traces and cycle summaries.

Cycle-average heat is useful for energy and sustained thermal duty. Cycle-peak heat is useful for short transient screening. Neither value alone defines a component; duration, thermal mass, control response, and boundary temperatures also matter.
