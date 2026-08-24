function results = calculate_battery_thermal_network(cellHeat_W, baseResistance_KW, sideResistance_KW_each)
%CALCULATE_BATTERY_THERMAL_NETWORK Parallel base and two-side screening paths.
% Thermal resistance uses K/W. The two equal side paths act in parallel;
% their equivalent resistance is Rside/2. The base path then acts in
% parallel with that side equivalent. Temperature rise follows dT = Q*Req.

sideEquivalent_KW = sideResistance_KW_each / 2;
equivalent_KW = 1 / (1/baseResistance_KW + 1/sideEquivalent_KW);
temperatureRise_C = cellHeat_W(:) * equivalent_KW;
heatToBase_W = temperatureRise_C / baseResistance_KW;
heatToSides_W = temperatureRise_C / sideEquivalent_KW;
basePathRequiredRise_C = cellHeat_W(:)*baseResistance_KW;
results = table(cellHeat_W(:),temperatureRise_C,basePathRequiredRise_C, ...
    heatToBase_W,heatToSides_W, ...
    'VariableNames', {'CellHeat_W','ParallelPathScreeningRise_C', ...
    'BasePathRequiredRise_C','HeatToBase_W','HeatToBothSides_W'});
end
