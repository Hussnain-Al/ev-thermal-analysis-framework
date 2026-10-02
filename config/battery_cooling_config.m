function battery = battery_cooling_config(rootDir)
%BATTERY_COOLING_CONFIG Sustained battery thermal-screen inputs.

arguments
    rootDir (1,1) string
end

battery.sourceSpecification = ...
    "SVOLT 134Ah LFP Cell Specification (3).zh-CN.en (1).pdf";
battery.sourceManifest = fullfile(rootDir,"references","SOURCE_PROVENANCE.md");

battery.capacity_Ah = 134;
battery.nominalVoltage_V = 3.2;
battery.seriesCells = 108;
battery.packNominalVoltage_V = battery.seriesCells*battery.nominalVoltage_V;

% The archived SVOLT sheet specifies ACR <= 0.40 mOhm at 25 C and 60% SOC.
% ACR is a 1 kHz measurement; apply_literature_corrections converts it to a
% DC resistance and adds the cell-to-coolant path built from the register.
battery.resistanceProxy_Ohm = 0.40e-3;
battery.cRates = [0.1 0.3 0.5 0.75 1 1.25 1.5 1.75 2];
% Superseded: the reconstructed base path is about ten times the bottom-
% cooling build-up and is kept only for comparison (docs/CORRECTIONS.md).
battery.superseded.baseResistance_KW = 3.10;
battery.regenChargeCutoff_C = 55;
battery.absoluteOperatingLimit_C = 60;
battery.maximumContinuousDischarge_C = 2.0;
battery.referenceContinuousRate_C = 1.0;
battery.referenceContinuousDuration_s = 600;
battery.referenceContinuousRiseLimit_C = 15;
battery.referencePulseRate_C = 3.0;
battery.referencePulseDuration_s = 30;
battery.referencePulseRiseLimit_C = 10;
battery.modelBoundary = ...
    "Set by apply_literature_corrections";
end
