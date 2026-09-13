function out = run_motor_heat_generation(cfg)
%RUN_MOTOR_HEAT_GENERATION Calculate drive-unit heat from each drive cycle.

p = cfg.motorHeat;
outputDir = fullfile(cfg.project.outputDir,"motor_heat");
ensure_output_folder(outputDir);

out.curves = load_propulsion_curves( ...
    p.files.driveLimitWorkbook,p.files.driveEfficiencyMap);
out.controllerLossReference = read_project_csv( ...
    p.files.controllerLossReference, ...
    {'OperatingPoint','OutputPower_kW','TotalControllerLoss_W', ...
    'IGBTLossPerBridgeArm_W','DiodeLossPerBridgeArm_W','EvidenceStatus'}, ...
    {'OutputPower_kW','TotalControllerLoss_W','IGBTLossPerBridgeArm_W', ...
    'DiodeLossPerBridgeArm_W'});
writetable(out.controllerLossReference,fullfile(outputDir, ...
    "controller_loss_reference_used.csv"));
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

% Drive schedules: retain the raw one-second calculation, but add a
% thermally more useful trailing 60-second average.
for i = 1:nCycles
    nexttile;
    plot(details{i}.Time_s,details{i}.DriveUnitHeat_kW, ...
        'Color',[0.72 0.80 0.88],'LineWidth',0.8, ...
        'DisplayName','One-second heat');
    hold on;
    trailing60s_kW = movmean(details{i}.DriveUnitHeat_kW,[59 0]);
    plot(details{i}.Time_s,trailing60s_kW,'Color',[0 0.447 0.741], ...
        'LineWidth',1.8,'DisplayName','Trailing 60-second mean');
    grid on;
    xlabel('Time (s)');
    ylabel('Heat generation (kW)');
    title(details{i}.Cycle(1));
    legend('Location','northwest');
end

% Accumulated energy shows the thermal burden over each drive schedule.
nexttile;
hold on;
for i = 1:nCycles
    cumulativeHeat_kWh = cumtrapz(details{i}.Time_s, ...
        details{i}.DriveUnitHeat_kW)/3600;
    plot(details{i}.Time_s,cumulativeHeat_kWh,'LineWidth',1.8, ...
        'DisplayName',details{i}.Cycle(1));
end
grid on;
xlabel('Time (s)');
ylabel('Cumulative generated heat (kWh)');
title('Drive-schedule thermal energy');
legend('Location','northwest');

% Constant operating cases are design points, not transient traces.
nexttile;
designNames = out.summary.Cycle(nCycles+(1:nCases));
designHeat_kW = out.summary.AverageDriveUnitHeat_kW(nCycles+(1:nCases));
bars = bar(categorical(designNames),designHeat_kW);
bars.FaceColor = [0.8500 0.3250 0.0980];
grid on;
ylabel('Sustained heat generation (kW)');
title('Hot-weather design cases');
ylim([0 1.15*max(designHeat_kW)]);
text(bars.XEndPoints,bars.YEndPoints, ...
    compose('%.3f kW',designHeat_kW), ...
    'HorizontalAlignment','center','VerticalAlignment','bottom');

title(layout,['Drive-unit thermal demand: instantaneous heat, ' ...
    '60-second load and accumulated energy']);
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

function ensure_output_folder(folder)
if ~isfolder(folder)
    mkdir(folder);
end
end
