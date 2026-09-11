function out = run_motor_heat_generation(cfg)
%RUN_MOTOR_HEAT_GENERATION Calculate drive-unit heat from each drive cycle.

p = cfg.motorHeat;
outputDir = fullfile(cfg.project.outputDir,"motor_heat");
ensure_output_folder(outputDir);

out.curves = load_propulsion_curves( ...
    p.files.driveLimitWorkbook,p.files.driveEfficiencyMap);
nCycles = height(cfg.cycles);
details = cell(nCycles,1);
summaries = cell(nCycles,1);

for i = 1:nCycles
    cycle = read_drive_cycle(cfg.cycles.File(i),cfg.cycles.Name(i));
    details{i} = calculate_motor_operating_trace( ...
        cycle,cfg.vehicle,out.curves);
    summaries{i} = summarize_motor_heat(details{i});
    writetable(details{i},fullfile(outputDir, ...
        cfg.cycles.FileStem(i)+"_motor_heat_trace.csv"));
end

out.details = details;
out.summary = vertcat(summaries{:});
writetable(out.summary,fullfile(outputDir,"motor_heat_summary.csv"));

fig = figure('Visible','off','Color','w');
layout = tiledlayout(nCycles,1,'TileSpacing','compact');
maximumHeat_kW = max(cellfun(@(x) max(x.DriveUnitHeat_kW),details));
for i = 1:nCycles
    nexttile;
    plot(details{i}.Time_s,details{i}.DriveUnitHeat_kW,'LineWidth',1.1);
    hold on;
    mark_extrema(details{i}.Time_s,details{i}.DriveUnitHeat_kW);
    grid on;
    ylabel('Heat (kW)');
    ylim([0 1.08*maximumHeat_kW]);
    title(cfg.cycles.Name(i));
end
xlabel(layout,'Time (s)');
exportgraphics(fig,fullfile(outputDir,"motor_heat_traces.png"), ...
    'Resolution',180);
close(fig);
end

function mark_extrema(time_s,signal)
[maximumValue,maximumIndex] = max(signal);
[minimumValue,minimumIndex] = min(signal);
plot(time_s(maximumIndex),maximumValue,'ro','MarkerFaceColor','r');
plot(time_s(minimumIndex),minimumValue,'bo','MarkerFaceColor','b');
text(time_s(maximumIndex),maximumValue, ...
    sprintf(' max %.3f kW @ %.0f s',maximumValue,time_s(maximumIndex)), ...
    'VerticalAlignment','bottom');
text(time_s(minimumIndex),minimumValue, ...
    sprintf(' min %.3f kW @ %.0f s',minimumValue,time_s(minimumIndex)), ...
    'VerticalAlignment','bottom');
end

function ensure_output_folder(folder)
if ~isfolder(folder)
    mkdir(folder);
end
end
