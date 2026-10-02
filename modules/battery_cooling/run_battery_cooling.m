function out = run_battery_cooling(cfg)
%RUN_BATTERY_COOLING Sustained battery thermal screen.
% Uses the DC resistance, entropic heat and cell-to-coolant path set by
% apply_literature_corrections. No coolant temperature is imposed here; the
% discharge transient is in modules/literature_gap_fill.

p = cfg.batteryCooling;
outputDir = fullfile(cfg.project.outputDir,"battery_cooling");
ensure_output_folder(outputDir);

out.screen = calculate_battery_requirements_screen(p.cRates,p);

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
% Heat and coolant envelope from the corrected parameters, with the register
% range as a band and the superseded ACR/3.10 K/W result for comparison.
fig = figure('Visible','off','Color','w','Position',[100 100 1250 520]);
layout = tiledlayout(1,2,'TileSpacing','compact');

nexttile;
area(screen.C_rate,[screen.JouleHeat_W screen.EntropicHeat_W]* ...
    battery.seriesCells/1000,'LineStyle','none');
hold on;
plot(screen.C_rate,screen.SupersededACRCellHeat_W*battery.seriesCells/1000, ...
    'k--','LineWidth',1.4);
grid on;
xlabel('Sustained C-rate');
ylabel('Pack heat (kW)');
legend({sprintf('Joule, DC resistance %.2f mOhm at 25 C', ...
    1000*battery.dcResistance25_Ohm), ...
    'Entropic, low-SOC peak','Superseded: 1 kHz ACR only'}, ...
    'Location','northwest');
title('Pack heat generation');

nexttile;
fill([screen.C_rate;flipud(screen.C_rate)], ...
    [screen.MaximumCoolantForDischargeP05_C; ...
     flipud(screen.MaximumCoolantForDischargeP95_C)], ...
    [0.75 0.85 1.0],'EdgeColor','none', ...
    'DisplayName','5-95% over register ranges, 60 C limit');
hold on;
plot(screen.C_rate,screen.MaximumCoolantForDischarge_C,'b-','LineWidth',2, ...
    'DisplayName',sprintf('60 C limit, %.2f K/W path',battery.cellToCoolantResistance_KW));
plot(screen.C_rate,screen.MaximumCoolantForRegen_C,'b:','LineWidth',1.6, ...
    'DisplayName','55 C charge cutoff');
plot(screen.C_rate,screen.SupersededMaximumCoolantForDischarge_C,'r--', ...
    'LineWidth',1.4,'DisplayName',sprintf('Superseded: ACR with %.2f K/W', ...
    battery.superseded.baseResistance_KW));
yline(45,'k:','45 C ambient','HandleVisibility','off');
grid on;
ylim([-40 65]);
xlabel('Sustained C-rate');
ylabel('Maximum allowable coolant temperature (C)');
title('Coolant temperature the cell can tolerate');
legend('Location','southwest');

title(layout,'Battery sustained screen: corrected heat and cell-to-coolant path');
exportgraphics(fig,fullfile(outputDir,"battery_c_rate_sweep.png"), ...
    'Resolution',180);
close(fig);
end

function ensure_output_folder(folder)
if ~isfolder(folder)
    mkdir(folder);
end
end
