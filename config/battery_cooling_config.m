function battery = battery_cooling_config(rootDir)
%BATTERY_COOLING_CONFIG Cell, pack, thermal-path and cooling-control inputs.

arguments
    rootDir (1,1) string
end

battery.files.vehicleLoadCases = fullfile(rootDir,"data", ...
    "battery_cooling","vehicle_load_cases.csv");
battery.files.heatExchangerGeometry = fullfile(rootDir,"data", ...
    "battery_cooling","battery_heat_exchanger_geometry.csv");

battery.capacity_Ah = 134;
battery.nominalVoltage_V = 3.2;
battery.seriesCells = 108;
battery.cellsPerRow = 9;
battery.cellsPerModule = 18;
battery.modules = 6;
battery.packNominalVoltage_V = battery.seriesCells*battery.nominalVoltage_V;

% The archived SVOLT sheet specifies ACR <= 0.40 mOhm at 25 C and 60% SOC.
% This remains a minimum-resistive screening proxy, not a fitted DC model.
battery.resistanceProxy_Ohm = 0.40e-3;
battery.resistanceCases_Ohm = [0.30 0.40 0.60]*1e-3;
battery.cRates = [0.1 0.3 0.5 0.75 1 1.25 1.5 1.75 2];
battery.sideResistance_KW_each = 16.67;
battery.baseResistance_KW = 3.10;
battery.cellMass_kg = 2.420;
battery.cellCp_JkgK = 900;
battery.coolingOn_C = 35;
battery.coolingOff_C = 32;
battery.maximumCell_C = 60;
battery.initialCellTemperature_C = 45;
battery.coolantTemperature_C = 30;
battery.modelBoundary = ...
    "Lumped cell thermal screen using an ACR resistance proxy and fixed 30 C plate coolant";
end
