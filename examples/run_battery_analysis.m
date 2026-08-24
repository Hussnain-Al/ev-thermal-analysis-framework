function out = run_battery_analysis(cfg)
%RUN_BATTERY_ANALYSIS Battery minimum-resistive heat and thermal-path screening.

p = cfg.battery;
out.heat = calculate_battery_ohmic_heat(p.cRates, p.capacity_Ah, p.resistanceProxy_Ohm, p.seriesCells);
network = calculate_battery_thermal_network(out.heat.CellHeat_W, p.baseResistance_KW, p.sideResistance_KW_each);
out.heat = [out.heat network(:,2:end)];
out.heat.BasePathSteadyCell_C = ...
    p.coolantTemperature_C+out.heat.BasePathRequiredRise_C;
out.heat.SustainedBasePathWithinLimit = ...
    out.heat.BasePathSteadyCell_C<=p.maximumCell_C;

vehicleCases = read_project_csv(cfg.files.vehicleLoadCases, ...
    {'LoadCase','Description','WheelPower_W','MotorPower_W','Current_A','Status'}, ...
    {'WheelPower_W','MotorPower_W','Current_A'});
vehicleCases.C_rate = vehicleCases.Current_A / p.capacity_Ah;
vehicleCases.MinimumResistivePackHeat_kW = (vehicleCases.Current_A.^2*p.resistanceProxy_Ohm*p.seriesCells)/1000;
out.vehicleCases = vehicleCases;

writetable(out.heat, fullfile(cfg.project.outputDir,'battery_heat_results.csv'));
writetable(out.vehicleCases, fullfile(cfg.project.outputDir,'battery_load_cases.csv'));

fig = figure('Visible','off','Color','w');
tiledlayout(1,2);
nexttile; plot(out.heat.C_rate,out.heat.CellHeat_W,'o-','LineWidth',1.5); grid on;
xlabel('Discharge rate (C)'); ylabel('Cell minimum resistive heat (W)');
title('Optional constant-current sensitivity');
nexttile; plot(out.heat.C_rate,out.heat.PackHeat_kW,'o-','LineWidth',1.5); grid on;
xlabel('Discharge rate (C)'); ylabel('Pack minimum resistive heat (kW)');
title('Not used for drive-cycle component sizing');
exportgraphics(fig, fullfile(cfg.project.outputDir,'battery_heat_generation.png'),'Resolution',180);
close(fig);
end
