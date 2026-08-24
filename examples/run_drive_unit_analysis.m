function out = run_drive_unit_analysis(cfg,driveSummary)
%RUN_DRIVE_UNIT_ANALYSIS Duty-cycle drive-unit coolant and radiator screening.

p = cfg.propulsionCooling;
c = cfg.coolant;
nominal = c(c.Temperature_C==p.propertyTemperature_C,:);
if height(nominal)~=1
    error('EVThermal:MissingCoolantProperty', ...
        'One coolant-property row is required at %.1f C.',p.propertyTemperature_C);
end
out.heat = make_cycle_heat_table(driveSummary);

out.coolant = calculate_coolant_transport(out.heat.ThermalDuty_kW, ...
    p.designFlow_Lmin,p.hoseID_m,nominal.Density_kgm3,nominal.Cp_JkgK);
out.coolant.Cycle = out.heat.Cycle;
out.coolant.LoadMetric = out.heat.LoadMetric;

% In a closed loop at steady state, the radiator coolant drop equals the
% calculated drive-unit coolant rise. This prevents an independent radiator
% outlet temperature from contradicting the coolant energy balance.
radiatorCoolantOut_C = p.radiatorCoolantIn_C-out.coolant.CoolantRise_C;
out.radiator = calculate_radiator_requirement(out.heat.ThermalDuty_kW, ...
    p.radiatorCoolantIn_C,radiatorCoolantOut_C,p.airIn_C,p.airOut_C,p.airCp_JkgK);
out.radiator.Cycle = out.heat.Cycle;
out.radiator.LoadMetric = out.heat.LoadMetric;

out.thermalReference = read_project_csv(cfg.files.driveThermalReference, ...
    {'ReferenceCase','CoolantInlet_C','CoolantFlow_Lmin', ...
     'ReportedWindingTemperature_C','Duration_s','EvidenceStatus'}, ...
    {'CoolantInlet_C','CoolantFlow_Lmin', ...
     'ReportedWindingTemperature_C','Duration_s'});

writetable(out.heat,fullfile(cfg.project.outputDir,'drive_unit_heat_results.csv'));
writetable(out.coolant,fullfile(cfg.project.outputDir,'drive_unit_coolant_results.csv'));
writetable(out.radiator,fullfile(cfg.project.outputDir,'radiator_requirement.csv'));
writetable(out.thermalReference,fullfile(cfg.project.outputDir,'drive_unit_thermal_reference.csv'));

fig=figure('Visible','off','Color','w');
heatMatrix = reshape(out.heat.ThermalDuty_kW,2,[])';
bar(categorical(unique(out.heat.Cycle,'stable')),heatMatrix);
ylabel('Integrated drive heat (kW)'); grid on;
legend('Cycle average','Cycle peak','Location','northwest');
exportgraphics(fig,fullfile(cfg.project.outputDir,'drive_unit_heat_breakdown.png'),'Resolution',180); close(fig);
end

function heat = make_cycle_heat_table(summary)
n = height(summary);
heat = table(repelem(summary.Cycle,2),repmat(["Average";"Peak"],n,1), ...
    reshape([summary.AverageDriveUnitHeat_kW summary.PeakDriveUnitHeat_kW]',[],1), ...
    repmat("Configured integrated drive-unit efficiency map",2*n,1), ...
    'VariableNames',{'Cycle','LoadMetric','ThermalDuty_kW','Boundary'});
end
