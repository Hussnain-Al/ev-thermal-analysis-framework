function out = run_drive_cycle_analysis(cfg)
%RUN_DRIVE_CYCLE_ANALYSIS Execute each configured transient drive cycle.

cycles = cfg.cycles;

model.vehicle = cfg.vehicle;
model.battery = cfg.battery;
model.propulsionCurves = load_propulsion_curves( ...
    cfg.files.driveLimitWorkbook,cfg.files.driveEfficiencyMap);
model.compressorCandidates = cfg.hvac.compressorCandidates;
model.cabinDuty_kW = cfg.hvac.recoveredCabinDuty_kW;
model.allocationPriority = cfg.hvac.allocationPriority;
model.coolantTemperature_C = cfg.battery.coolantTemperature_C;
model.initialBatteryTemperature_C = cfg.battery.initialCellTemperature_C;

out = analyze_drive_cycles(cycles,model,string(cfg.project.outputDir));
end
