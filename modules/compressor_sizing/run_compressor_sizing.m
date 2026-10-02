function out = run_compressor_sizing(cfg,batteryCooling,gapFill)
%RUN_COMPRESSOR_SIZING Refrigeration capacity the cabin and battery chiller need.
% Every scenario is evaluated at the DM18A1 rating condition (about 0 C
% evaporating, 57 C condensing, R134a), which matches a 45 C day, so the
% supplier capacity scales with displacement at equal speed and efficiency:
%   V_required = V_DM18A1 * Q_required / Q_DM18A1(6000 rpm)
% Demand = cabin load + battery chiller duty. In steady state the chiller
% removes the battery's mean heat for the cycle. This is a capacity screen:
% there is no refrigerant-circuit, evaporator or condenser model.

c = cfg.cabinCooling.compressor;
outputDir = fullfile(cfg.project.outputDir,"compressor_sizing");
if ~isfolder(outputDir)
    mkdir(outputDir);
end

balance = gapFill.cabinHeatBalance;
humid = balance.Scenario==cfg.literatureGapFill.cabin.scenarioNames(end);
cabin_kW = sum(balance.Load_kW(humid));
cabinP95_kW = gapFill.robustness.P95(4);
pull = gapFill.cabinPullDown;
pullDown_kW = pull.MeanCapacity_CentralMass_kW( ...
    pull.PullDownTime_min==c.pullDownMinutes)-cabin_kW;

cycles = batteryCooling.cycleHeat.summary;
n = height(cycles);
scenario = [compose("Hot cabin + %s",cycles.Cycle); ...
    sprintf("%d-min pull-down + %s",c.pullDownMinutes, ...
        cycles.Cycle(cycles.FileStem==c.pullDownCycle))];
cabinPart = [repmat(cabin_kW,n,1);cabin_kW];
pullPart = [zeros(n,1);pullDown_kW];
batteryPart = [cycles.MeanBatteryHeat_kW; ...
    cycles.MeanBatteryHeat_kW(cycles.FileStem==c.pullDownCycle)];
batteryUpper = [cycles.MeanBatteryHeatUpperBound_kW; ...
    cycles.MeanBatteryHeatUpperBound_kW(cycles.FileStem==c.pullDownCycle)];
required_kW = cabinPart+pullPart+batteryPart;
[design_kW,designRow] = max(required_kW);
% Cabin at the 95th percentile with the design battery duty, and the
% highest-possible battery heat on the design scenario as a bound.
bandDesign_kW = cabinP95_kW+pullPart(designRow)+batteryPart(designRow);
boundDesign_kW = cabinPart(designRow)+pullPart(designRow)+batteryUpper(designRow);

ratedCapacity_kW = c.capacity_kW(end);
ratedSpeed_rpm = c.speed_rpm(end);
perCC_kW = ratedCapacity_kW/c.displacement_cc;
cop = ratedCapacity_kW/c.input_kW(end);
displacement = @(q,speed) q/perCC_kW*ratedSpeed_rpm/speed;

out.scenarios = table(scenario,cabinPart,pullPart,batteryPart,batteryUpper, ...
    required_kW,required_kW/ratedCapacity_kW,displacement(required_kW,ratedSpeed_rpm), ...
    'VariableNames',{'Scenario','CabinLoad_kW','PullDownExtra_kW', ...
    'BatteryChillerExpected_kW','BatteryChillerHighestPossible_kW', ...
    'RequiredCapacity_kW','RatioToDM18A1','RequiredDisplacementAt6000rpm_cc'});

basis = ["Design: largest expected demand";"Design with cabin load at its 95th percentile"; ...
    "Bound: highest-possible battery heat"];
capacity = [design_kW;bandDesign_kW;boundDesign_kW];
out.sizing = table(basis,repmat(scenario(designRow),3,1),capacity, ...
    displacement(capacity,ratedSpeed_rpm), ...
    displacement(capacity,c.alternativeSpeed_rpm), ...
    capacity/cop,capacity+capacity/cop,repmat(ratedCapacity_kW,3,1), ...
    'VariableNames',{'Basis','Scenario','RequiredCapacity_kW', ...
    'DisplacementAt6000rpm_cc','DisplacementAtAlternativeSpeed_cc', ...
    'ElectricalInputAtDM18A1COP_kW','CondenserHeatRejection_kW', ...
    'DM18A1Capacity_kW'});
out.designCapacity_kW = design_kW;
out.alternativeSpeed_rpm = c.alternativeSpeed_rpm;

writetable(out.scenarios,fullfile(outputDir,"compressor_demand_scenarios.csv"));
writetable(out.sizing,fullfile(outputDir,"compressor_sizing.csv"));
plot_sizing(out,c,outputDir);
end

function plot_sizing(out,c,outputDir)
s = out.scenarios;
fig = figure('Visible','off','Color','w','Position',[100 100 1400 560]);
layout = tiledlayout(1,2,'TileSpacing','compact');

nexttile;
labels = categorical(s.Scenario,flipud(s.Scenario));
data = [s.CabinLoad_kW s.PullDownExtra_kW s.BatteryChillerExpected_kW ...
    s.BatteryChillerHighestPossible_kW-s.BatteryChillerExpected_kW];
bars = barh(labels,data,'stacked','EdgeColor','w','LineWidth',1);
palette = [0.165 0.471 0.839;0.922 0.408 0.204;0.106 0.686 0.478;0.929 0.631 0];
for k = 1:4
    bars(k).FaceColor = palette(k,:);
end
bars(4).FaceAlpha = 0.35;
hold on;
xline(c.capacity_kW(end),'--','Color',[0.85 0.15 0.15],'LineWidth',1.6, ...
    'Label',sprintf('DM18A1: %.1f kW',c.capacity_kW(end)), ...
    'LabelOrientation','horizontal','LabelVerticalAlignment','bottom', ...
    'HandleVisibility','off');
xline(out.designCapacity_kW,'-','Color',[0.2 0.2 0.2],'LineWidth',1.6, ...
    'Label',sprintf('Required: %.2f kW',out.designCapacity_kW), ...
    'LabelOrientation','horizontal','LabelVerticalAlignment','top', ...
    'HandleVisibility','off');
text(s.BatteryChillerHighestPossible_kW+s.CabinLoad_kW+s.PullDownExtra_kW+0.15,labels, ...
    compose('%.2f kW',s.RequiredCapacity_kW),'FontSize',8);
grid on;
set(gca,'TickLabelInterpreter','none');
xlabel('Refrigeration capacity at about 0 C evaporating / 57 C condensing (kW)');
legend({'Cabin, humid heat','Pull-down extra (central mass)', ...
    'Battery chiller, expected','Battery chiller, up to highest possible'}, ...
    'Location','southeast','FontSize',8);
title('Demand per scenario against the DM18A1');

nexttile;
speed = linspace(2000,9000,71);
perRpm = c.capacity_kW(end)/c.speed_rpm(end);
plot(c.speed_rpm,c.capacity_kW,'o','Color',palette(1,:), ...
    'MarkerFaceColor',palette(1,:),'MarkerSize',8,'DisplayName','DM18A1 18 cc, supplier table');
hold on;
plot(speed,perRpm*speed,'-','Color',palette(1,:),'LineWidth',1.5, ...
    'DisplayName','18 cc, proportional to speed');
sizing = out.sizing;
styles = {'-','--'};
for k = 1:2
    cc = sizing.DisplacementAt6000rpm_cc(k);
    plot(speed,perRpm*speed*cc/c.displacement_cc,styles{k},'Color',palette(k+1,:), ...
        'LineWidth',2,'DisplayName',sprintf('%.0f cc (%s)',cc,lower(sizing.Basis(k))));
    ccAlt = sizing.DisplacementAtAlternativeSpeed_cc(k);
    plot(speed,perRpm*speed*ccAlt/c.displacement_cc,':','Color',palette(k+1,:), ...
        'LineWidth',2,'DisplayName',sprintf('%.0f cc reaches it at %d rpm',ccAlt, ...
        out.alternativeSpeed_rpm));
end
yline(sizing.RequiredCapacity_kW(1),'k-','HandleVisibility','off');
yline(sizing.RequiredCapacity_kW(2),'k--','HandleVisibility','off');
xline(c.speed_rpm(end),':','DM18A1 maximum 6000 rpm','HandleVisibility','off');
grid on;
xlabel('Compressor speed (rpm)');
ylabel('Refrigeration capacity (kW)');
legend('Location','northwest','FontSize',8);
title('Displacement that meets the demand');
title(layout,'Compressor sizing: cabin plus battery chiller at a 45 C design day (R134a)');
exportgraphics(fig,fullfile(outputDir,"compressor_sizing.png"),'Resolution',180);
close(fig);
end
