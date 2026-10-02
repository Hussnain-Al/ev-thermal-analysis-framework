function cabin = cabin_cooling_config(rootDir)
%CABIN_COOLING_CONFIG Karachi hot-weather cabin boundaries and input file.

arguments
    rootDir (1,1) string
end

cabin.files.loadInputs = fullfile(rootDir,"data", ...
    "cabin_cooling","cabin_load_inputs.csv");
cabin.files.sourceWorkbook = fullfile(rootDir,"data", ...
    "cabin_cooling","Cabin_Cooling_Load_AutoRecovered.xlsx");
cabin.designLocation = "Karachi, Pakistan";
cabin.designAmbient_C = 45;
cabin.initialHotSoak_C = 80;
% Superseded: 45 C at 70% RH has a 38 C dew point, above any recorded dew
% point. apply_literature_corrections sets the coincident humidity.
cabin.superseded.ambientRelativeHumidity_pct = 70;
cabin.cabinSetpoint_C = 25;
cabin.cabinRelativeHumidity_pct = 50;
cabin.recoveredCabinDuty_kW = 4.156;
% Archived compressor evidence (WRDT18101-DM18A1 specification, R134a,
% 6000 rpm, 4 C evaporating, 312 V). Used only as a capacity reference.
cabin.archivedCompressorCapacity_kW = 3.63;
cabin.modelBoundary = ...
    "Heat-balance rebuild with literature solar, latent and fresh-air terms; recovered workbook retained as audited source";
end
