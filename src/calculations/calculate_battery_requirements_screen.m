function results = calculate_battery_requirements_screen(cRates,battery)
%CALCULATE_BATTERY_REQUIREMENTS_SCREEN Sustained battery requirements.
% This is a lower-bound requirements calculation, not a transient model.
% The SVOLT 1 kHz ACR limit is the only available resistance and is used
% only to calculate minimum ohmic heat. No coolant temperature is imposed.

arguments
    cRates double {mustBeNonnegative}
    battery (1,1) struct
end

results = calculate_battery_ohmic_heat(cRates,battery.capacity_Ah, ...
    battery.resistanceProxy_Ohm,battery.seriesCells);
results.RequiredCellToCoolantRise_C = ...
    results.CellHeat_W*battery.baseResistance_KW;
results.MaximumCoolantForRegen_C = ...
    battery.regenChargeCutoff_C-results.RequiredCellToCoolantRise_C;
results.MaximumCoolantForDischarge_C = ...
    battery.absoluteOperatingLimit_C-results.RequiredCellToCoolantRise_C;
results.ACRProxyOnly = true(height(results),1);
end
