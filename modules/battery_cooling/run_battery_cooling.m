function out = run_battery_cooling(cfg)
%RUN_BATTERY_COOLING Sustained ACR-based battery thermal screen.
% No drive-cycle temperature state, fixed coolant temperature, cooling
% request or compressor capacity is calculated here.

p = cfg.batteryCooling;
outputDir = fullfile(cfg.project.outputDir,"battery_cooling");
ensure_output_folder(outputDir);

out.screen = calculate_battery_ohmic_heat( ...
    p.cRates,p.capacity_Ah,p.resistanceProxy_Ohm,p.seriesCells);
out.screen.RequiredCellToCoolantRise_C = ...
    out.screen.CellHeat_W*p.baseResistance_KW;
out.screen.MaximumCoolantForRegen_C = ...
    p.regenChargeCutoff_C-out.screen.RequiredCellToCoolantRise_C;
out.screen.MaximumCoolantForDischarge_C = ...
    p.absoluteOperatingLimit_C-out.screen.RequiredCellToCoolantRise_C;
out.screen.ACRProxyOnly = true(height(out.screen),1);

out.specification = table( ...
    ["Regen charge cutoff";"Absolute operating limit"; ...
     "Maximum continuous discharge";"Continuous thermal reference"; ...
     "Pulse thermal reference"], ...
    [p.regenChargeCutoff_C;p.absoluteOperatingLimit_C; ...
     p.maximumContinuousDischarge_C;p.referenceContinuousRiseLimit_C; ...
     p.referencePulseRiseLimit_C], ...
    ["degC";"degC";"C-rate";"degC rise";"degC rise"], ...
    ["SVOLT continuous-charge table";"SVOLT absolute protection"; ...
     "SVOLT at 25 +/- 3 degC";"SVOLT 1C for 600 s"; ...
     "SVOLT 3C for 30 s"], ...
    'VariableNames',{'Requirement','Value','Unit','EvidenceCondition'});

writetable(out.screen,fullfile(outputDir,"battery_sustained_screen.csv"));
writetable(out.specification,fullfile(outputDir,"battery_specification_limits.csv"));
plot_battery_c_rate_sweep(out.screen,p,outputDir);
end

function plot_battery_c_rate_sweep(screen,battery,outputDir)
% Plot the useful sustained screen. This does not claim that ACR is DCIR;
% the resistance remains a lower-bound proxy pending measured DC data.
fig = figure('Visible','off','Color','w','Position',[100 100 1250 520]);
layout = tiledlayout(1,2,'TileSpacing','compact');

nexttile;
plot(screen.C_rate,screen.PackHeat_kW,'o-','LineWidth',1.5);
grid on;
xlabel('Sustained C-rate');
ylabel('Minimum ohmic pack heat (kW)');
title('Heat floor from ACR proxy');

nexttile;
plot(screen.C_rate,screen.MaximumCoolantForRegen_C, ...
    'o-','LineWidth',1.5,'DisplayName','55 C regen cutoff');
hold on;
plot(screen.C_rate,screen.MaximumCoolantForDischarge_C, ...
    's-','LineWidth',1.5,'DisplayName','60 C absolute limit');
yline(0,'k:','LineWidth',1.0,'HandleVisibility','off');
grid on;
xlabel('Sustained C-rate');
ylabel('Maximum allowable coolant temperature (C)');
title('Coolant requirement from 3.10 K/W base path');
legend('Location','southwest');

title(layout,'Battery sustained-load lower-bound screen');
exportgraphics(fig,fullfile(outputDir,"battery_c_rate_sweep.png"), ...
    'Resolution',180);
close(fig);
end

function ensure_output_folder(folder)
if ~isfolder(folder)
    mkdir(folder);
end
end
