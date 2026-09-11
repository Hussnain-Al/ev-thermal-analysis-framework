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

out.summary = table(p.designLocation,p.designAmbient_C,p.initialHotSoak_C, ...
    p.ambientRelativeHumidity_pct,p.cabinSetpoint_C, ...
    p.cabinRelativeHumidity_pct, ...
    calculated.RecoveredPartialSensibleLoad_kW,p.modelBoundary, ...
    string(p.files.sourceWorkbook),workbookBodyAndGlazing_kW, ...
    'VariableNames',{'DesignLocation','DesignAmbient_C','InitialHotSoak_C', ...
    'AmbientRelativeHumidity_pct','CabinSetpoint_C', ...
    'CabinRelativeHumidity_pct','RecoveredPartialSensibleLoad_kW', ...
    'ModelBoundary','SourceWorkbook','WorkbookBodyAndGlazingLoad_kW'});

writetable(out.inputs,fullfile(outputDir,"cabin_load_inputs_used.csv"));
writetable(out.summary,fullfile(outputDir,"cabin_cooling_summary.csv"));
plot_cabin_load_breakdown(out.inputs,out.summary,outputDir);
end

function plot_cabin_load_breakdown(inputs,summary,outputDir)
fig = figure('Visible','off','Color','w','Position',[100 100 1050 650]);
bar(inputs.Load_kW);
grid on;
xticks(1:height(inputs));
xticklabels(inputs.LoadComponent);
xtickangle(20);
ylabel('Recovered load (kW)');
title(sprintf('Recovered partial sensible cabin load: %.3f kW', ...
    summary.RecoveredPartialSensibleLoad_kW));
for i = 1:height(inputs)
    text(i,inputs.Load_kW(i),sprintf(' %.3f',inputs.Load_kW(i)), ...
        'HorizontalAlignment','center','VerticalAlignment','bottom');
end
exportgraphics(fig,fullfile(outputDir,"cabin_load_breakdown.png"), ...
    'Resolution',180);
close(fig);
end

function ensure_output_folder(folder)
if ~isfolder(folder)
    mkdir(folder);
end
end
