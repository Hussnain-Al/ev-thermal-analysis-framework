function modelFile = build_system_thermal_simscape(cfg,systemThermal,options)
%BUILD_SYSTEM_THERMAL_SIMSCAPE Closed-loop Simscape model of all three loops.
% Builds the system of run_system_thermal as three Simscape thermal networks
% (foundation library) driven by one drive cycle, with the thermal
% management controls in Simulink:
%   - battery: delivered DC power / loaded pack voltage = current; state of
%     charge integrated from it; heat = I^2 R_DC - I T dU/dT(SOC) per cell;
%     cell and battery-coolant masses joined by the cell-to-coolant path;
%   - cabin: thermal mass with the heat-balance load at its own temperature
%     less the evaporator duty;
%   - propulsion: winding and coolant masses joined by the winding-to-coolant
%     resistance; motor loss into the winding, controller loss into the
%     coolant; radiator UA max(T_coolant - T_ambient, 0);
%   - controls: cabin and battery-coolant PI loops with back-calculation
%     anti-windup, a cascade that lowers the coolant set point when the cells
%     run hot, a compressor priority relay with hysteresis, and BMS and motor
%     derating of the requested power.
% Example:
%   cfg = setup_project(); results = run_all(cfg);
%   build_system_thermal_simscape(cfg,results.systemThermal, ...
%       CycleStem="project_l6_continuous_grade",Capacity_kW=8,Overwrite=true);
% Requires Simulink and Simscape. No refrigerant circuit is modelled.

arguments
    cfg (1,1) struct
    systemThermal (1,1) struct
    options.CycleStem (1,1) string = "project_l6_continuous_grade"
    options.Capacity_kW (1,1) double = NaN
    options.Overwrite (1,1) logical = false
end

if isempty(ver('simulink')) || isempty(ver('simscape'))
    error('EVThermal:SimscapeRequired', ...
        'Simulink and Simscape are required to build the system thermal model.');
end

s = cfg.systemThermal;
capacity_kW = options.Capacity_kW;
if isnan(capacity_kW)
    capacity_kW = systemThermal.capacity_kW(end);
end
cycleIndex = find(s.cycles==options.CycleStem,1);
if isempty(cycleIndex)
    error('EVThermal:UnknownCycle','Unknown system cycle %s.',options.CycleStem);
end
p = systemThermal.plants{cycleIndex};
c = p.control;
battery = p.battery;
motor = p.motor;
drive = systemThermal.inputs{cycleIndex}.drive;
curve = systemThermal.cabinLoadCurve;
cap_W = 1000*capacity_kW;

modelDir = fullfile(cfg.project.rootDir,'models','system_thermal');
modelName = "system_thermal_simscape";
modelFile = fullfile(modelDir,modelName+".slx");
if isfile(modelFile) && ~options.Overwrite
    error('EVThermal:ModelExists', ...
        'Model already exists: %s\nUse Overwrite=true to replace it.',modelFile);
end
if bdIsLoaded(modelName)
    close_system(modelName,0);
end
if isfile(modelFile)
    delete(modelFile);
end
load_system('fl_lib');
load_system('nesl_utility');
new_system(modelName,'Model');
load_system(modelName);
set_param(modelName,'SolverType','Variable-step','Solver','ode23t', ...
    'MaxStep','1','RelTol','1e-5','StartTime','0', ...
    'StopTime',num2str(drive.Time_s(end)), ...
    'SaveOutput','on','OutputSaveName','yout','SaveFormat','Dataset');
m = char(modelName);
K0 = 273.15;

thermal = 'fl_lib/Thermal/';
massLib = [thermal 'Thermal Elements/Thermal Mass'];
sourceLib = [thermal sprintf('Thermal Sources/Controlled Heat Flow\nRate Source')];
sensorLib = [thermal 'Thermal Sensors/Temperature Sensor'];
toPS = sprintf('nesl_utility/Simulink-PS\nConverter');
fromPS = sprintf('nesl_utility/PS-Simulink\nConverter');
solverLib = sprintf('nesl_utility/Solver\nConfiguration');

% Physical networks (three, each with its own solver configuration).
add_block(solverLib,[m '/Cabin solver'],'Position',[780 160 840 190]);
add_block(solverLib,[m '/Battery solver'],'Position',[780 600 840 630]);
add_block(solverLib,[m '/Propulsion solver'],'Position',[780 1000 840 1030]);
add_mass(m,'Cabin',massLib,p.cabinCapacitance_JK,p.cabinInitial_C+K0,[700 80 760 140]);
add_mass(m,'Cell',massLib,p.packCapacitance_JK,p.packInitial_C+K0,[700 300 760 360]);
add_mass(m,'Battery coolant',massLib,p.batteryCoolantCapacitance_JK, ...
    p.batteryCoolantInitial_C+K0,[700 480 760 540]);
add_block([thermal 'Thermal Elements/Thermal Resistance'],[m '/Cell to coolant path'], ...
    'Position',[820 400 880 430], ...
    'resistance',num2str(p.packResistance_KW,12),'resistance_unit','K/W');
connect(m,'Cell','LConn',1,'Cell to coolant path','LConn',1);
connect(m,'Cell to coolant path','RConn',1,'Battery coolant','LConn',1);
connect(m,'Cabin solver','RConn',1,'Cabin','LConn',1);
connect(m,'Battery solver','RConn',1,'Cell','LConn',1);
add_mass(m,'Drive unit',massLib,motor.motorThermalCapacity_JK, ...
    motor.initialMotorTemperature_C+K0,[700 900 760 960]);
add_mass(m,'Propulsion coolant',massLib,motor.coolantThermalCapacity_JK, ...
    motor.initialCoolantTemperature_C+K0,[700 1100 760 1160]);
add_block([thermal 'Thermal Elements/Thermal Resistance'],[m '/Winding to coolant'], ...
    'Position',[820 1020 880 1050], ...
    'resistance',num2str(motor.motorToCoolantResistance_KW,12),'resistance_unit','K/W');
connect(m,'Drive unit','LConn',1,'Winding to coolant','LConn',1);
connect(m,'Winding to coolant','RConn',1,'Propulsion coolant','LConn',1);
connect(m,'Propulsion solver','RConn',1,'Drive unit','LConn',1);

add_source(m,'Cabin net heat',sourceLib,toPS,'Cabin',[560 80 620 140]);
add_source(m,'Battery heat',sourceLib,toPS,'Cell',[560 300 620 360]);
add_source(m,'Chiller extraction',sourceLib,toPS,'Battery coolant',[560 480 620 540]);
add_source(m,'Motor loss',sourceLib,toPS,'Drive unit',[560 900 620 960]);
add_source(m,'Controller loss',sourceLib,toPS,'Propulsion coolant',[560 1000 620 1060]);
add_source(m,'Radiator rejection',sourceLib,toPS,'Propulsion coolant',[560 1100 620 1160]);
add_sensor(m,'Cabin',sensorLib,fromPS,[900 80 960 140]);
add_sensor(m,'Cell',sensorLib,fromPS,[900 260 960 320]);
add_sensor(m,'Battery coolant',sensorLib,fromPS,[900 480 960 540]);
add_sensor(m,'Drive unit',sensorLib,fromPS,[900 900 960 960]);
add_sensor(m,'Propulsion coolant',sensorLib,fromPS,[900 1100 960 1160]);

% Drive cycle: requested DC-link power and losses, held over each second.
add_block('simulink/Sources/Clock',[m '/Clock'],'Position',[40 700 70 720]);
cycleTable(m,'Requested power W',drive.Time_s,1000*drive.DCLinkPower_kW,[120 690 200 730]);
cycleTable(m,'Motor loss request W',drive.Time_s,1000*drive.MotorLoss_kW,[120 900 200 940]);
cycleTable(m,'Controller loss request W',drive.Time_s,1000*drive.ControllerLoss_kW,[120 1000 200 1040]);
add_line(m,'Clock/1','Requested power W/1');
add_line(m,'Clock/1','Motor loss request W/1');
add_line(m,'Clock/1','Controller loss request W/1');

% Derating: BMS discharge and charge curves on cell temperature, motor
% curve on winding temperature; regen (negative request) uses the charge curve.
ramp(m,'BMS discharge',c.dischargeDerate_C,[1300 600 1370 630]);
ramp(m,'BMS charge',c.chargeDerate_C,[1300 660 1370 690]);
ramp(m,'Motor derate',c.motorDerate_C,[1300 900 1370 930]);
add_line(m,'Cell C/1','BMS discharge/1');
add_line(m,'Cell C/1','BMS charge/1');
add_line(m,'Drive unit C/1','Motor derate/1');
minmax(m,'Discharge factor','min',[1400 600 1430 640]);
add_line(m,'BMS discharge/1','Discharge factor/1');
add_line(m,'Motor derate/1','Discharge factor/2');
minmax(m,'Charge factor','min',[1400 660 1430 700]);
add_line(m,'BMS charge/1','Charge factor/1');
add_line(m,'Motor derate/1','Charge factor/2');
switch3(m,'Derate factor',0,[1460 620 1500 700]);
add_line(m,'Discharge factor/1','Derate factor/1');
add_line(m,'Requested power W/1','Derate factor/2');
add_line(m,'Charge factor/1','Derate factor/3');
product2(m,'Delivered power W',[240 690 270 740]);
add_line(m,'Requested power W/1','Delivered power W/1');
add_line(m,'Derate factor/1','Delivered power W/2');
product2(m,'Motor loss W',[240 900 270 950]);
add_line(m,'Motor loss request W/1','Motor loss W/1');
add_line(m,'Derate factor/1','Motor loss W/2');
add_line(m,'Motor loss W/1','Motor loss input/1');
product2(m,'Controller loss W',[240 1000 270 1050]);
add_line(m,'Controller loss request W/1','Controller loss W/1');
add_line(m,'Derate factor/1','Controller loss W/2');
add_line(m,'Controller loss W/1','Controller loss input/1');

% Battery electrical side on the delivered power.
gain(m,'Pack current A',1/battery.cycleVoltage_V,[300 695 350 725]);
add_line(m,'Delivered power W/1','Pack current A/1');
gain(m,'SOC rate',-100/(battery.capacity_Ah*3600),[380 760 430 790]);
add_line(m,'Pack current A/1','SOC rate/1');
add_block('simulink/Continuous/Integrator',[m '/SOC'], ...
    'InitialCondition',num2str(battery.cycleInitialSOC_pct,12),'Position',[460 760 490 790]);
add_line(m,'SOC rate/1','SOC/1');
add_block('simulink/Discontinuities/Saturation',[m '/SOC 0-100'],'UpperLimit','100', ...
    'LowerLimit','0','Position',[520 760 560 790]);
add_line(m,'SOC/1','SOC 0-100/1');
add_block('simulink/Lookup Tables/1-D Lookup Table',[m '/dUdT V per K'], ...
    'Position',[590 755 660 795], ...
    'BreakpointsForDimension1',mat2str(battery.entropicSOC_pct), ...
    'Table',mat2str(1e-3*battery.entropic_mVK),'ExtrapMethod','Clip');
add_line(m,'SOC 0-100/1','dUdT V per K/1');
product2(m,'Current squared',[390 640 420 690]);
add_line(m,'Pack current A/1','Current squared/1');
add_line(m,'Pack current A/1','Current squared/2');
gain(m,'Joule heat W',battery.dcResistance25_Ohm*battery.seriesCells,[450 650 510 680]);
add_line(m,'Current squared/1','Joule heat W/1');
product2(m,'Current x dUdT',[690 720 720 790]);
add_line(m,'Pack current A/1','Current x dUdT/1');
add_line(m,'dUdT V per K/1','Current x dUdT/2');
gain(m,'Entropic heat W', ...
    -(battery.entropicReferenceTemperature_C+K0)*battery.seriesCells,[750 740 810 770]);
add_line(m,'Current x dUdT/1','Entropic heat W/1');
sum2(m,'Battery heat W','++',[470 300 500 360]);
add_line(m,'Joule heat W/1','Battery heat W/1');
add_line(m,'Entropic heat W/1','Battery heat W/2');
add_line(m,'Battery heat W/1','Battery heat input/1');

% Thermal management: PI loops with back-calculation anti-windup.
bias(m,'Cabin error',-p.cabinSetpoint_C,[1100 40 1150 70]);
add_line(m,'Cabin C/1','Cabin error/1');
% Cascade: coolant set point = nominal - gain (T_cell - target), clamped
% between the floor and the nominal value.
bias(m,'Cell excess',-c.cellTarget_C,[950 380 1000 410]);
add_line(m,'Cell C/1','Cell excess/1');
gain(m,'Set point drop',-c.cascadeGain_KK,[1010 380 1050 410]);
add_line(m,'Cell excess/1','Set point drop/1');
bias(m,'Coolant set point raw',p.batteryCoolantSetpoint_C,[1060 380 1100 410]);
add_line(m,'Set point drop/1','Coolant set point raw/1');
add_block('simulink/Discontinuities/Saturation',[m '/Coolant set point'], ...
    'UpperLimit',num2str(p.batteryCoolantSetpoint_C),'LowerLimit', ...
    num2str(c.coolantSetpointFloor_C),'Position',[1110 380 1150 410]);
add_line(m,'Coolant set point raw/1','Coolant set point/1');
sum2(m,'Battery error','+-',[1160 300 1190 360]);
add_line(m,'Battery coolant C/1','Battery error/1');
add_line(m,'Coolant set point/1','Battery error/2');
add_pi(m,'Cabin',c.cabinKp_WK,c.cabinKi_WKs,cap_W,[1100 40]);
add_pi(m,'Battery',c.batteryKp_WK,c.batteryKi_WKs,cap_W,[1100 300]);

% Compressor priority: battery first between the relay's on and off points.
add_block('simulink/Discontinuities/Relay',[m '/Battery priority'], ...
    'OnSwitchValue',num2str(c.priorityOn_C),'OffSwitchValue',num2str(c.priorityOff_C), ...
    'OnOutputValue','1','OffOutputValue','0','Position',[1300 200 1340 230]);
add_line(m,'Cell C/1','Battery priority/1');
add_block('simulink/Sources/Constant',[m '/Capacity W'],'Value',num2str(cap_W,12), ...
    'Position',[1300 140 1360 160]);
sum2(m,'Capacity left after battery','+-',[1400 120 1430 170]);
add_line(m,'Capacity W/1','Capacity left after battery/1');
add_line(m,'Battery demand/1','Capacity left after battery/2');
minmax(m,'Evaporator battery first','min',[1460 60 1490 120]);
add_line(m,'Cabin demand/1','Evaporator battery first/1');
add_line(m,'Capacity left after battery/1','Evaporator battery first/2');
sum2(m,'Capacity left after cabin','+-',[1400 260 1430 310]);
add_line(m,'Capacity W/1','Capacity left after cabin/1');
add_line(m,'Cabin demand/1','Capacity left after cabin/2');
minmax(m,'Chiller cabin first','min',[1460 300 1490 360]);
add_line(m,'Battery demand/1','Chiller cabin first/1');
add_line(m,'Capacity left after cabin/1','Chiller cabin first/2');
switch3(m,'Evaporator duty W',0.5,[1540 60 1580 140]);
add_line(m,'Evaporator battery first/1','Evaporator duty W/1');
add_line(m,'Battery priority/1','Evaporator duty W/2');
add_line(m,'Cabin demand/1','Evaporator duty W/3');
switch3(m,'Chiller duty W',0.5,[1540 280 1580 360]);
add_line(m,'Battery demand/1','Chiller duty W/1');
add_line(m,'Battery priority/1','Chiller duty W/2');
add_line(m,'Chiller cabin first/1','Chiller duty W/3');

% Anti-windup feedback: what each loop actually got.
add_line(m,'Evaporator duty W/1','Cabin tracking/1');
add_line(m,'Chiller duty W/1','Battery tracking/1');

% Cabin net heat and chiller extraction.
add_block('simulink/Lookup Tables/1-D Lookup Table',[m '/Cabin load W'], ...
    'Position',[1100 160 1180 200], ...
    'BreakpointsForDimension1',mat2str(curve.Cabin_C'), ...
    'Table',mat2str(1000*curve.CabinLoad_kW',10),'ExtrapMethod','Linear');
add_line(m,'Cabin C/1','Cabin load W/1');
sum2(m,'Cabin net','+-',[400 90 430 150]);
add_line(m,'Cabin load W/1','Cabin net/1');
add_line(m,'Evaporator duty W/1','Cabin net/2');
add_line(m,'Cabin net/1','Cabin net heat input/1');
gain(m,'Extract',-1,[400 495 440 525]);
add_line(m,'Chiller duty W/1','Extract/1');
add_line(m,'Extract/1','Chiller extraction input/1');

% Radiator: UA max(T_coolant - T_ambient, 0), taken out of the coolant.
bias(m,'Above ambient',-p.ambient_C,[1100 1110 1150 1140]);
add_line(m,'Propulsion coolant C/1','Above ambient/1');
gain(m,'Radiator UA',p.radiatorUA_WK,[1180 1110 1230 1140]);
add_line(m,'Above ambient/1','Radiator UA/1');
floor0(m,'Radiator duty W',[1260 1110 1300 1140]);
add_line(m,'Radiator UA/1','Radiator duty W/1');
gain(m,'Reject',-1,[400 1115 440 1145]);
add_line(m,'Radiator duty W/1','Reject/1');
add_line(m,'Reject/1','Radiator rejection input/1');

names = ["Cabin C","Cell C","Battery coolant C","Evaporator duty W","Chiller duty W", ...
    "Drive unit C","Propulsion coolant C","Battery heat W","SOC 0-100","Derate factor"];
for k = 1:numel(names)
    out = sprintf('%s/%s out',m,names(k));
    add_block('simulink/Sinks/Out1',out,'Position',[1800 60+80*k 1830 74+80*k]);
    add_line(m,char(names(k)+"/1"),char(names(k)+" out/1"),'autorouting','on');
end
save_system(modelName,modelFile);
close_system(modelName,0);
end

function add_pi(m,name,kp,ki,limit_W,origin)
% PI on the existing [name ' error'] signal. Back-calculation anti-windup:
% the integrator input is Ki e + (Ki/Kp) (delivered - unsaturated demand);
% the delivered duty is wired into [name ' tracking'] input 1 later.
x = origin(1)+60; y = origin(2);
gain(m,[name ' Kp'],kp,[x+80 y x+130 y+30]);
gain(m,[name ' Ki'],ki,[x+80 y+50 x+130 y+80]);
sum2(m,[name ' tracking'],'+-',[x+80 y+100 x+110 y+150]);
gain(m,[name ' back-calculation'],ki/kp,[x+120 y+110 x+160 y+140]);
sum2(m,[name ' integrator input'],'++',[x+170 y+50 x+200 y+110]);
add_block('simulink/Continuous/Integrator',[m '/' name ' integral'], ...
    'InitialCondition','0','Position',[x+210 y+60 x+240 y+90]);
sum2(m,[name ' PI'],'++',[x+260 y x+290 y+80]);
add_block('simulink/Discontinuities/Saturation',[m '/' name ' demand'], ...
    'UpperLimit',num2str(limit_W,12),'LowerLimit','0','Position',[x+310 y+25 x+350 y+55]);
add_line(m,[name ' error/1'],[name ' Kp/1']);
add_line(m,[name ' error/1'],[name ' Ki/1']);
add_line(m,[name ' Ki/1'],[name ' integrator input/1']);
add_line(m,[name ' back-calculation/1'],[name ' integrator input/2']);
add_line(m,[name ' tracking/1'],[name ' back-calculation/1']);
add_line(m,[name ' integrator input/1'],[name ' integral/1']);
add_line(m,[name ' Kp/1'],[name ' PI/1']);
add_line(m,[name ' integral/1'],[name ' PI/2']);
add_line(m,[name ' PI/1'],[name ' demand/1']);
add_line(m,[name ' PI/1'],[name ' tracking/2']);
end

function ramp(m,name,limits,position)
% 1 at or below limits(1), 0 at or above limits(2), linear between.
add_block('simulink/Lookup Tables/1-D Lookup Table',[m '/' name],'Position',position, ...
    'BreakpointsForDimension1',mat2str(limits),'Table','[1 0]','ExtrapMethod','Clip');
end

function switch3(m,name,threshold,position)
% Passes input 1 when input 2 >= threshold, otherwise input 3.
add_block('simulink/Signal Routing/Switch',[m '/' name],'Criteria','u2 >= Threshold', ...
    'Threshold',num2str(threshold),'Position',position);
end

function cycleTable(m,name,time_s,values,position)
add_block('simulink/Lookup Tables/1-D Lookup Table',[m '/' name],'Position',position, ...
    'BreakpointsForDimension1',mat2str(time_s'),'Table',mat2str(values',10), ...
    'InterpMethod','Flat','ExtrapMethod','Clip');
end

function add_mass(m,name,lib,capacitance_JK,initial_K,position)
add_block(lib,[m '/' name],'Position',position,'mass',num2str(capacitance_JK,12), ...
    'mass_unit','kg','sp_heat','1','sp_heat_unit','J/(kg*K)', ...
    'T_specify','on','T_priority','High','T',num2str(initial_K,12),'T_unit','K');
end

function add_reference(m,name,position)
add_block('fl_lib/Thermal/Thermal Elements/Thermal Reference',[m '/' name], ...
    'Position',position);
end

function add_source(m,name,lib,toPS,massName,position)
add_block(lib,[m '/' name],'Position',position);
reference = [name ' reference'];
add_reference(m,reference,[position(1)-30 position(4)+30 position(1)+10 position(4)+60]);
converter = [name ' converter'];
add_block(toPS,[m '/' converter],'Unit','W', ...
    'Position',[position(1)-120 position(2)+10 position(1)-60 position(4)-10]);
add_block('simulink/Math Operations/Gain',[m '/' name ' input'],'Gain','1', ...
    'Position',[position(1)-220 position(2)+15 position(1)-170 position(4)-15]);
add_line(m,[name ' input/1'],[converter '/1']);
pc = get_param([m '/' converter],'PortHandles');
thermalPorts = connect_signal_port(m,pc.RConn(1),name);
% A positive input delivers heat into the source's first thermal port,
% which goes on the mass; the second goes to the reference. (Checked in CI:
% the reverse wiring makes the cabin run away instead of cooling.)
add_line(m,thermalPorts(1),port_of(m,massName,'LConn',1),'autorouting','on');
add_line(m,thermalPorts(2),port_of(m,reference,'LConn',1),'autorouting','on');
end

function add_sensor(m,massName,lib,fromPS,position)
sensor = [massName ' sensor'];
add_block(lib,[m '/' sensor],'Position',position);
reference = [sensor ' reference'];
add_reference(m,reference,[position(3)+10 position(4)+30 position(3)+50 position(4)+60]);
converter = [massName ' K'];
add_block(fromPS,[m '/' converter],'Position',position+[100 10 100 -10],'Unit','K');
pc = get_param([m '/' converter],'PortHandles');
thermalPorts = connect_signal_port(m,pc.LConn(1),sensor);
% The sensor reads port A against port B: A on the mass, B on the reference.
add_line(m,port_of(m,massName,'LConn',1),thermalPorts(1),'autorouting','on');
add_line(m,thermalPorts(2),port_of(m,reference,'LConn',1),'autorouting','on');
add_block('simulink/Math Operations/Bias',[m '/' massName ' C'],'Bias','-273.15', ...
    'Position',position+[180 15 210 -15]);
add_line(m,[converter '/1'],[massName ' C/1']);
end

function thermalPorts = connect_signal_port(m,signalPort,blockName)
% Simscape rejects a line between different domains, so the physical-signal
% port is the one candidate that accepts the converter. The remaining ports
% are the thermal ports, in library order (A, then B).
ph = get_param([m '/' blockName],'PortHandles');
candidates = [ph.LConn ph.RConn];
used = 0;
for k = 1:numel(candidates)
    try
        add_line(m,signalPort,candidates(k),'autorouting','on');
        used = k;
        break
    catch
    end
end
if used==0
    error('EVThermal:SimscapeBuild','No physical-signal port found on %s.',blockName);
end
thermalPorts = candidates(setdiff(1:numel(candidates),used));
end

function h = port_of(m,blockName,side,index)
ph = get_param([m '/' blockName],'PortHandles');
h = ph.(side)(index);
end

function connect(m,a,aSide,aIndex,b,bSide,bIndex)
pa = get_param([m '/' a],'PortHandles');
pb = get_param([m '/' b],'PortHandles');
add_line(m,pa.(aSide)(aIndex),pb.(bSide)(bIndex),'autorouting','on');
end

function gain(m,name,value,position)
add_block('simulink/Math Operations/Gain',[m '/' name],'Gain',num2str(value,12), ...
    'Position',position);
end

function bias(m,name,value,position)
add_block('simulink/Math Operations/Bias',[m '/' name],'Bias',num2str(value,12), ...
    'Position',position);
end

function sum2(m,name,signs,position)
add_block('simulink/Math Operations/Sum',[m '/' name],'Inputs',signs, ...
    'Position',position);
end

function floor0(m,name,position)
add_block('simulink/Discontinuities/Saturation',[m '/' name],'UpperLimit','inf', ...
    'LowerLimit','0','Position',position);
end

function minmax(m,name,fn,position)
add_block('simulink/Math Operations/MinMax',[m '/' name],'Function',fn, ...
    'Inputs','2','Position',position);
end

function product2(m,name,position)
add_block('simulink/Math Operations/Product',[m '/' name],'Inputs','**', ...
    'Position',position);
end
