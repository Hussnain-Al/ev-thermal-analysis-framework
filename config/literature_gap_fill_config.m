function gapFill = literature_gap_fill_config(rootDir)
%LITERATURE_GAP_FILL_CONFIG Literature-assumption layer for missing inputs.
% Every numerical assumption lives in the register CSV with a low/high range
% and a source. Results from this layer are estimates, not project evidence.

arguments
    rootDir (1,1) string
end

gapFill.files.assumptionRegister = fullfile(rootDir,"data", ...
    "literature","literature_assumption_register.csv");

% Battery discharge transient scenarios.
gapFill.battery.cRates = [0.5 1 2];
gapFill.battery.coolantScenarios_C = [25 50];
gapFill.battery.coolantScenarioNames = ...
    ["Chiller-conditioned coolant";"Radiator-only coolant at 45 C ambient"];
gapFill.battery.timeStep_s = 1;
% Simplified LFP/graphite entropic profile (dU/dT, mV/K versus SOC). Shape
% follows published LFP profiles: negative at low SOC, small positive peak
% near 45% SOC. Magnitudes are screening values, not SVOLT measurements.
gapFill.battery.entropicSOC_pct = [0 5 20 37.8 45 55 65.5 75 88.5 95 100];
gapFill.battery.entropic_mVK = ...
    [-0.30 -0.37 -0.15 0 0.10 0.05 0 -0.05 0 0.03 0.03];

% Radiator performance sweep.
gapFill.radiator.faceVelocity_ms = (0.5:0.25:8)';
gapFill.radiator.coolantFlows_Lmin = [10 20 30];

% Drive-unit calibration sweep over the unknown rated operating speed.
gapFill.motor.ratedSpeedSweep_rpm = (3000:250:9000)';
gapFill.motor.referenceCoolant_C = 60;
gapFill.motor.referenceWinding_C = 143;
gapFill.motor.insulationClassH_C = 180;

% Cabin heat-balance scenarios. The configured 45 C / 70% RH pairing has a
% 38 C dew point, above the highest dew point ever recorded (about 35 C), so
% it is replaced here by two physically consistent hot-weather scenarios.
gapFill.cabin.scenarioNames = ["Dry heat";"Humid heat (2015 peak)"];
gapFill.cabin.solarHour = 15;
gapFill.cabin.latitude_deg = 24.9;
gapFill.cabin.declination_deg = 23.45;
gapFill.cabin.pullDownTime_min = (10:1:60)';
gapFill.cabin.workbookOutdoor_C = 38.1;
gapFill.cabin.workbookIndoor_C = 23;
gapFill.modelBoundary = ...
    "Literature-assumption estimates; replace each register row with project measurements";
end
