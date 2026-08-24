function result = calculate_compressor_duty_margin(capacity_kW, batteryDuty_kW, cabinDuty_kW, label)
%CALCULATE_COMPRESSOR_DUTY_MARGIN Gross capacity margin before HX losses.

combinedDuty_kW = batteryDuty_kW + cabinDuty_kW;
grossMargin_kW = capacity_kW - combinedDuty_kW;
result = table(string(label), batteryDuty_kW, cabinDuty_kW, combinedDuty_kW, ...
    capacity_kW, grossMargin_kW, grossMargin_kW >= 0, ...
    'VariableNames', {'Case','BatteryDuty_kW','CabinDuty_kW','CombinedDuty_kW', ...
    'CompressorCapacity_kW','GrossMargin_kW','CapacityExceedsDuty'});
end

