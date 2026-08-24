function result = simulate_battery_thermal_state(result, battery, coolantTemperature_C, initialTemperature_C)
%SIMULATE_BATTERY_THERMAL_STATE Lumped cell-to-cooling-plate response.
% The supplied module model shows lateral conduction between cells and a
% base path through the thermal pad and cooling plate. For a uniform row,
% lateral conduction redistributes heat but does not remove pack energy.
% The cell temperature state is advanced with the lumped energy balance:
%   m*cp*dT/dt = cell heat generation - heat transferred to the plate.
% Cooling hysteresis prevents rapid on/off switching at one temperature.

n = height(result);
if nargin < 4
    initialTemperature_C = battery.coolingOn_C;
end
cellTemperature_C = zeros(n,1);
coolingActive = false(n,1);
coolingRequest_kW = zeros(n,1);
cellTemperature_C(1) = initialTemperature_C;
active = initialTemperature_C >= battery.coolingOn_C;
thermalCapacity_JK = battery.cellMass_kg*battery.cellCp_JkgK;

for k = 1:n
    % Apply the configured on/off temperature thresholds.
    if active && cellTemperature_C(k) <= battery.coolingOff_C
        active = false;
    elseif ~active && cellTemperature_C(k) >= battery.coolingOn_C
        active = true;
    end

    if active
        % Conduction path to the plate: Q = (Tcell-Tcoolant)/Rbase.
        heatToPlatePerCell_W = max( ...
            (cellTemperature_C(k)-coolantTemperature_C)/battery.baseResistance_KW,0);
    else
        heatToPlatePerCell_W = 0;
    end
    coolingActive(k) = active;
    coolingRequest_kW(k) = heatToPlatePerCell_W*battery.seriesCells/1000;

    if k < n
        % Explicit time integration of the cell energy balance.
        dt = result.Time_s(k+1)-result.Time_s(k);
        dT = (result.BatteryHeat_kW(k)*1000/battery.seriesCells-heatToPlatePerCell_W) ...
            *dt/thermalCapacity_JK;
        cellTemperature_C(k+1) = cellTemperature_C(k)+dT;
    end
end

result.EstimatedCellTemperature_C = cellTemperature_C;
result.BatteryCoolingActive = coolingActive;
result.BatteryCoolingRequest_kW = coolingRequest_kW;
end
