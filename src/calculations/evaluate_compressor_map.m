function result = evaluate_compressor_map(mapTable, rpm, evaporatorTemperature_C)
%EVALUATE_COMPRESSOR_MAP Interpolate within a compressor performance map.
% Extrapolation is deliberately prohibited because condensing-temperature
% and superheat/subcooling boundaries are not parameterized in the table.
% A complete rectangular speed/evaporating-temperature grid is assembled
% from coordinate columns before bilinear interpolation.

validate_table_columns(mapTable,{'RPM','EvaporatorTemperature_C', ...
    'CoolingCapacity_kW','InputPower_kW','Current_A'},'compressor map');

rpmGrid = unique(mapTable.RPM);
tempGrid = unique(mapTable.EvaporatorTemperature_C);
if rpm < min(rpmGrid) || rpm > max(rpmGrid) || ...
        evaporatorTemperature_C < min(tempGrid) || evaporatorTemperature_C > max(tempGrid)
    error('EVThermal:CompressorMapExtrapolation', ...
        'Requested compressor point is outside the available map.');
end

capacityGrid = map_to_grid(mapTable,mapTable.CoolingCapacity_kW,rpmGrid,tempGrid);
powerGrid = map_to_grid(mapTable,mapTable.InputPower_kW,rpmGrid,tempGrid);
currentGrid = map_to_grid(mapTable,mapTable.Current_A,rpmGrid,tempGrid);

capacity_kW = interp2(tempGrid, rpmGrid, capacityGrid, evaporatorTemperature_C, rpm, 'linear');
inputPower_kW = interp2(tempGrid, rpmGrid, powerGrid, evaporatorTemperature_C, rpm, 'linear');
current_A = interp2(tempGrid, rpmGrid, currentGrid, evaporatorTemperature_C, rpm, 'linear');
result = table(rpm, evaporatorTemperature_C, capacity_kW, inputPower_kW, current_A, ...
    capacity_kW/inputPower_kW, ...
    'VariableNames', {'RPM','EvaporatorTemperature_C','CoolingCapacity_kW', ...
    'InputPower_kW','Current_A','CalculatedCOP_WW'});
end

function grid = map_to_grid(mapTable,values,rpmGrid,tempGrid)
[~,rpmIndex] = ismember(mapTable.RPM,rpmGrid);
[~,tempIndex] = ismember(mapTable.EvaporatorTemperature_C,tempGrid);
grid = nan(numel(rpmGrid),numel(tempGrid));
linearIndex = sub2ind(size(grid),rpmIndex,tempIndex);
if numel(unique(linearIndex))~=height(mapTable)
    error('EVThermal:DuplicateMapPoint', ...
        'Compressor map contains duplicate speed/temperature coordinates.');
end
grid(linearIndex) = values;
if any(isnan(grid),'all')
    error('EVThermal:IncompleteMap', ...
        'Compressor map must contain a complete rectangular grid.');
end
end
