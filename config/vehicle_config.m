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
