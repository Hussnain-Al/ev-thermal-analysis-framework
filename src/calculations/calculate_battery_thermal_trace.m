function result = calculate_battery_thermal_trace(motorTrace,battery)
%CALCULATE_BATTERY_THERMAL_TRACE Battery heat and plate request from DC power.
% The motor module supplies the time-aligned DC-link power. This function
% owns pack voltage, cell resistance, thermal mass and cooling thresholds.

validate_table_columns(motorTrace,{'Cycle','Time_s','DCLinkPower_kW'}, ...
    'motor heat trace');

result = motorTrace;
result.BatteryPower_kW = result.DCLinkPower_kW;
result.PackCurrent_A = ...
    result.BatteryPower_kW*1000/battery.packNominalVoltage_V;
cellHeat_W = result.PackCurrent_A.^2*battery.resistanceProxy_Ohm;
result.BatteryHeat_kW = cellHeat_W*battery.seriesCells/1000;
result = simulate_battery_thermal_state(result,battery, ...
    battery.coolantTemperature_C,battery.initialCellTemperature_C);
end
