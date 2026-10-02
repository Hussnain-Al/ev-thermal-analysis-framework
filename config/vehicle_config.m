function [vehicle,cycles] = vehicle_config(rootDir)
%VEHICLE_CONFIG Vehicle longitudinal inputs and imposed drive schedules.

arguments
    rootDir (1,1) string
end

vehicle.mass_kg = 1950;
vehicle.gravity_ms2 = 9.81;
vehicle.wheelDiameter_m = 0.724;
vehicle.wheelRadius_m = vehicle.wheelDiameter_m/2;
vehicle.gearRatio = 9.11;
% Single-speed reducer efficiency. Project evidence: power demand1.xlsx
% (Sheet4, "Mechanical Transmission Efficiency 98%"). The supplied
% efficiency map is the motor-system map (motor plus controller), so the
% reducer loss sits between the wheel and the map. That loss is reported
% separately and not added to the coolant heat: the reducer is oil-splash
% lubricated and rejects mostly through its own housing.
vehicle.reducerEfficiency = 0.98;

% Flat-road force model: Froad = A + B*v^2. Replace these reconstructed
% coefficients with measured coast-down data when it becomes available.
vehicle.roadLoadA_N = 566.4645;
vehicle.roadLoadB_N_per_ms2 = 0.4185918;
vehicle.grade_pct = 0;
vehicle.regenEnabled = true;

cycles = table( ...
    ["Urban stop-start";"Highway"], ...
    ["urban_cycle";"highway_cycle"], ...
    [string(fullfile(rootDir,"data","common","cycles","urban_cycle.txt")); ...
     string(fullfile(rootDir,"data","common","cycles","highway_cycle.txt"))], ...
    'VariableNames',{'Name','FileStem','File'});
end
