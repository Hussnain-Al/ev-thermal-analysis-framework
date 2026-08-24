function eta = estimate_integrated_drive_efficiency(speed_rpm,torque_Nm,map)
%ESTIMATE_INTEGRATED_DRIVE_EFFICIENCY Interpolate the configured efficiency map.
% Absolute torque is used because the sample map is magnitude-based. Queries
% are limited to the supplied axes; no efficiency extrapolation is permitted.

speedQuery = min(max(abs(speed_rpm),map.efficiencyRPM(1)),map.efficiencyRPM(end));
torqueQuery = min(max(abs(torque_Nm),map.efficiencyTorque_Nm(1)), ...
    map.efficiencyTorque_Nm(end));
eta = interp2(map.efficiencyTorque_Nm,map.efficiencyRPM, ...
    map.integratedEfficiency,torqueQuery,speedQuery,'linear');
mapMinimum = min(map.integratedEfficiency,[],'all');
mapMaximum = max(map.integratedEfficiency,[],'all');
eta = min(max(eta,mapMinimum),mapMaximum);
end
