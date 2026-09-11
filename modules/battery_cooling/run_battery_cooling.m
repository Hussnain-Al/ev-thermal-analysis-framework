function out = run_battery_cooling(cfg,motorHeat)
%RUN_BATTERY_COOLING Battery heat, temperature and plate-demand module.
% The module consumes the motor module's DC-link power traces. It does not
% access cabin or compressor parameters.

p = cfg.batteryCooling;
outputDir = fullfile(cfg.project.outputDir,"battery_cooling");
ensure_output_folder(outputDir);

nCycles = numel(motorHeat.details);
details = cell(nCycles,1);
summaries = cell(nCycles,1);
for i = 1:nCycles
    details{i} = calculate_battery_thermal_trace(motorHeat.details{i},p);
    summaries{i} = summarize_battery_cooling(details{i},p);
    exported = battery_trace_columns(details{i});
    writetable(exported,fullfile(outputDir, ...
        cfg.cycles.FileStem(i)+"_battery_cooling_trace.csv"));
end
out.details = details;
out.summary = vertcat(summaries{:});

out.sensitivity = calculate_battery_ohmic_heat( ...
    p.cRates,p.capacity_Ah,p.resistanceProxy_Ohm,p.seriesCells);
network = calculate_battery_thermal_network(out.sensitivity.CellHeat_W, ...
    p.baseResistance_KW,p.sideResistance_KW_each);
out.sensitivity = [out.sensitivity network(:,2:end)];
out.sensitivity.BasePathSteadyCell_C = ...
    p.coolantTemperature_C+out.sensitivity.BasePathRequiredRise_C;
out.sensitivity.SustainedBasePathWithinLimit = ...
    out.sensitivity.BasePathSteadyCell_C<=p.maximumCell_C;

out.vehicleCases = read_project_csv(p.files.vehicleLoadCases, ...
    {'LoadCase','Description','WheelPower_W','MotorPower_W','Current_A','Status'}, ...
    {'WheelPower_W','MotorPower_W','Current_A'});
out.vehicleCases.C_rate = out.vehicleCases.Current_A/p.capacity_Ah;
out.vehicleCases.MinimumResistivePackHeat_kW = ...
    out.vehicleCases.Current_A.^2*p.resistanceProxy_Ohm*p.seriesCells/1000;
out.heatExchangerGeometry = read_project_csv(p.files.heatExchangerGeometry, ...
    radiator_geometry_columns(),radiator_geometry_numeric_columns());

writetable(out.summary,fullfile(outputDir,"battery_cooling_summary.csv"));
writetable(out.sensitivity,fullfile(outputDir, ...
    "battery_constant_current_sensitivity.csv"));
writetable(out.vehicleCases,fullfile(outputDir,"battery_reference_cases.csv"));
writetable(out.heatExchangerGeometry,fullfile(outputDir, ...
    "battery_heat_exchanger_geometry.csv"));
plot_battery_results(details,cfg.cycles.Name,p,outputDir);
end

function exported = battery_trace_columns(trace)
names = {'Cycle','Time_s','BatteryPower_kW','PackCurrent_A', ...
    'BatteryHeat_kW','EstimatedCellTemperature_C', ...
    'BatteryCoolingActive','BatteryCoolingRequest_kW'};
exported = trace(:,names);
end

function plot_battery_results(details,names,battery,outputDir)
fig = figure('Visible','off','Color','w','Position',[100 100 1500 850]);
layout = tiledlayout(numel(details),3,'TileSpacing','compact');
maximumHeat_kW = max(cellfun(@(x) max(x.BatteryHeat_kW),details));
maximumRequest_kW = max(cellfun(@(x) max(x.BatteryCoolingRequest_kW),details));
for i = 1:numel(details)
    nexttile;
    plot(details{i}.Time_s,details{i}.BatteryHeat_kW,'LineWidth',1.1);
    hold on;
    mark_extrema(details{i}.Time_s,details{i}.BatteryHeat_kW);
    grid on;
    ylabel('Heat (kW)');
    ylim([0 1.08*maximumHeat_kW]);
    title(names(i)+" battery heat");

    nexttile;
    plot(details{i}.Time_s,details{i}.BatteryCoolingRequest_kW, ...
        'LineWidth',1.1);
    hold on;
    mark_extrema(details{i}.Time_s,details{i}.BatteryCoolingRequest_kW);
    grid on;
    ylabel('Plate request (kW)');
    ylim([0 1.08*maximumRequest_kW]);
    title(names(i)+" cooling request");

    nexttile;
    plot(details{i}.Time_s,details{i}.EstimatedCellTemperature_C, ...
        'LineWidth',1.1);
    hold on;
    plot(details{i}.Time_s(1),details{i}.EstimatedCellTemperature_C(1), ...
        'ko','MarkerFaceColor','k');
    plot(details{i}.Time_s(end),details{i}.EstimatedCellTemperature_C(end), ...
        'ks','MarkerFaceColor','w');
    grid on;
    ylabel('Cell temperature (C)');
    margin_C = battery.maximumCell_C- ...
        max(details{i}.EstimatedCellTemperature_C);
    title(sprintf('%s cell temperature | %.1f C margin', ...
        names(i),margin_C));
end
xlabel(layout,'Time (s)');
exportgraphics(fig,fullfile(outputDir,"battery_cooling_traces.png"), ...
    'Resolution',180);
close(fig);
end

function mark_extrema(time_s,signal)
[maximumValue,maximumIndex] = max(signal);
[minimumValue,minimumIndex] = min(signal);
plot(time_s(maximumIndex),maximumValue,'ro','MarkerFaceColor','r');
plot(time_s(minimumIndex),minimumValue,'bo','MarkerFaceColor','b');
text(time_s(maximumIndex),maximumValue, ...
    sprintf(' max %.3f @ %.0f s',maximumValue,time_s(maximumIndex)), ...
    'VerticalAlignment','bottom');
text(time_s(minimumIndex),minimumValue, ...
    sprintf(' min %.3f @ %.0f s',minimumValue,time_s(minimumIndex)), ...
    'VerticalAlignment','bottom');
end

function names = radiator_geometry_columns()
names = {'Radiator','Application','CoreHeight_mm','CoreWidth_mm', ...
    'FrontalArea_m2','TubeWidth_mm','TubeThickness_mm','TubeQuantity', ...
    'TubeLength_mm','FinWidth_mm','FinHeight_mm','FinPitch_mm', ...
    'FinQuantity','FinLength_mm'};
end

function names = radiator_geometry_numeric_columns()
names = {'CoreHeight_mm','CoreWidth_mm','FrontalArea_m2','TubeWidth_mm', ...
    'TubeThickness_mm','TubeQuantity','TubeLength_mm','FinWidth_mm', ...
    'FinHeight_mm','FinPitch_mm','FinQuantity','FinLength_mm'};
end

function ensure_output_folder(folder)
if ~isfolder(folder)
    mkdir(folder);
end
end
