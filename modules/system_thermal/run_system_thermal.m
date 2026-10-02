function out = run_system_thermal(cfg,results)
%RUN_SYSTEM_THERMAL All three loops driven by each drive cycle, second by second.
% The drive cycle is repeated to the window length. From its DC-link power
% the pack current, state of charge and battery heat are computed with SOC
% carried continuously across repeats (calculate_battery_cycle_heat); its
% drive-unit heat drives the propulsion two-node loop and radiator
% (simulate_motor_coolant_thermal); the battery heat and the heat-balance
% cabin load draw on one compressor (simulate_system_thermal), at the DM18A1
% capacity and at the size from compressor_sizing. A front-end check shows
% what the condenser does to the radiator if both share one air stream.

s = cfg.systemThermal;
a = cfg.literature.values;
battery = cfg.batteryCooling;
outputDir = fullfile(cfg.project.outputDir,"system_thermal");
if ~isfolder(outputDir)
    mkdir(outputDir);
end

% Cabin heat-balance load as a function of cabin temperature (humid heat).
cabinGrid_C = (15:1:95)';
cabinLoad_kW = zeros(size(cabinGrid_C));
for i = 1:numel(cabinGrid_C)
    components = calculate_cabin_heat_balance(a.K01,a.K02,cabinGrid_C(i), ...
        cfg.cabinCooling.cabinRelativeHumidity_pct,cfg.literatureGapFill.cabin,a);
    cabinLoad_kW(i) = sum(components.Load_kW);
end
out.cabinLoadCurve = table(cabinGrid_C,cabinLoad_kW, ...
    'VariableNames',{'Cabin_C','CabinLoad_kW'});

p.cabinInitial_C = a.C26;
p.packInitial_C = s.packInitial_C;
p.batteryCoolantInitial_C = s.batteryCoolantInitial_C;
p.cabinSetpoint_C = s.cabinSetpoint_C;
p.batteryCoolantSetpoint_C = s.batteryCoolantSetpoint_C;
p.controllerGain_WK = s.controllerGain_WK;
p.cabinCapacitance_JK = 1000*a.C24;
p.packCapacitance_JK = battery.seriesCells*a.B20*a.B21;
p.packResistance_KW = battery.cellToCoolantResistance_KW/battery.seriesCells;
p.batteryCoolantCapacitance_JK = 1000*a.S01;
out.parameters = p;

compressorName = ["DM18A1";"Recommended"];
capacity_kW = [cfg.cabinCooling.compressorRatedCapacity_kW; ...
    results.compressorSizing.sizing.RequiredCapacity_kW(2)];
out.compressorName = compressorName;
out.capacity_kW = capacity_kW;

stems = results.motorHeat.fileStems;
time_s = (0:s.duration_s)';
nCycles = numel(s.cycles);
out.traces = cell(nCycles,numel(capacity_kW));
out.inputs = cell(nCycles,1);
rows = cell(nCycles*numel(capacity_kW),1);
r = 0;
for i = 1:nCycles
    index = find(stems==s.cycles(i),1);
    if isempty(index)
        error('EVThermal:UnknownCycle','System cycle %s was not run.',s.cycles(i));
    end
    % Repeat the cycle's one-second power and heat to the window length.
    detail = results.motorHeat.details{index};
    samples = height(detail)-1;
    pick = mod(time_s,samples)+1;
    drive = table(repmat(detail.Cycle(1),numel(time_s),1),time_s, ...
        detail.DCLinkPower_kW(pick),detail.DriveUnitHeat_kW(pick), ...
        'VariableNames',{'Cycle','Time_s','DCLinkPower_kW','DriveUnitHeat_kW'});
    batteryTrace = calculate_battery_cycle_heat(drive,battery);
    motorParameters = cfg.motorCooling.transient;
    if results.motorHeat.fanOnly(index)
        motorParameters.radiatorUA_WK = motorParameters.fanOnlyRadiatorUA_WK;
    end
    ambient_C = results.motorHeat.ambient_C(index);
    propulsion = simulate_motor_coolant_thermal(drive,ambient_C,motorParameters);
    out.inputs{i} = struct('drive',drive,'ambient_C',ambient_C, ...
        'radiatorUA_WK',motorParameters.radiatorUA_WK);
    for j = 1:numel(capacity_kW)
        trace = simulate_system_thermal(time_s,batteryTrace.BatteryHeat_kW, ...
            cabinGrid_C,cabinLoad_kW,capacity_kW(j),p);
        trace.DCLinkPower_kW = drive.DCLinkPower_kW;
        trace.SOC_pct = batteryTrace.SOC_pct;
        trace.DriveUnitHeat_kW = drive.DriveUnitHeat_kW;
        trace.DriveUnit_C = propulsion.MotorTemperature_C;
        trace.PropulsionCoolant_C = propulsion.CoolantTemperature_C;
        out.traces{i,j} = trace;
        r = r+1;
        rows{r} = summarize(trace,detail.Cycle(1),s.cycles(i), ...
            compressorName(j),capacity_kW(j),s);
    end
end
out.summary = vertcat(rows{:});

% Front end: condenser heat at full capacity against the radiator's L6 air
% stream. If the condenser sits upstream on that stream, the radiator sees
% hotter air.
thermal = cfg.motorCooling.thermal;
airDensity = thermal.ambientPressure_Pa/(thermal.airGasConstant_JkgK*(thermal.airIn_C+273.15));
radiatorAir_m3s = max(results.motorCooling.radiatorDesign.RequiredAirVolumeFlow_m3s);
cop = cfg.cabinCooling.compressorRatedCapacity_kW/cfg.cabinCooling.compressorRatedInput_kW;
condenser_kW = capacity_kW*(1+1/cop);
condenserAir_m3s = 1000*condenser_kW/(airDensity*thermal.airCp_JkgK*s.condenserAirRise_C);
radiatorInlet_C = thermal.airIn_C+1000*condenser_kW/ ...
    (airDensity*radiatorAir_m3s*thermal.airCp_JkgK);
out.frontEnd = table(compressorName,capacity_kW,condenser_kW,condenserAir_m3s, ...
    repmat(radiatorAir_m3s,2,1),radiatorInlet_C, ...
    radiatorInlet_C<thermal.radiatorCoolantIn_C, ...
    'VariableNames',{'Compressor','Capacity_kW','CondenserHeat_kW', ...
    'CondenserAirAt15KRise_m3s','RadiatorAirL6_m3s', ...
    'RadiatorInletIfCondenserUpstream_C','RadiatorStillRejects'});

writetable(out.summary,fullfile(outputDir,"system_thermal_summary.csv"));
writetable(out.frontEnd,fullfile(outputDir,"front_end_air_check.csv"));
writetable(out.cabinLoadCurve,fullfile(outputDir,"cabin_load_curve.csv"));
plot_system(out,s,battery,outputDir);
end

function row = summarize(trace,cycleName,stem,compressor,capacity_kW,s)
t = trace.Time_s;
comfort = find(trace.Cabin_C<=s.cabinSetpoint_C+s.comfortBand_C,1);
timeToComfort_s = NaN;
if ~isempty(comfort)
    timeToComfort_s = t(comfort);
end
dt = [diff(t);0];
row = table(cycleName,stem,compressor,capacity_kW,timeToComfort_s, ...
    trace.Cabin_C(end),max(trace.Cell_C),trace.Cell_C(end), ...
    sum(dt(trace.Cell_C>55)),trace.BatteryCoolant_C(end), ...
    100*mean(trace.CompressorUse),trace.SOC_pct(end), ...
    max(trace.DriveUnit_C),max(trace.PropulsionCoolant_C), ...
    'VariableNames',{'Cycle','FileStem','Compressor','Capacity_kW', ...
    'TimeToCabinComfort_s','CabinAtEnd_C','PeakCell_C','CellAtEnd_C', ...
    'TimeCellAbove55C_s','BatteryCoolantAtEnd_C','MeanCompressorUse_pct', ...
    'SOCAtEnd_pct','PeakDriveUnit_C','PeakPropulsionCoolant_C'});
end

function plot_system(out,s,battery,outputDir)
blue = [0.165 0.471 0.839]; orange = [0.922 0.408 0.204];
colors = [orange;blue];
fig = figure('Visible','off','Color','w','Position',[100 100 1400 1300]);
layout = tiledlayout(3,2,'TileSpacing','compact');
shown = ["project_l6_continuous_grade";"urban_cycle"];
for k = 1:2
    i = find(s.cycles==shown(k));
    nexttile;
    hold on;
    for j = 1:numel(out.capacity_kW)
        tr = out.traces{i,j};
        label = sprintf('%s %.1f kW',out.compressorName(j),out.capacity_kW(j));
        plot(tr.Time_s/60,tr.Cabin_C,'-','Color',colors(j,:),'LineWidth',2, ...
            'DisplayName',"Cabin, "+label);
        plot(tr.Time_s/60,tr.Cell_C,'--','Color',colors(j,:),'LineWidth',2, ...
            'DisplayName',"Cell, "+label);
    end
    yline(s.cabinSetpoint_C,':','Cabin set point','HandleVisibility','off');
    yline(battery.regenChargeCutoff_C,':','Charge cut-off 55 C','HandleVisibility','off');
    yline(battery.absoluteOperatingLimit_C,'-','Cell limit 60 C', ...
        'Color',[0.6 0.6 0.6],'HandleVisibility','off');
    grid on; ylim([15 85]);
    xlabel('Time from hot-soak start (min)'); ylabel('Temperature (C)');
    title(sprintf('%s, repeated to %d min',out.summary.Cycle( ...
        out.summary.FileStem==shown(k) & out.summary.Compressor=="DM18A1"), ...
        s.duration_s/60),'Interpreter','none');
    legend('Location','northeast','FontSize',8);
end

nexttile;
i = find(s.cycles==shown(1));
tr = out.traces{i,2};
duty = area(tr.Time_s/60,[tr.EvaporatorDuty_kW tr.ChillerDuty_kW],'EdgeColor','none');
duty(1).FaceColor = blue;
duty(2).FaceColor = [0.106 0.686 0.478];
hold on;
yline(out.capacity_kW(2),'k--',sprintf('Recommended capacity %.1f kW',out.capacity_kW(2)), ...
    'HandleVisibility','off');
yline(out.capacity_kW(1),'--','Color',orange,'HandleVisibility','off');
text(1,out.capacity_kW(1)+0.3,sprintf('DM18A1 %.1f kW',out.capacity_kW(1)),'Color',orange);
grid on; xlabel('Time (min)'); ylabel('Refrigeration duty (kW)');
legend({'Cabin evaporator','Battery chiller'},'Location','east');
title('L6: how the recommended compressor splits its capacity');

nexttile;
summary = out.summary;
peak = reshape(summary.PeakCell_C,numel(out.capacity_kW),[])';
names = summary.Cycle(summary.Compressor=="DM18A1");
bars = bar(categorical(names,names),peak,'EdgeColor','w');
bars(1).FaceColor = orange; bars(2).FaceColor = blue;
hold on;
yline(battery.regenChargeCutoff_C,':','55 C','HandleVisibility','off');
yline(battery.absoluteOperatingLimit_C,'-','60 C','Color',[0.6 0.6 0.6],'HandleVisibility','off');
grid on; ylim([40 65]);
set(gca,'TickLabelInterpreter','none');
ylabel('Peak cell temperature in 30 min (C)');
legend(compose('%s %.1f kW',out.compressorName,out.capacity_kW),'Location','northwest');
title('Peak cell temperature per cycle');
cycleColors = [0.165 0.471 0.839;0.922 0.408 0.204;0.106 0.686 0.478; ...
    0.929 0.631 0;0.910 0.482 0.643];
nexttile;
hold on;
for i = 1:numel(s.cycles)
    tr = out.traces{i,end};
    plot(tr.Time_s/60,tr.DriveUnit_C,'-','Color',cycleColors(i,:),'LineWidth',1.6, ...
        'DisplayName',out.summary.Cycle(2*i));
    plot(tr.Time_s/60,tr.PropulsionCoolant_C,':','Color',cycleColors(i,:), ...
        'LineWidth',1.4,'HandleVisibility','off');
end
yline(150,':','150 C hot-spot target','HandleVisibility','off');
grid on; xlabel('Time (min)'); ylabel('Temperature (C)');
title('Propulsion loop: drive unit (solid) and its coolant (dotted)');
legend('Location','northwest','FontSize',7,'Interpreter','none');
nexttile;
hold on;
for i = 1:numel(s.cycles)
    tr = out.traces{i,end};
    plot(tr.Time_s/60,tr.SOC_pct,'-','Color',cycleColors(i,:),'LineWidth',1.6, ...
        'DisplayName',out.summary.Cycle(2*i));
end
grid on; xlabel('Time (min)'); ylabel('State of charge (%)'); ylim([0 100]);
title('Battery state of charge, integrated from the cycle current');
legend('Location','southwest','FontSize',7,'Interpreter','none');
title(layout,'System model: every loop driven by the drive cycle from a hot soak on a 45 C day');
exportgraphics(fig,fullfile(outputDir,"system_thermal_response.png"),'Resolution',160);
close(fig);
end
