function curves = load_propulsion_curves(workbookPath,efficiencyMapPath)
%LOAD_PROPULSION_CURVES Import drive-unit limits and efficiency data.

torqueData = readmatrix(workbookPath,'Sheet','Torque RPM Curve','Range','A2:B200');
powerData = readmatrix(workbookPath,'Sheet','Power RPM Curve','Range','A2:B200');
torqueData = torqueData(all(isfinite(torqueData),2),:);
powerData = powerData(all(isfinite(powerData),2),:);

[curves.torqueRPM,idx] = sort(torqueData(:,1));
curves.maxTorque_Nm = torqueData(idx,2);
[curves.powerRPM,idx] = sort(powerData(:,1));
curves.maxPower_kW = powerData(idx,2);

efficiencyData = read_project_csv(efficiencyMapPath, ...
    {'Speed_rpm','Torque_Nm','IntegratedEfficiency_pct'}, ...
    {'Speed_rpm','Torque_Nm','IntegratedEfficiency_pct'});
curves.efficiencyRPM = unique(efficiencyData.Speed_rpm,'sorted')';
curves.efficiencyTorque_Nm = unique(efficiencyData.Torque_Nm,'sorted')';
[~,rpmIndex] = ismember(efficiencyData.Speed_rpm,curves.efficiencyRPM);
[~,torqueIndex] = ismember(efficiencyData.Torque_Nm,curves.efficiencyTorque_Nm);
curves.integratedEfficiency = nan(numel(curves.efficiencyRPM), ...
    numel(curves.efficiencyTorque_Nm));
linearIndex = sub2ind(size(curves.integratedEfficiency),rpmIndex,torqueIndex);
if numel(unique(linearIndex))~=height(efficiencyData)
    error('EVThermal:DuplicateMapPoint', ...
        'Drive-unit efficiency map contains duplicate coordinates.');
end
curves.integratedEfficiency(linearIndex) = ...
    efficiencyData.IntegratedEfficiency_pct/100;
if any(isnan(curves.integratedEfficiency),'all')
    error('EVThermal:IncompleteMap', ...
        'Drive-unit efficiency map must contain a complete rectangular grid.');
end
end
