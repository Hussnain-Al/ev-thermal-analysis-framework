function modelFile = build_system_thermal_simscape(cfg,systemThermal,options)
%BUILD_SYSTEM_THERMAL_SIMSCAPE Simscape model of the cabin and battery loops.
% Builds the coupled system of run_system_thermal as a Simscape thermal
% network (foundation library) with the compressor allocation in Simulink:
%   - cabin, cell (pack) and battery-coolant thermal masses;
%   - pack-to-coolant thermal resistance (cell path / series cells);
%   - heat-flow sources for battery heat (drive-cycle trace), net cabin heat
%     and chiller extraction;
%   - Simulink logic: cabin load lookup, demands, proportional sharing of
%     the compressor capacity.
% Example:
%   cfg = setup_project(); results = run_all(cfg);
%   build_system_thermal_simscape(cfg,results.systemThermal, ...
%       CycleStem="project_l6_continuous_grade",Capacity_kW=9.19,Overwrite=true);
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
p = systemThermal.parameters;
capacity_kW = options.Capacity_kW;
if isnan(capacity_kW)
    capacity_kW = systemThermal.capacity_kW(end);
end
cycleIndex = find(s.cycles==options.CycleStem,1);
if isempty(cycleIndex)
    error('EVThermal:UnknownCycle','Unknown system cycle %s.',options.CycleStem);
end
trace = systemThermal.traces{cycleIndex,1};
curve = systemThermal.cabinLoadCurve;

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
    'StopTime',num2str(trace.Time_s(end)), ...
    'SaveOutput','on','OutputSaveName','yout','SaveFormat','Dataset');
m = char(modelName);
K0 = 273.15;

thermal = 'fl_lib/Thermal/';
massLib = [thermal 'Thermal Elements/Thermal Mass'];
sourceLib = [thermal sprintf('Thermal Sources/Controlled Heat Flow\nRate Source')];
sensorLib = [thermal 'Thermal Sensors/Temperature Sensor'];
toPS = sprintf('nesl_utility/Simulink-PS\nConverter');
fromPS = sprintf('nesl_utility/PS-Simulink\nConverter');

% Physical network.
% The cabin and battery networks are physically separate, so each has
% its own solver configuration.
solverLib = sprintf('nesl_utility/Solver\nConfiguration');
add_block(solverLib,[m '/Cabin solver'],'Position',[780 160 840 190]);
add_block(solverLib,[m '/Battery solver'],'Position',[780 600 840 630]);
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

add_source(m,'Cabin net heat',sourceLib,toPS,'Cabin',[560 80 620 140]);
add_source(m,'Battery heat',sourceLib,toPS,'Cell',[560 300 620 360]);
add_source(m,'Chiller extraction',sourceLib,toPS,'Battery coolant',[560 480 620 540]);
add_sensor(m,'Cabin',sensorLib,fromPS,[900 80 960 140]);
add_sensor(m,'Cell',sensorLib,fromPS,[900 260 960 320]);
add_sensor(m,'Battery coolant',sensorLib,fromPS,[900 480 960 540]);

% Battery heat from the drive-cycle trace.
add_block('simulink/Sources/Clock',[m '/Clock'],'Position',[60 320 90 340]);
add_block('simulink/Lookup Tables/1-D Lookup Table',[m '/Battery heat trace W'], ...
    'Position',[140 310 220 350], ...
    'BreakpointsForDimension1',mat2str(trace.Time_s'), ...
    'Table',mat2str(1000*trace.BatteryHeat_kW',10),'ExtrapMethod','Clip');
add_line(m,'Clock/1','Battery heat trace W/1');
add_line(m,'Battery heat trace W/1','Battery heat input/1');

% Compressor allocation (same equations as simulate_system_thermal).
add_block('simulink/Lookup Tables/1-D Lookup Table',[m '/Cabin load W'], ...
    'Position',[1100 40 1180 80], ...
    'BreakpointsForDimension1',mat2str(curve.Cabin_C'), ...
    'Table',mat2str(1000*curve.CabinLoad_kW',10),'ExtrapMethod','Linear');
add_line(m,'Cabin C/1','Cabin load W/1');
gain(m,'Cabin error gain',p.controllerGain_WK,[1180 120 1230 150]);
bias(m,'Cabin error',-p.cabinSetpoint_C,[1100 120 1150 150]);
add_line(m,'Cabin C/1','Cabin error/1');
add_line(m,'Cabin error/1','Cabin error gain/1');
sum2(m,'Cabin demand raw','++',[1260 60 1290 130]);
add_line(m,'Cabin load W/1','Cabin demand raw/1');
add_line(m,'Cabin error gain/1','Cabin demand raw/2');
floor0(m,'Cabin demand',[1320 80 1360 110]);
add_line(m,'Cabin demand raw/1','Cabin demand/1');

sum2(m,'Cell minus coolant','+-',[1100 280 1130 340]);
add_line(m,'Cell C/1','Cell minus coolant/1');
add_line(m,'Battery coolant C/1','Cell minus coolant/2');
gain(m,'Heat to coolant',1/p.packResistance_KW,[1160 295 1210 325]);
add_line(m,'Cell minus coolant/1','Heat to coolant/1');
bias(m,'Coolant error',-p.batteryCoolantSetpoint_C,[1100 380 1150 410]);
add_line(m,'Battery coolant C/1','Coolant error/1');
gain(m,'Coolant error gain',p.controllerGain_WK,[1180 380 1230 410]);
add_line(m,'Coolant error/1','Coolant error gain/1');
sum2(m,'Battery demand raw','++',[1260 300 1290 400]);
add_line(m,'Heat to coolant/1','Battery demand raw/1');
add_line(m,'Coolant error gain/1','Battery demand raw/2');
floor0(m,'Battery demand',[1320 335 1360 365]);
add_line(m,'Battery demand raw/1','Battery demand/1');

sum2(m,'Total demand','++',[1400 180 1430 240]);
add_line(m,'Cabin demand/1','Total demand/1');
add_line(m,'Battery demand/1','Total demand/2');
add_block('simulink/Sources/Constant',[m '/Small demand'],'Value','1e-6', ...
    'Position',[1400 260 1440 280]);
minmax(m,'Nonzero demand','max',[1460 200 1490 260]);
add_line(m,'Total demand/1','Nonzero demand/1');
add_line(m,'Small demand/1','Nonzero demand/2');
add_block('simulink/Sources/Constant',[m '/Compressor capacity W'], ...
    'Value',num2str(1000*capacity_kW,12),'Position',[1460 140 1520 160]);
add_block('simulink/Math Operations/Product',[m '/Capacity over demand'], ...
    'Inputs','*/','Position',[1540 150 1570 230]);
add_line(m,'Compressor capacity W/1','Capacity over demand/1');
add_line(m,'Nonzero demand/1','Capacity over demand/2');
add_block('simulink/Sources/Constant',[m '/One'],'Value','1','Position',[1540 250 1570 270]);
minmax(m,'Share','min',[1600 180 1630 260]);
add_line(m,'Capacity over demand/1','Share/1');
add_line(m,'One/1','Share/2');
product2(m,'Evaporator duty W',[1680 80 1710 140]);
add_line(m,'Share/1','Evaporator duty W/1');
add_line(m,'Cabin demand/1','Evaporator duty W/2');
product2(m,'Chiller duty W',[1680 330 1710 390]);
add_line(m,'Share/1','Chiller duty W/1');
add_line(m,'Battery demand/1','Chiller duty W/2');

sum2(m,'Cabin net','+-',[400 90 430 150]);
add_line(m,'Cabin load W/1','Cabin net/1');
add_line(m,'Evaporator duty W/1','Cabin net/2');
add_line(m,'Cabin net/1','Cabin net heat input/1');
gain(m,'Extract',-1,[400 495 440 525]);
add_line(m,'Chiller duty W/1','Extract/1');
add_line(m,'Extract/1','Chiller extraction input/1');

names = ["Cabin C","Cell C","Battery coolant C","Evaporator duty W","Chiller duty W"];
for k = 1:numel(names)
    out = sprintf('%s/%s out',m,names(k));
    add_block('simulink/Sinks/Out1',out,'Position',[1800 60+80*k 1830 74+80*k]);
    add_line(m,char(names(k)+"/1"),char(names(k)+" out/1"),'autorouting','on');
end
save_system(modelName,modelFile);
close_system(modelName,0);
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
