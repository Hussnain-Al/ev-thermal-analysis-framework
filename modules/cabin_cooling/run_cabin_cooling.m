function out = run_cabin_cooling(cfg)
%RUN_CABIN_COOLING Independent Karachi cabin-load screening module.

p = cfg.cabinCooling;
outputDir = fullfile(cfg.project.outputDir,"cabin_cooling");
ensure_output_folder(outputDir);

out.inputs = read_project_csv(p.files.loadInputs, ...
    {'LoadComponent','Load_kW','CabinSetpoint_C', ...
     'InteriorRelativeHumidity_pct','SourceWorkbook','SourceStatus'}, ...
    {'Load_kW','CabinSetpoint_C','InteriorRelativeHumidity_pct'});
surfaceLoads_W = readmatrix(p.files.sourceWorkbook,'Sheet','Sheet1', ...
    'Range','I2:I18');
workbookBodyAndGlazing_kW = sum(surfaceLoads_W,'omitnan')/1000;

% The derived CSV intentionally reports loads to 0.001 kW. Compare the
% workbook subtotal at that published precision instead of demanding
% bit-for-bit equality with unrounded workbook cells.
publishedLoadTolerance_kW = 0.5e-3;
if abs(workbookBodyAndGlazing_kW-out.inputs.Load_kW(1))>publishedLoadTolerance_kW
    error('EVThermal:CabinWorkbookMismatch', ...
        'Recovered workbook surface-load total does not match the derived input table to 0.001 kW.');
end
calculated = calculate_cabin_partial_load(out.inputs);
if abs(calculated.RecoveredPartialSensibleLoad_kW- ...
        p.recoveredCabinDuty_kW)>1e-9
    error('EVThermal:CabinLoadMismatch', ...
        'Configured cabin duty does not equal the recovered load-input sum.');
end

% Corrected results. The workbook stays unchanged (it is hashed source
% evidence); audit_cabin_workbook recomputes its rows consistently, and the
% heat-balance rebuild adds the solar, latent and fresh-air terms.
g = cfg.literatureGapFill.cabin;
a = cfg.literature.values;
out.workbookAudit = audit_cabin_workbook(p.files.sourceWorkbook, ...
    g.workbookOutdoor_C,g.workbookIndoor_C);
correctedSubtotal_kW = sum(out.workbookAudit.Recomputed_W)/1000+ ...
    sum(out.inputs.Load_kW(2:end));
scenarioRH = [a.K03;a.K02];
balances = cell(numel(scenarioRH),1);
for i = 1:numel(scenarioRH)
    components = calculate_cabin_heat_balance(p.designAmbient_C,scenarioRH(i), ...
        p.cabinSetpoint_C,p.cabinRelativeHumidity_pct,g,a);
    components.Scenario = repmat(g.scenarioNames(i),height(components),1);
    components.OutdoorRH_pct = repmat(scenarioRH(i),height(components),1);
    balances{i} = components(:,{'Scenario','OutdoorRH_pct','Component','Load_kW'});
end
out.heatBalance = vertcat(balances{:});
heatBalanceTotals_kW = zeros(numel(scenarioRH),1);
for i = 1:numel(scenarioRH)
    heatBalanceTotals_kW(i) = sum(out.heatBalance.Load_kW( ...
        out.heatBalance.Scenario==g.scenarioNames(i)));
end

out.summary = table(p.designLocation,p.designAmbient_C,p.initialHotSoak_C, ...
    p.ambientRelativeHumidity_pct,p.cabinSetpoint_C, ...
    p.cabinRelativeHumidity_pct, ...
    calculated.RecoveredPartialSensibleLoad_kW,p.modelBoundary, ...
    string(p.files.sourceWorkbook),workbookBodyAndGlazing_kW, ...
    correctedSubtotal_kW,heatBalanceTotals_kW(1),heatBalanceTotals_kW(2), ...
    'VariableNames',{'DesignLocation','DesignAmbient_C','InitialHotSoak_C', ...
    'AmbientRelativeHumidity_pct','CabinSetpoint_C', ...
    'CabinRelativeHumidity_pct','RecoveredPartialSensibleLoad_kW', ...
    'ModelBoundary','SourceWorkbook','WorkbookBodyAndGlazingLoad_kW', ...
    'CorrectedWorkbookSubtotal_kW','HeatBalanceDryHeat_kW', ...
    'HeatBalanceHumidHeat_kW'});

writetable(out.inputs,fullfile(outputDir,"cabin_load_inputs_used.csv"));
writetable(out.summary,fullfile(outputDir,"cabin_cooling_summary.csv"));
writetable(out.workbookAudit,fullfile(outputDir,"cabin_workbook_audit.csv"));
writetable(out.heatBalance,fullfile(outputDir,"cabin_heat_balance.csv"));
plot_cabin_load_breakdown(out,g,outputDir);
end

function plot_cabin_load_breakdown(out,g,outputDir)
% Stacked heat-balance components for both humidity scenarios beside the
% workbook subtotal as recorded and as recomputed.
components = unique(out.heatBalance.Component,'stable');
nComponents = numel(components);
groups = ["Workbook as recorded";"Workbook recomputed";g.scenarioNames];
data = zeros(numel(groups),nComponents+2);
data(1,end-1) = out.summary.RecoveredPartialSensibleLoad_kW;
data(2,end) = out.summary.CorrectedWorkbookSubtotal_kW;
for i = 1:numel(g.scenarioNames)
    data(2+i,1:nComponents) = out.heatBalance.Load_kW( ...
        out.heatBalance.Scenario==g.scenarioNames(i))';
end
fig = figure('Visible','off','Color','w','Position',[100 100 1150 650]);
bars = bar(categorical(groups,groups),data,'stacked');
palette = [0.12 0.35 0.75;0.55 0.70 0.95;0.90 0.55 0.10;0.55 0.35 0.10; ...
    0.10 0.55 0.35;0.55 0.85 0.65;0.50 0.20 0.70;0.80 0.65 0.95;0.40 0.40 0.45];
for k = 1:nComponents
    bars(k).FaceColor = palette(k,:);
end
bars(end-1).FaceColor = [0.55 0.55 0.55];
bars(end).FaceColor = [0.35 0.35 0.35];
totals = sum(data,2);
text(1:numel(groups),totals,compose(' %.2f kW',totals), ...
    'HorizontalAlignment','center','VerticalAlignment','bottom');
grid on;
ylim([0 1.6*max(totals)]);
ylabel('Cabin cooling load (kW)');
legend([components;"Workbook subtotal as recorded";"Workbook subtotal recomputed"], ...
    'Location','northwest','FontSize',8);
title(sprintf(['Cabin load at 45 C, 25 C / 50%% RH cabin: workbook ' ...
    'audit and heat-balance rebuild (15:00 solar)']));
exportgraphics(fig,fullfile(outputDir,"cabin_load_breakdown.png"), ...
    'Resolution',180);
close(fig);
end

function ensure_output_folder(folder)
if ~isfolder(folder)
    mkdir(folder);
end
end
