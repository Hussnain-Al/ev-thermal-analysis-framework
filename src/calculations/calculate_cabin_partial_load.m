function result = calculate_cabin_partial_load(inputs)
%CALCULATE_CABIN_PARTIAL_LOAD Recovered sensible-load subtotal only.

result = table(sum(inputs.Load_kW), ...
    'VariableNames', {'RecoveredPartialSensibleLoad_kW'});
end
