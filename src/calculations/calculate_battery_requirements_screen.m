function results = calculate_battery_requirements_screen(cRates,battery)
%CALCULATE_BATTERY_REQUIREMENTS_SCREEN Sustained battery requirements.
% Cell heat = I^2 R_DC(25 C) + I T_ref |dU/dT|peak. Both terms are held at
% their conservative values: 25 C resistance (it falls as the cell warms)
% and the low-SOC entropic peak. The required cell-to-coolant temperature
% difference uses the bottom-cooling path built from the literature register.
% The band is the 5th-95th percentile of the allowable coolant temperature
% over the joint register samples of DC resistance and path resistance
% (battery.uncertainty, set by apply_literature_corrections). The superseded
% ACR/3.10 K/W result is reported for comparison only.

arguments
    cRates double {mustBeNonnegative}
    battery (1,1) struct
end

results = calculate_battery_ohmic_heat(cRates,battery.capacity_Ah, ...
    battery.dcResistance25_Ohm,battery.seriesCells);
current = results.Current_A;
results.JouleHeat_W = results.CellHeat_W;
results.EntropicHeat_W = current*(battery.entropicReferenceTemperature_C+273.15)* ...
    battery.entropicPeak_VK;
results.CellHeat_W = results.JouleHeat_W+results.EntropicHeat_W;
results.PackHeat_kW = results.CellHeat_W*battery.seriesCells/1000;
results.RequiredCellToCoolantRise_C = ...
    results.CellHeat_W*battery.cellToCoolantResistance_KW;
results.MaximumCoolantForRegen_C = ...
    battery.regenChargeCutoff_C-results.RequiredCellToCoolantRise_C;
results.MaximumCoolantForDischarge_C = ...
    battery.absoluteOperatingLimit_C-results.RequiredCellToCoolantRise_C;

n = numel(current);
p05 = zeros(n,1);
p95 = zeros(n,1);
for i = 1:n
    sampledHeat = current(i)^2*battery.uncertainty.dcResistance25_Ohm+ ...
        results.EntropicHeat_W(i);
    sampledLimit = battery.absoluteOperatingLimit_C- ...
        sampledHeat.*battery.uncertainty.cellToCoolantResistance_KW;
    band = percentile_linear(sampledLimit,[5 95]);
    p05(i) = band(1);
    p95(i) = band(2);
end
results.MaximumCoolantForDischargeP05_C = p05;
results.MaximumCoolantForDischargeP95_C = p95;

acrHeat = current.^2*battery.resistanceProxy_Ohm;
results.SupersededACRCellHeat_W = acrHeat;
results.SupersededMaximumCoolantForDischarge_C = battery.absoluteOperatingLimit_C- ...
    acrHeat*battery.superseded.baseResistance_KW;
end
