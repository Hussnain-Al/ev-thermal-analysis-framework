function out = run_motor_cooling(cfg,motorHeat)
%RUN_MOTOR_COOLING Transient propulsion thermal and hydraulic screens.

p = cfg.motorCooling.transient;
c = cfg.motorCooling.coolant;
g = cfg.motorCooling.loop;
pump = cfg.motorCooling.pump;
outputDir = fullfile(cfg.project.outputDir,"motor_cooling");
ensure_output_folder(outputDir);

nCases = numel(motorHeat.details);
out.details = cell(nCases,1);
summaries = cell(nCases,1);
for i = 1:nCases
    caseParameters = p;
    if motorHeat.fanOnly(i)
        caseParameters.radiatorUA_WK = p.fanOnlyRadiatorUA_WK;
    end
    out.details{i} = simulate_motor_coolant_thermal( ...
        motorHeat.details{i},motorHeat.ambient_C(i),caseParameters);
    summaries{i} = summarize_thermal_case(out.details{i},caseParameters);
    writetable(out.details{i},fullfile(outputDir, ...
        motorHeat.fileStems(i)+"_motor_thermal_trace.csv"));
end
out.summary = vertcat(summaries{:});
out.hydraulics = evaluate_hydraulics(g,c,pump, ...
    cfg.motorCooling.files.inactivePumpCurve, ...
    cfg.motorCooling.files.componentPressureDrop);
out.radiatorCandidate = read_radiator_geometry( ...
    cfg.motorCooling.files.radiatorGeometry);
designRows = nCases-height(cfg.motorHeat.operatingCases)+(1:height( ...
    cfg.motorHeat.operatingCases));
coolantRow = c(c.Temperature_C==cfg.motorCooling.thermal.propertyTemperature_C,:);
out.radiatorDesign = calculate_radiator_design_requirements( ...
    motorHeat.summary.Cycle(designRows), ...
    motorHeat.summary.AverageDriveUnitHeat_kW(designRows), ...
    cfg.motorCooling.thermal, ...
    coolantRow,out.radiatorCandidate.FrontalArea_m2(1));
out.radiatorAirsideSensitivity = calculate_radiator_airside_sensitivity( ...
    motorHeat.summary.Cycle(designRows), ...
    motorHeat.summary.AverageDriveUnitHeat_kW(designRows), ...
    cfg.motorCooling.thermal.airTemperatureRiseSensitivity_C, ...
    cfg.motorCooling.thermal,coolantRow, ...
    out.radiatorCandidate.FrontalArea_m2(1));

writetable(out.summary,fullfile(outputDir,"motor_thermal_summary.csv"));
writetable(out.hydraulics.nominalSegments, ...
    fullfile(outputDir,"loop_segments.csv"));
writetable(out.hydraulics.sensitivity, ...
    fullfile(outputDir,"loop_sensitivity.csv"));
writetable(out.hydraulics.pumpCheck, ...
    fullfile(outputDir,"pump_operating_point.csv"));
writetable(out.hydraulics.componentLosses, ...
    fullfile(outputDir,"component_pressure_drop.csv"));
writetable(out.radiatorCandidate, ...
    fullfile(outputDir,"radiator_candidate_geometry.csv"));
writetable(out.radiatorDesign, ...
    fullfile(outputDir,"radiator_design_requirements.csv"));
writetable(out.radiatorAirsideSensitivity, ...
    fullfile(outputDir,"radiator_airside_sensitivity.csv"));

plot_motor_thermal_response(out.details,p,outputDir);
plot_hydraulic_sensitivity(out.hydraulics,c,pump,outputDir);
plot_radiator_design_requirements( ...
    out.radiatorAirsideSensitivity,cfg.motorCooling.thermal,outputDir);
end

function summary = summarize_thermal_case(trace,p)
duration_s = trace.Time_s(end)-trace.Time_s(1);
generated_kWh = trapz(trace.Time_s,trace.DriveUnitHeat_kW)/3600;
rejected_kWh = trapz(trace.Time_s,trace.RadiatorHeatRejection_kW)/3600;
stored_kWh = ( ...
    p.motorThermalCapacity_JK*(trace.MotorTemperature_C(end)- ...
        trace.MotorTemperature_C(1))+ ...
    p.coolantThermalCapacity_JK*(trace.CoolantTemperature_C(end)- ...
        trace.CoolantTemperature_C(1)))/3.6e6;
summary = table(trace.Case(1),duration_s,trace.Ambient_C(1), ...
    max(trace.DriveUnitHeat_kW),max(trace.MotorTemperature_C), ...
    max(trace.CoolantTemperature_C),generated_kWh,rejected_kWh,stored_kWh, ...
    generated_kWh-rejected_kWh-stored_kWh, ...
    p.motorThermalCapacity_JK,p.coolantThermalCapacity_JK, ...
    p.motorToCoolantResistance_KW,p.radiatorUA_WK,string(p.modelBoundary), ...
    'VariableNames',{'Case','Duration_s','Ambient_C','PeakHeat_kW', ...
    'PeakMotorTemperature_C','PeakCoolantTemperature_C', ...
    'GeneratedHeat_kWh','RadiatorRejectedHeat_kWh','StoredHeatChange_kWh', ...
    'EnergyBalanceResidual_kWh','AssumedMotorThermalCapacity_JK', ...
    'AssumedCoolantThermalCapacity_JK','AssumedMotorToCoolantResistance_KW', ...
    'AssumedRadiatorUA_WK','ModelBoundary'});
end

function out = evaluate_hydraulics(g,c,pump,inactivePumpCurveFile,componentFile)
components = read_project_csv(componentFile, ...
    {'Component','Flow_Lmin','PressureDrop_kPa','EvidenceStatus'}, ...
    {'Flow_Lmin','PressureDrop_kPa'});
out.componentData = components;
flows = g.flowCases_Lmin;
summaryTables = cell(height(c),1);
for j = 1:height(c)
    local = cell(numel(flows),1);
    for i = 1:numel(flows)
        [segments,summary] = calculate_cooling_loop_losses( ...
            g,flows(i),c.Density_kgm3(j),c.Viscosity_Pas(j));
        summary.CoolantCase = repmat(string(sprintf('%d C', ...
            c.Temperature_C(j))),height(summary),1);
        summary.Temperature_C = repmat(c.Temperature_C(j),height(summary),1);
        [~,summary.SupplierComponentLoss_kPa] = ...
            calculate_component_pressure_drop(components,flows(i));
        summary.LoopLoss_kPa = summary.HoseAndFittingLoss_kPa+ ...
            summary.SupplierComponentLoss_kPa;
        local{i} = summary;
        if c.Temperature_C(j)==g.nominalTemperature_C && ...
                flows(i)==g.nominalFlow_Lmin
            out.nominalSegments = segments;
        end
    end
    summaryTables{j} = vertcat(local{:});
end
out.sensitivity = vertcat(summaryTables{:});

pumpRows = out.sensitivity( ...
    out.sensitivity.Flow_Lmin==pump.referenceFlow_Lmin & ...
    out.sensitivity.Temperature_C==pump.checkTemperature_C,:);
if height(pumpRows)~=1
    error('EVThermal:MissingPumpCheckCase', ...
        'One result is required at %.1f L/min and %.1f C.', ...
        pump.referenceFlow_Lmin,pump.checkTemperature_C);
end
pumpRow = pumpRows(1,:);
[out.componentLosses,componentLoss_kPa] = ...
    calculate_component_pressure_drop(components,pump.referenceFlow_Lmin);
loopLoss_kPa = pumpRow.HoseAndFittingLoss_kPa+componentLoss_kPa;
headRemaining_kPa = pump.minimumHead_kPa-loopLoss_kPa;
coversLoop = headRemaining_kPa>=0;

% Flow at which hoses plus supplier components use the documented head. The
% pump curve is not available, so this is the flow the documented point
% guarantees, not the operating point.
property = c(c.Temperature_C==pump.checkTemperature_C,:);
searchLoss_kPa = zeros(numel(pump.flowSearch_Lmin),1);
for i = 1:numel(pump.flowSearch_Lmin)
    q = pump.flowSearch_Lmin(i);
    [~,hose] = calculate_cooling_loop_losses(g,q, ...
        property.Density_kgm3,property.Viscosity_Pas);
    [~,component_kPa] = calculate_component_pressure_drop(components,q);
    searchLoss_kPa(i) = hose.HoseAndFittingLoss_kPa+component_kPa;
end
out.loopCurve = table(pump.flowSearch_Lmin,searchLoss_kPa, ...
    'VariableNames',{'Flow_Lmin','LoopLoss_kPa'});
flowAtHead_Lmin = interp1(searchLoss_kPa,pump.flowSearch_Lmin, ...
    pump.minimumHead_kPa,'linear');
if coversLoop
    conclusion = "Documented point covers hoses and supplier component losses; radiator loss excluded";
else
    conclusion = "Hoses plus supplier component losses exceed the documented head at the design flow; the pump curve decides the real flow";
end
out.pumpCheck = table(pump.referenceFlow_Lmin,pump.minimumHead_kPa, ...
    pumpRow.Temperature_C,pumpRow.HoseMajorLoss_kPa, ...
    pumpRow.FittingMinorLoss_kPa,pumpRow.HoseAndFittingLoss_kPa, ...
    componentLoss_kPa,loopLoss_kPa,headRemaining_kPa,coversLoop, ...
    flowAtHead_Lmin,conclusion, ...
    'VariableNames',{'SpecifiedFlow_Lmin','SpecifiedMinimumHead_kPa', ...
    'OperatingCoolantTemperature_C','HoseMajorLoss_kPa', ...
    'FittingMinorLoss_kPa','ModeledHoseAndFittingLoss_kPa', ...
    'SupplierComponentLoss_kPa','LoopLoss_kPa','HeadRemaining_kPa', ...
    'DocumentedPointCoversLoop','FlowAtDocumentedHead_Lmin','Conclusion'});

% Preserve and validate the inactive-pump source curve without including it
% in the active-loop decision.
out.inactivePumpCurve = read_project_csv(inactivePumpCurveFile, ...
    {'Flow_Lmin','Flow_Lh','InactivePumpResistance_kPa', ...
     'DigitizationUncertainty_kPa','EvidenceStatus'}, ...
    {'Flow_Lmin','Flow_Lh','InactivePumpResistance_kPa', ...
     'DigitizationUncertainty_kPa'});
end

function plot_motor_thermal_response(details,p,outputDir)
nTiles = numel(details);
fig = figure('Visible','off','Color','w','Position',[100 100 1250 410*ceil(nTiles/2)]);
layout = tiledlayout(ceil(nTiles/2),2,'TileSpacing','compact');
for i = 1:nTiles
    nexttile;
    plot(details{i}.Time_s,details{i}.MotorTemperature_C, ...
        'LineWidth',1.4,'DisplayName','Winding');
    hold on;
    plot(details{i}.Time_s,details{i}.CoolantTemperature_C, ...
        'LineWidth',1.4,'DisplayName','Coolant');
    yline(details{i}.Ambient_C(1),':','Ambient','HandleVisibility','off');
    yline(150,':','150 C hot-spot target','HandleVisibility','off');
    grid on;
    ylabel('Temperature (C)');
    title(details{i}.Case(1));
    legend('Location','best');
end
xlabel(layout,'Time (s)');
title(layout,sprintf(['Two-node screen: winding R %.4f K/W and C %.1f kJ/K from ' ...
    'the supplier rated point and heating curve; core UA %.0f/%.0f W/K ' ...
    '(normal/fan-only)'],p.motorToCoolantResistance_KW, ...
    p.motorThermalCapacity_JK/1000,p.radiatorUA_WK,p.fanOnlyRadiatorUA_WK));
exportgraphics(fig,fullfile(outputDir,"motor_thermal_response.png"), ...
    'Resolution',180);
close(fig);
end

function plot_hydraulic_sensitivity(hydraulics,c,pump,outputDir)
sensitivity = hydraulics.sensitivity;
passiveCurve = hydraulics.inactivePumpCurve;
fig = figure('Visible','off','Color','w','Position',[100 100 1200 500]);
layout = tiledlayout(1,2,'TileSpacing','compact');

nexttile;
hold on;
labels = strings(height(c),1);
palette = [0 0.447 0.741;0.85 0.33 0.10;0.47 0.67 0.19];
for j = 1:height(c)
    rows = sensitivity.Temperature_C==c.Temperature_C(j);
    plot(sensitivity.Flow_Lmin(rows),sensitivity.LoopLoss_kPa(rows), ...
        'o-','LineWidth',1.5,'Color',palette(j,:));
    labels(j) = string(sprintf('Hoses + supplier components, %d C',c.Temperature_C(j)));
end
hotRows = sensitivity.Temperature_C==pump.checkTemperature_C;
plot(sensitivity.Flow_Lmin(hotRows),sensitivity.HoseAndFittingLoss_kPa(hotRows), ...
    '--','Color',[0.5 0.5 0.5],'LineWidth',1.3);
labels(end+1) = sprintf('Hoses and fittings only, %d C',pump.checkTemperature_C);
plot(pump.referenceFlow_Lmin,pump.minimumHead_kPa,'rp', ...
    'MarkerSize',13,'MarkerFaceColor','r');
labels(end+1) = "Pump datasheet: 20 L/min at 60 kPa or more";
check = hydraulics.pumpCheck;
plot(check.FlowAtDocumentedHead_Lmin,pump.minimumHead_kPa,'kd', ...
    'MarkerSize',9,'MarkerFaceColor','k');
labels(end+1) = sprintf('Loop reaches 60 kPa at %.1f L/min (%d C)', ...
    check.FlowAtDocumentedHead_Lmin,pump.checkTemperature_C);
grid on;
xlabel('Coolant flow (L/min)');
ylabel('Pressure loss (kPa)');
xlim([min(sensitivity.Flow_Lmin) pump.referenceFlow_Lmin+1]);
ylim([0 1.25*max(sensitivity.LoopLoss_kPa)]);
legend(labels,'Location','northwest','FontSize',7);
title(sprintf('Loop loss at %d L/min and %d C: %.1f kPa against 60 kPa', ...
    pump.referenceFlow_Lmin,pump.checkTemperature_C,check.LoopLoss_kPa));

nexttile;
errorbar(passiveCurve.Flow_Lmin, ...
    passiveCurve.InactivePumpResistance_kPa, ...
    passiveCurve.DigitizationUncertainty_kPa,'o-', ...
    'LineWidth',1.5,'MarkerFaceColor',[0.8500 0.3250 0.0980]);
grid on;
xlabel('Coolant flow (L/min)');
ylabel('Passive pressure loss (kPa)');
xlim([0 max(passiveCurve.Flow_Lmin)]);
ylim([0 1.08*max(passiveCurve.InactivePumpResistance_kPa)]);
title('Supplied stopped-pump resistance evidence');

title(layout,['Hydraulics with supplier MCU, motor and PDU/OBC/DCDC ' ...
    'losses; the active pump curve and radiator loss are not supplied']);
exportgraphics(fig,fullfile(outputDir,"loop_sensitivity.png"), ...
    'Resolution',180);
close(fig);
end

function plot_radiator_design_requirements(sensitivity,thermal,outputDir)
fig = figure('Visible','off','Color','w','Position',[100 100 1150 480]);
layout = tiledlayout(1,2,'TileSpacing','compact');
caseNames = unique(sensitivity.Case,'stable');

nexttile;
hold on;
for i = 1:numel(caseNames)
    rows = sensitivity.Case==caseNames(i);
    plot(sensitivity.AirTemperatureRise_C(rows), ...
        sensitivity.RequiredCoreFaceVelocity_ms(rows),'o-', ...
        'LineWidth',1.6,'DisplayName',caseNames(i));
end
xline(thermal.airOut_C-thermal.airIn_C,':','10 C baseline', ...
    'HandleVisibility','off');
grid on;
ylabel('Required core-face velocity (m/s)');
xlabel('Assumed air temperature rise (C)');
legend('Location','northeast');
title('Air-side flow requirement');

nexttile;
hold on;
for i = 1:numel(caseNames)
    rows = sensitivity.Case==caseNames(i);
    plot(sensitivity.AirTemperatureRise_C(rows), ...
        sensitivity.RequiredIdealUA_WK(rows),'o-', ...
        'LineWidth',1.6,'DisplayName',caseNames(i));
end
xline(thermal.airOut_C-thermal.airIn_C,':','10 C baseline', ...
    'HandleVisibility','off');
grid on;
ylabel('Required ideal UA (W/K)');
xlabel('Assumed air temperature rise (C)');
legend('Location','northwest');
title('Ideal heat-transfer requirement');

title(layout,['Requirement sensitivity only; achieved core and fan ' ...
    'performance are not predicted']);
exportgraphics(fig,fullfile(outputDir,"radiator_design_requirements.png"), ...
    'Resolution',180);
close(fig);
end

function ensure_output_folder(folder)
if ~isfolder(folder)
    mkdir(folder);
end
end
