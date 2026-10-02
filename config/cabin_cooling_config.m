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
% Compressor evidence (DM18A1 specification, R134a, 312 V). The rated
% 2.9 kW is at 6000 rpm, 1.47 MPa(G) discharge (about 57 C condensing) and
% 0.196 MPa(G) suction (about 0 C evaporating), which matches a 45 C
% ambient. The archived 3.63 kW read from the capacity curve at 4 C
% evaporating needs a lower condensing temperature than a 45 C day allows.
cabin.compressorRatedCapacity_kW = 2.9;
cabin.compressorRatedInput_kW = 1.5;
cabin.superseded.archivedCompressorCapacity_kW = 3.63;
cabin.modelBoundary = ...
    "Heat-balance rebuild with literature solar, latent and fresh-air terms; recovered workbook retained as audited source";
end
