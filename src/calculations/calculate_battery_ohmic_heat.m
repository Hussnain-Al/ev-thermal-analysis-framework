function results = calculate_battery_ohmic_heat(cRates, capacity_Ah, resistance_Ohm, seriesCells)
%CALCULATE_BATTERY_OHMIC_HEAT Minimum resistive heat from I^2R.
% C-rate is current divided by rated capacity, therefore I = C*capacity.
% All series cells carry the same current and their heat contributions add.

current_A = cRates(:) * capacity_Ah;
cellHeat_W = current_A.^2 * resistance_Ohm;
packHeat_W = cellHeat_W * seriesCells;
results = table(cRates(:), current_A, cellHeat_W, packHeat_W / 1000, ...
    'VariableNames', {'C_rate','Current_A','CellHeat_W','PackHeat_kW'});
end
