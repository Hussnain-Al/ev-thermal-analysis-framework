function motorHeat = motor_heat_config(rootDir)
%MOTOR_HEAT_CONFIG Inputs used only to calculate integrated drive-unit heat.

arguments
    rootDir (1,1) string
end

motorHeat.files.driveLimitWorkbook = fullfile(rootDir,"data", ...
    "motor_heat","drive_unit_limits.xlsx");
motorHeat.files.driveEfficiencyMap = fullfile(rootDir,"data", ...
    "motor_heat","drive_unit_efficiency_map.csv");
motorHeat.mapBoundary = ...
    "Integrated motor/inverter/reducer map digitized from the 125 kW source chart";
end
