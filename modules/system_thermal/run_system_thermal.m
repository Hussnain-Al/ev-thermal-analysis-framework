function out = run_system_thermal(cfg,results)
%RUN_SYSTEM_THERMAL Closed-loop thermal management on each drive cycle.
% The drive cycle is repeated to the window length. Its DC-link power drives
% the pack (current, state of charge, Joule and entropic heat), its motor
% and controller losses drive the propulsion loop, and the heat-balance
% cabin load and the battery chiller share one compressor. The thermal
% management controllers (PI loops, compressor priority, BMS and motor
% derating) act on the simulated temperatures; see simulate_system_thermal.
% Each cycle runs at the DM18A1 capacity and at the size from
% compressor_sizing. A front-end check shows what the condenser does to the
% radiator if both share one air stream.

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
p.cabinCapacitance_JK = 1000*a.C24;
p.packCapacitance_JK = battery.seriesCells*a.B20*a.B21;
p.packResistance_KW = battery.cellToCoolantResistance_KW/battery.seriesCells;
p.batteryCoolantCapacitance_JK = 1000*a.S01;
p.battery = battery;
p.motor = cfg.motorCooling.transient;

% Lambda (IMC) tuning. Each loop is a first-order plant from duty to
% temperature, C dT/dt = -Q + G (T_drive - T). A PI controller
% Kp = C/lambda, Ki = G/lambda cancels the plant pole and gives a
% first-order closed loop with time constant lambda.
%   cabin: C = interior thermal mass, G = slope of the cabin load with
%          cabin temperature at the set point;
%   battery coolant: C = battery-loop capacitance, G = 1/R_pack.
slope_WK = -1000*(interp1(cabinGrid_C,cabinLoad_kW,p.cabinSetpoint_C+1)- ...
    interp1(cabinGrid_C,cabinLoad_kW,p.cabinSetpoint_C-1))/2;
c = s.control;
c.cabinPlantG_WK = slope_WK;
c.batteryPlantG_WK = 1/p.packResistance_KW;
c.cabinKp_WK = p.cabinCapacitance_JK/c.cabinLambda_s;
c.cabinKi_WKs = c.cabinPlantG_WK/c.cabinLambda_s;
c.batteryKp_WK = p.batteryCoolantCapacitance_JK/c.batteryLambda_s;
c.batteryKi_WKs = c.batteryPlantG_WK/c.batteryLambda_s;
p.control = c;
out.parameters = p;
out.controllerGains = table(["Cabin";"Battery coolant"], ...
    [p.cabinCapacitance_JK;p.batteryCoolantCapacitance_JK]/1000, ...
    [c.cabinPlantG_WK;c.batteryPlantG_WK],[c.cabinLambda_s;c.batteryLambda_s], ...
    [c.cabinKp_WK;c.batteryKp_WK],[c.cabinKi_WKs;c.batteryKi_WKs], ...
    'VariableNames',{'Loop','PlantCapacitance_kJK','PlantConductance_WK', ...
    'Lambda_s','Kp_WK','Ki_WKs'});

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
out.plants = cell(nCycles,1);
rows = cell(nCycles*numel(capacity_kW),1);
r = 0;
for i = 1:nCycles
    index = find(stems==s.cycles(i),1);
    if isempty(index)
        error('EVThermal:UnknownCycle','System cycle %s was not run.',s.cycles(i));
    end
    % Repeat the cycle's one-second power and losses to the window length.
    detail = results.motorHeat.details{index};
    samples = height(detail)-1;
    pick = mod(time_s,samples)+1;
    drive = table(repmat(detail.Cycle(1),numel(time_s),1),time_s, ...
        detail.DCLinkPower_kW(pick),detail.DriveUnitHeat_kW(pick), ...
        detail.MotorLoss_kW(pick),detail.ControllerLoss_kW(pick), ...
        'VariableNames',{'Cycle','Time_s','DCLinkPower_kW','DriveUnitHeat_kW', ...
        'MotorLoss_kW','ControllerLoss_kW'});
    plant = p;
    plant.ambient_C = results.motorHeat.ambient_C(index);
    plant.radiatorUA_WK = p.motor.radiatorUA_WK;
    if results.motorHeat.fanOnly(index)
        plant.radiatorUA_WK = p.motor.fanOnlyRadiatorUA_WK;
    end
    out.inputs{i} = struct('drive',drive,'ambient_C',plant.ambient_C, ...
        'radiatorUA_WK',plant.radiatorUA_WK);
    out.plants{i} = plant;
    for j = 1:numel(capacity_kW)
        trace = simulate_system_thermal(time_s,drive,cabinGrid_C,cabinLoad_kW, ...
            capacity_kW(j),plant);
        out.traces{i,j} = trace;
        r = r+1;
        rows{r} = summarize(trace,detail.Cycle(1),s.cycles(i), ...
            compressorName(j),capacity_kW(j),s);
    end
end
out.summary = vertcat(rows{:});

% Cabin pull-down depends on the interior thermal mass, which is a
% screening value (register C23-C25): rerun the L6 case at each, with the
% cabin PI retuned for each mass.
l6 = find(s.cycles=="project_l6_continuous_grade",1);
masses_kJK = [a.C23;a.C24;a.C25];
comfort_s = nan(numel(masses_kJK),1);
for k = 1:numel(masses_kJK)
    q = out.plants{l6};
    q.cabinCapacitance_JK = 1000*masses_kJK(k);
    q.control.cabinKp_WK = q.cabinCapacitance_JK/q.control.cabinLambda_s;
    tr = simulate_system_thermal(time_s,out.inputs{l6}.drive,cabinGrid_C, ...
        cabinLoad_kW,capacity_kW(end),q);
    first = find(tr.Cabin_C<=s.cabinSetpoint_C+s.comfortBand_C,1);
    if ~isempty(first)
        comfort_s(k) = time_s(first);
    end
end
out.cabinMassSensitivity = table(masses_kJK,comfort_s/60, ...
    'VariableNames',{'CabinThermalMass_kJK','TimeToComfortL6Recommended_min'});

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
writetable(out.controllerGains,fullfile(outputDir,"controller_gains.csv"));
writetable(out.cabinMassSensitivity,fullfile(outputDir,"cabin_mass_sensitivity.csv"));
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
requested_kWh = sum(max(trace.RequestedDCPower_kW,0).*dt)/3600;
unmet_kWh = sum(trace.UnmetDCPower_kW.*dt)/3600;
row = table(cycleName,stem,compressor,capacity_kW,timeToComfort_s, ...
    trace.Cabin_C(end),max(trace.Cell_C),trace.Cell_C(end), ...
    sum(dt(trace.Cell_C>55)),trace.BatteryCoolant_C(end), ...
    100*mean(trace.CompressorUse),sum(dt(trace.BatteryPriority)), ...
    min(trace.DerateFactor),100*unmet_kWh/max(requested_kWh,eps), ...
    trace.SOC_pct(end),max(trace.DriveUnit_C),max(trace.PropulsionCoolant_C), ...
    'VariableNames',{'Cycle','FileStem','Compressor','Capacity_kW', ...
    'TimeToCabinComfort_s','CabinAtEnd_C','PeakCell_C','CellAtEnd_C', ...
    'TimeCellAbove55C_s','BatteryCoolantAtEnd_C','MeanCompressorUse_pct', ...
    'TimeBatteryPriority_s','MinimumDerateFactor','UnmetTractionEnergy_pct', ...
    'SOCAtEnd_pct','PeakDriveUnit_C','PeakPropulsionCoolant_C'});
end

function plot_system(out,s,battery,outputDir)
blue = [0.165 0.471 0.839]; orange = [0.922 0.408 0.204]; aqua = [0.106 0.686 0.478];
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

i = find(s.cycles==shown(1));
nexttile;
tr = out.traces{i,2};
duty = area(tr.Time_s/60,[tr.EvaporatorDuty_kW tr.ChillerDuty_kW],'EdgeColor','none');
duty(1).FaceColor = blue;
duty(2).FaceColor = aqua;
hold on;
plot(tr.Time_s/60,tr.CabinDemand_kW,'-','Color',[0.1 0.1 0.1],'LineWidth',1);
plot(tr.Time_s/60,tr.BatteryDemand_kW,':','Color',[0.1 0.1 0.1],'LineWidth',1.4);
yline(out.capacity_kW(2),'k--',sprintf('Capacity %.1f kW',out.capacity_kW(2)), ...
    'HandleVisibility','off');
grid on; xlabel('Time (min)'); ylabel('Refrigeration duty (kW)');
ylim([0 1.15*out.capacity_kW(2)]);
legend({'Cabin evaporator','Battery chiller','Cabin PI demand','Battery PI demand'}, ...
    'Location','east','FontSize',8);
title('L6, recommended compressor: PI demands and the duty each loop gets');

nexttile;
hold on;
for j = 1:numel(out.capacity_kW)
    tr = out.traces{i,j};
    plot(tr.Time_s/60,tr.DerateFactor,'-','Color',colors(j,:),'LineWidth',2, ...
        'DisplayName',sprintf('Derate factor, %s',out.compressorName(j)));
    stairs(tr.Time_s/60,0.05+0.9*tr.BatteryPriority,':','Color',colors(j,:), ...
        'LineWidth',1.2,'DisplayName',sprintf('Battery priority on, %s',out.compressorName(j)));
end
grid on; ylim([0 1.1]); xlabel('Time (min)'); ylabel('Fraction of requested power');
legend('Location','southwest','FontSize',8);
title('L6: BMS and motor derating, and compressor priority');

cycleColors = [blue;orange;aqua;0.929 0.631 0;0.910 0.482 0.643];
nexttile;
hold on;
for i = 1:numel(s.cycles)
    tr = out.traces{i,end};
    plot(tr.Time_s/60,tr.DriveUnit_C,'-','Color',cycleColors(i,:),'LineWidth',1.6, ...
        'DisplayName',out.summary.Cycle(2*i));
    plot(tr.Time_s/60,tr.PropulsionCoolant_C,':','Color',cycleColors(i,:), ...
        'LineWidth',1.4,'HandleVisibility','off');
end
yline(150,':','Motor derate starts 150 C','HandleVisibility','off');
grid on; xlabel('Time (min)'); ylabel('Temperature (C)');
title('Propulsion loop: winding (solid) and its coolant (dotted)');
legend('Location','northwest','FontSize',7,'Interpreter','none');
nexttile;
hold on;
for i = 1:numel(s.cycles)
    tr = out.traces{i,end};
    plot(tr.Time_s/60,tr.SOC_pct,'-','Color',cycleColors(i,:),'LineWidth',1.6, ...
        'DisplayName',out.summary.Cycle(2*i));
end
grid on; xlabel('Time (min)'); ylabel('State of charge (%)'); ylim([0 100]);
title('Battery state of charge, integrated from the delivered current');
legend('Location','southwest','FontSize',7,'Interpreter','none');
title(layout,'Closed-loop system: every loop driven by the drive cycle from a hot soak on a 45 C day');
exportgraphics(fig,fullfile(outputDir,"system_thermal_response.png"),'Resolution',160);
close(fig);
end
