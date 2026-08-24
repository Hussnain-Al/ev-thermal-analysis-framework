function out = analyze_drive_cycles(cycleDefinitions, model, outputDir)
%ANALYZE_DRIVE_CYCLES Run, summarize and export multiple drive cycles.
% cycleDefinitions is a table with Name, FileStem and File columns. model contains
% vehicle, battery, propulsion curves, compressor candidates, cabin duty
% and initial battery/coolant temperatures. This is the single integrated
% entry point for transient thermal analysis.

arguments
    cycleDefinitions table
    model struct
    outputDir (1,1) string
end

nCycles = height(cycleDefinitions);
details = cell(nCycles,1);
summaries = cell(nCycles,1);
compressorChecks = cell(nCycles,1);

for i = 1:nCycles
    cycle = read_drive_cycle(cycleDefinitions.File(i),cycleDefinitions.Name(i));
    trace = calculate_drive_cycle_thermal( ...
        cycle,model.vehicle,model.battery,model.propulsionCurves);
    trace = simulate_battery_thermal_state( ...
        trace,model.battery,model.coolantTemperature_C, ...
        model.initialBatteryTemperature_C);

    details{i} = trace;
    summaries{i} = summarize_drive_cycle(trace);
    compressorChecks{i} = calculate_cycle_compressor_check( ...
        trace,model.compressorCandidates,model.cabinDuty_kW, ...
        model.allocationPriority);

    if ismember('FileStem',cycleDefinitions.Properties.VariableNames)
        fileStem = cycleDefinitions.FileStem(i);
    else
        fileStem = lower(strrep(cycleDefinitions.Name(i),' ','_'));
    end
    writetable(trace,fullfile(outputDir,fileStem+"_transient_results.csv"));
end

out.summary = vertcat(summaries{:});
out.compressor = vertcat(compressorChecks{:});
out.details = details;
writetable(out.summary,fullfile(outputDir,'drive_cycle_thermal_summary.csv'));
writetable(out.compressor,fullfile(outputDir,'drive_cycle_compressor_comparison.csv'));
writetable(model.compressorCandidates, ...
    fullfile(outputDir,'compressor_candidate_specifications.csv'));

plot_thermal_traces(details,cycleDefinitions.Name,outputDir);
end

function plot_thermal_traces(details,names,outputDir)
fig = figure('Visible','off','Color','w');
layout = tiledlayout(numel(details),2,'TileSpacing','compact');
for i = 1:numel(details)
    nexttile;
    plot(details{i}.Time_s,details{i}.DriveUnitHeat_kW,'LineWidth',1.1);
    grid on; ylabel('Drive heat (kW)'); title(names(i));
    nexttile;
    plot(details{i}.Time_s,details{i}.BatteryHeat_kW,'LineWidth',1.1);
    grid on; ylabel('Battery heat (kW)'); title(names(i));
end
xlabel(layout,'Time (s)');
exportgraphics(fig,fullfile(outputDir,'drive_cycle_thermal_traces.png'), ...
    'Resolution',180);
close(fig);
end
