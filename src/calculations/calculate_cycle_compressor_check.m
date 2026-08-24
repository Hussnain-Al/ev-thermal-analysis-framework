function out = calculate_cycle_compressor_check(result,candidates,cabinDuty_kW,priority)
%CALCULATE_CYCLE_COMPRESSOR_CHECK Allocate shared cooling capacity.
% At each time step, the configured priority load receives capacity first.
% The remaining capacity is assigned to the other load. This is a capacity
% balance only; it does not solve refrigerant pressures or transient controls.
% Driving inputs: time-varying battery demand, cabin duty and candidate capacity.
% Calculated responses: allocation, shortfall, duty fraction and capacity margin.

if nargin < 4
    priority = "battery";
end
priority = lower(string(priority));
if ~ismember(priority,["battery","cabin"])
    error('EVThermal:InvalidCoolingPriority', ...
        'Cooling priority must be "battery" or "cabin".');
end
validate_table_columns(candidates,{'Model','CoolingCapacity_kW','InputPower_kW'}, ...
    'compressor candidates');

rows = cell(height(candidates),1);
for i = 1:height(candidates)
    capacity = candidates.CoolingCapacity_kW(i);
    batteryDemand = result.BatteryCoolingRequest_kW;
    if priority == "battery"
        batteryAllocated = min(batteryDemand,capacity);
        remaining = max(capacity-batteryAllocated,0);
        cabinAllocated = min(cabinDuty_kW,remaining);
    else
        cabinAllocated = min(cabinDuty_kW,capacity)*ones(size(batteryDemand));
        remaining = max(capacity-cabinAllocated,0);
        batteryAllocated = min(batteryDemand,remaining);
    end
    combinedDemand = batteryDemand+cabinDuty_kW;
    [peakBatteryRequest,peakBatteryIndex] = max(batteryDemand);
    peakBatteryTime_s = result.Time_s(peakBatteryIndex);
    peakBatteryCellTemperature_C = result.EstimatedCellTemperature_C(peakBatteryIndex);
    % Estimate input power by scaling the map-point power with duty fraction.
    compressorFraction = min(combinedDemand/capacity,1);
    compressorInput = compressorFraction*candidates.InputPower_kW(i);

    time_s = result.Time_s;
    rows{i} = table(result.Cycle(1),candidates.Model(i),capacity, ...
        time_average(time_s,batteryDemand),peakBatteryRequest,peakBatteryTime_s, ...
        peakBatteryCellTemperature_C,cabinDuty_kW, ...
        time_average(time_s,combinedDemand),max(combinedDemand), ...
        capacity-max(combinedDemand),100*(capacity/max(combinedDemand)-1), ...
        time_average(time_s,batteryAllocated),time_average(time_s,cabinAllocated), ...
        time_average(time_s,max(batteryDemand-batteryAllocated,0)), ...
        time_average(time_s,max(cabinDuty_kW-cabinAllocated,0)), ...
        100*time_average(time_s,double(combinedDemand<=capacity)), ...
        time_average(time_s,compressorInput), ...
        'VariableNames',{'Cycle','Compressor','Capacity_kW', ...
        'AverageBatteryPlateHeatTransfer_kW','PeakBatteryPlateHeatTransfer_kW', ...
        'PeakBatteryPlateHeatTransferTime_s','CellTemperatureAtPeakRequest_C', ...
        'CabinDemand_kW', ...
        'AverageCombinedDemand_kW','PeakCombinedDemand_kW', ...
        'GrossPeakCapacityMargin_kW','GrossPeakCapacityMargin_pct', ...
        'AverageBatteryCoolingAllocated_kW','AverageCabinCoolingAllocated_kW', ...
        'AverageBatteryShortfall_kW','AverageCabinShortfall_kW', ...
        'TimeDemandWithinCapacity_pct','AverageCompressorInput_kW'});
end
out = vertcat(rows{:});
end

function average = time_average(time_s,signal)
duration_s = time_s(end)-time_s(1);
average = trapz(time_s,signal)/duration_s;
end
