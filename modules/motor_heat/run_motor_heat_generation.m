function out = run_motor_heat_generation(cfg)
%RUN_MOTOR_HEAT_GENERATION Calculate drive-unit heat from each drive cycle.

p = cfg.motorHeat;
outputDir = fullfile(cfg.project.outputDir,"motor_heat");
ensure_output_folder(outputDir);

out.curves = load_propulsion_curves( ...
    p.files.driveLimitWorkbook,p.files.driveEfficiencyMap);
nCycles = height(cfg.cycles);
nCases = height(p.operatingCases);
details = cell(nCycles+nCases,1);
summaries = cell(nCycles+nCases,1);
fileStems = [cfg.cycles.FileStem;p.operatingCases.FileStem];

for i = 1:nCycles
    cycle = read_drive_cycle(cfg.cycles.File(i),cfg.cycles.Name(i));
    details{i} = calculate_motor_operating_trace( ...
        cycle,cfg.vehicle,out.curves);
    summaries{i} = summarize_motor_heat(details{i});
    writetable(details{i},fullfile(outputDir, ...
        cfg.cycles.FileStem(i)+"_motor_heat_trace.csv"));
end

for j = 1:nCases
    i = nCycles+j;
    caseInput = p.operatingCases(j,:);
    cycle = make_constant_speed_case(caseInput);
    caseVehicle = cfg.vehicle;
    caseVehicle.grade_pct = caseInput.Grade_pct;
    details{i} = calculate_motor_operating_trace(cycle,caseVehicle,out.curves);
    summaries{i} = summarize_motor_heat(details{i});
    writetable(details{i},fullfile(outputDir, ...
        caseInput.FileStem+"_motor_heat_trace.csv"));
end

out.details = details;
out.summary = vertcat(summaries{:});
writetable(out.summary,fullfile(outputDir,"motor_heat_summary.csv"));

out.fileStems = fileStems;
out.ambient_C = [repmat(cfg.motorCooling.transient.designAmbient_C,nCycles,1); ...
    p.operatingCases.Ambient_C];
out.fanOnly = [false(nCycles,1);p.operatingCases.FanOnly];

fig = figure('Visible','off','Color','w','Position',[100 100 1250 820]);
layout = tiledlayout(2,2,'TileSpacing','compact');
maximumHeat_kW = max(cellfun(@(x) max(x.DriveUnitHeat_kW),details));
for i = 1:numel(details)
    nexttile;
    plot(details{i}.Time_s,details{i}.DriveUnitHeat_kW,'LineWidth',1.1);
    hold on;
    mark_extrema(details{i}.Time_s,details{i}.DriveUnitHeat_kW);
    grid on;
    ylabel('Heat (kW)');
    ylim([0 1.08*maximumHeat_kW]);
    title(details{i}.Cycle(1));
end
xlabel(layout,'Time (s)');
exportgraphics(fig,fullfile(outputDir,"motor_heat_traces.png"), ...
    'Resolution',180);
close(fig);
end

function cycle = make_constant_speed_case(caseInput)
time_s = (0:caseInput.Duration_s)';
speed_mph = repmat(caseInput.Speed_kmh/1.609344,numel(time_s),1);
cycle = table(repmat(caseInput.Name,numel(time_s),1),time_s,speed_mph, ...
    speed_mph*0.44704, ...
    'VariableNames',{'Cycle','Time_s','Speed_mph','Speed_ms'});
end

function mark_extrema(time_s,signal)
[maximumValue,maximumIndex] = max(signal);
[minimumValue,minimumIndex] = min(signal);
if abs(maximumValue-minimumValue) <= ...
        max(1e-12,eps(max(abs(signal))))
    plot(time_s(1),maximumValue,'ko','MarkerFaceColor','k');
    text(time_s(1),maximumValue, ...
        sprintf(' constant %.3f kW',maximumValue), ...
        'VerticalAlignment','bottom');
    return;
end
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
