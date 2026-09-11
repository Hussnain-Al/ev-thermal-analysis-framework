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
cabin.ambientRelativeHumidity_pct = 70;
cabin.cabinSetpoint_C = 25;
cabin.cabinRelativeHumidity_pct = 50;
cabin.recoveredCabinDuty_kW = 4.156;
cabin.modelBoundary = ...
    "Recovered partial sensible load; solar, latent, ventilation and pull-down require validation";
end
