function out = run_battery_cycle_heat(cfg,motorHeat,selection)
%RUN_BATTERY_CYCLE_HEAT Battery heat for the selected drive cycles.
% selection is "all" or a list of cycle file stems, for example
%   out = run_battery_cycle_heat(cfg,results.motorHeat,["highway_cycle","sustained_grade"]);
% Without a selection, cfg.batteryCooling.cycleSelection is used.
% Available stems: the drive schedules in cfg.cycles plus the hot-weather
% operating cases in cfg.motorHeat.operatingCases.

if nargin < 3
    selection = cfg.batteryCooling.cycleSelection;
end
battery = cfg.batteryCooling;
outputDir = fullfile(cfg.project.outputDir,"battery_cooling");
if ~isfolder(outputDir)
    mkdir(outputDir);
end

index = select_cycles(selection,motorHeat.fileStems);
out.selection = motorHeat.fileStems(index);
out.traces = cell(numel(index),1);
rows = cell(numel(index),1);
for j = 1:numel(index)
    i = index(j);
    trace = calculate_battery_cycle_heat(motorHeat.details{i},battery);
    out.traces{j} = trace;
    rows{j} = summarize_trace(trace,motorHeat.fileStems(i));
    writetable(trace,fullfile(outputDir, ...
        motorHeat.fileStems(i)+"_battery_heat_trace.csv"));
end
out.summary = vertcat(rows{:});
writetable(out.summary,fullfile(outputDir,"battery_cycle_heat_summary.csv"));
plot_cycle_heat(out,outputDir);
end

function index = select_cycles(selection,stems)
selection = string(selection);
if isscalar(selection) && lower(selection)=="all"
    index = (1:numel(stems))';
    return
end
[found,index] = ismember(selection(:),stems);
if ~all(found)
    error('EVThermal:UnknownCycle', ...
        'Unknown drive cycle: %s. Available: %s.', ...
        strjoin(selection(~found),', '),strjoin(stems,', '));
end
end

function row = summarize_trace(trace,stem)
t = trace.Time_s;
duration_s = t(end)-t(1);
meanOf = @(x) trapz(t,x)/duration_s;
trailing = @(x) max(movmean(x,[59 0]));
row = table(trace.Cycle(1),stem,duration_s, ...
    meanOf(abs(trace.C_rate)),max(abs(trace.C_rate)),trace.SOC_pct(end), ...
    meanOf(trace.BatteryHeat_kW),max(trace.BatteryHeat_kW), ...
    trailing(trace.BatteryHeat_kW),trapz(t,trace.BatteryHeat_kW)/3600, ...
    meanOf(trace.BatteryHeatUpperBound_kW),max(trace.BatteryHeatUpperBound_kW), ...
    meanOf(trace.DriveUnitHeat_kW), ...
    meanOf(trace.BatteryHeat_kW+trace.DriveUnitHeat_kW), ...
    meanOf(trace.BatteryHeatUpperBound_kW+trace.DriveUnitHeat_kW), ...
    'VariableNames',{'Cycle','FileStem','Duration_s','MeanAbsC_rate', ...
    'PeakAbsC_rate','FinalSOC_pct','MeanBatteryHeat_kW', ...
    'PeakOneSecondBatteryHeat_kW','MaxTrailing60sBatteryHeat_kW', ...
    'BatteryHeatEnergy_kWh','MeanBatteryHeatUpperBound_kW', ...
    'PeakBatteryHeatUpperBound_kW','MeanDriveUnitHeat_kW', ...
    'MeanCombinedHeat_kW','MeanCombinedHeatUpperBound_kW'});
end

function plot_cycle_heat(out,outputDir)
n = numel(out.traces);
fig = figure('Visible','off','Color','w','Position',[100 100 1300 380*ceil((n+1)/2)]);
layout = tiledlayout(ceil((n+1)/2),2,'TileSpacing','compact');
for j = 1:n
    trace = out.traces{j};
    nexttile;
    plot(trace.Time_s,trace.BatteryHeat_kW,'Color',[0.70 0.80 0.92], ...
        'LineWidth',0.8,'DisplayName','Expected, one-second');
    hold on;
    plot(trace.Time_s,movmean(trace.BatteryHeat_kW,[59 0]),'Color',[0 0.447 0.741], ...
        'LineWidth',1.8,'DisplayName','Expected, trailing 60 s mean');
    plot(trace.Time_s,movmean(trace.BatteryHeatUpperBound_kW,[59 0]),'--', ...
        'Color',[0.85 0.15 0.15],'LineWidth',1.4, ...
        'DisplayName','Highest possible, trailing 60 s mean');
    yline(0,'k:','HandleVisibility','off');
    grid on;
    xlabel('Time (s)');
    ylabel('Pack heat (kW)');
    title(sprintf('%s: start SOC %.0f%%, end %.0f%%',trace.Cycle(1), ...
        trace.SOC_pct(1),trace.SOC_pct(end)));
    legend('Location','northwest','FontSize',7);
end

nexttile;
s = out.summary;
data = [s.MeanDriveUnitHeat_kW s.MeanBatteryHeat_kW ...
    s.MeanBatteryHeatUpperBound_kW-s.MeanBatteryHeat_kW];
bars = bar(categorical(s.Cycle,s.Cycle),data,'stacked');
bars(1).FaceColor = [0.85 0.33 0.10];
bars(2).FaceColor = [0 0.447 0.741];
bars(3).FaceColor = [0.95 0.75 0.75];
totals = s.MeanCombinedHeat_kW;
text(1:height(s),totals,compose(' %.2f kW',totals), ...
    'HorizontalAlignment','center','VerticalAlignment','bottom');
grid on;
ylabel('Mean heat to the coolant loops (kW)');
legend({'Drive unit','Battery, expected','Battery, extra up to highest possible'}, ...
    'Location','northwest','FontSize',7);
title('Mean heat per cycle: drive unit plus battery');
title(layout,'Battery heat driven by the drive cycles (expected and highest possible)');
exportgraphics(fig,fullfile(outputDir,"battery_cycle_heat.png"),'Resolution',180);
close(fig);
end
