function cfg = project_config(rootDir)
%PROJECT_CONFIG Assemble independent configuration domains.
% Each domain owns its parameters and input files. Cross-domain coupling is
% performed by run_all through result structs, not through hidden globals.

arguments
    rootDir (1,1) string
end

cfg.project.name = "EV Thermal Analysis Framework";
cfg.project.version = "3.1.0";
cfg.project.rootDir = rootDir;
cfg.project.outputDir = fullfile(rootDir,"outputs");
cfg.project.parameterRegister = fullfile(rootDir,"data", ...
    "sample_parameter_register.csv");

[cfg.vehicle,cfg.cycles] = vehicle_config(rootDir);
cfg.motorHeat = motor_heat_config(rootDir);
cfg.motorCooling = motor_cooling_config(rootDir);
cfg.batteryCooling = battery_cooling_config(rootDir);
cfg.cabinCooling = cabin_cooling_config(rootDir);
cfg.sharedCompressor = shared_compressor_config(rootDir);
end
