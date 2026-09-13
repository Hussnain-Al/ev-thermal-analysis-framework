function result = calculate_radiator_airside_sensitivity( ...
    caseNames,heatDuty_kW,airTemperatureRise_C,thermal,coolant,coreArea_m2)
%CALCULATE_RADIATOR_AIRSIDE_SENSITIVITY Show boundary-condition dependence.
% Required face velocity and ideal UA are calculated over assumed air-side
% temperature rise. The function does not predict achieved radiator or fan
% performance.

arguments
    caseNames string
    heatDuty_kW double {mustBeNonnegative}
    airTemperatureRise_C double {mustBePositive}
    thermal (1,1) struct
    coolant table
    coreArea_m2 (1,1) double {mustBePositive}
end

caseNames = caseNames(:);
heatDuty_kW = heatDuty_kW(:);
airTemperatureRise_C = airTemperatureRise_C(:);
assert(numel(caseNames)==numel(heatDuty_kW), ...
    'EVThermal:RadiatorSensitivityInputSize', ...
    'Case and heat-duty vectors must have equal length.');

tables = cell(numel(airTemperatureRise_C),1);
for i = 1:numel(airTemperatureRise_C)
    localThermal = thermal;
    localThermal.airOut_C = thermal.airIn_C+airTemperatureRise_C(i);
    local = calculate_radiator_design_requirements( ...
        caseNames,heatDuty_kW,localThermal,coolant,coreArea_m2);
    local.AirTemperatureRise_C = repmat( ...
        airTemperatureRise_C(i),height(local),1);
    tables{i} = local;
end
result = vertcat(tables{:});
end
