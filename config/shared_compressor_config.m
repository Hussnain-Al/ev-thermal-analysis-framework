function shared = shared_compressor_config(rootDir)
%SHARED_COMPRESSOR_CONFIG Common refrigerant source for cabin and battery.

arguments
    rootDir (1,1) string
end

shared.files.performanceMap = fullfile(rootDir,"data", ...
    "shared_compressor","compressor_performance_map.csv");
shared.files.candidates = fullfile(rootDir,"data", ...
    "shared_compressor","compressor_candidates.csv");
shared.mapSpeed_rpm = 6000;
shared.mapEvaporator_C = 4;
shared.allocationPriority = "battery";
shared.refrigerant = "R134a";
shared.mapVoltage_V = 312;
shared.modelBoundary = ...
    "Capacity allocation only; condenser and refrigerant-state dynamics are not solved";
end
