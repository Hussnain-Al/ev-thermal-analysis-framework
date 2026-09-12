function modelFile = build_propulsion_thermal_sensitivity_simulink(cfg,options)
%BUILD_PROPULSION_THERMAL_SENSITIVITY_SIMULINK Build two-node model.
% Drive-unit heat, ambient temperature and radiator UA are model inputs.
% Thermal capacitances and motor-to-coolant resistance are exposed
% calibration assumptions. The model is not a validated temperature plant.

arguments
    cfg (1,1) struct = setup_project()
    options.Overwrite (1,1) logical = false
end

if isempty(ver('simulink'))
    error('EVThermal:SimulinkRequired', ...
        'Simulink is required to generate the propulsion thermal model.');
end

rootDir = cfg.project.rootDir;
modelDir = fullfile(rootDir,'models','propulsion_thermal_sensitivity');
modelName = "propulsion_thermal_sensitivity";
modelFile = fullfile(modelDir,modelName+".slx");

if isfile(modelFile) && ~options.Overwrite
    error('EVThermal:ModelExists', ...
        ['Model already exists: %s\nUse Overwrite=true only when the ' ...
         'generated model should be replaced.'],modelFile);
end
if isfile(modelFile) && options.Overwrite
    delete(modelFile);
end
if bdIsLoaded(modelName)
    close_system(modelName,0);
end

new_system(modelName,'Model');
cleanup = onCleanup(@() close_if_loaded(modelName)); %#ok<NASGU>
load_system(modelName);

set_param(modelName, ...
    'SolverType','Variable-step', ...
    'Solver','ode45', ...
    'StartTime','0', ...
    'StopTime','600', ...
    'SaveOutput','on', ...
    'OutputSaveName','yout', ...
    'SaveFormat','Dataset');

p = cfg.motorCooling.transient;

add_inport(modelName,'Drive-unit heat kW',[30 65 60 79],1);
add_inport(modelName,'Ambient temperature C',[30 305 60 319],2);
add_inport(modelName,'Radiator UA W per K',[30 405 60 419],3);

add_block('simulink/Math Operations/Gain',modelName+"/Heat kW to W", ...
    'Gain','1000','Position',[100 50 190 95]);
add_block('simulink/Math Operations/Sum',modelName+"/Motor energy balance", ...
    'Inputs','+-','Position',[315 60 350 100]);
add_block('simulink/Math Operations/Gain',modelName+"/Inverse motor capacity", ...
    'Gain',number(1/p.motorThermalCapacity_JK), ...
    'Position',[395 55 515 105]);
add_block('simulink/Continuous/Integrator',modelName+"/Motor temperature", ...
    'InitialCondition',number(p.initialMotorTemperature_C), ...
    'Position',[565 55 595 105]);

add_block('simulink/Math Operations/Sum', ...
    modelName+"/Motor minus coolant",'Inputs','+-', ...
    'Position',[650 145 685 185]);
add_block('simulink/Math Operations/Gain', ...
    modelName+"/Motor-to-coolant conductance", ...
    'Gain',number(1/p.motorToCoolantResistance_KW), ...
    'Position',[730 140 880 190]);

add_block('simulink/Math Operations/Sum',modelName+"/Coolant energy balance", ...
    'Inputs','+-','Position',[315 225 350 265]);
add_block('simulink/Math Operations/Gain',modelName+"/Inverse coolant capacity", ...
    'Gain',number(1/p.coolantThermalCapacity_JK), ...
    'Position',[395 220 515 270]);
add_block('simulink/Continuous/Integrator',modelName+"/Coolant temperature", ...
    'InitialCondition',number(p.initialCoolantTemperature_C), ...
    'Position',[565 220 595 270]);

add_block('simulink/Math Operations/Sum', ...
    modelName+"/Coolant minus ambient",'Inputs','+-', ...
    'Position',[140 300 175 340]);
add_block('simulink/Math Operations/Product', ...
    modelName+"/Radiator heat transfer", ...
    'Position',[220 325 265 365]);
add_block('simulink/Discontinuities/Saturation', ...
    modelName+"/Nonnegative radiator rejection", ...
    'LowerLimit','0','UpperLimit','inf', ...
    'Position',[315 320 440 370]);

add_block('simulink/Math Operations/Gain',modelName+"/Motor heat W to kW", ...
    'Gain','0.001','Position',[920 140 1020 190]);
add_block('simulink/Math Operations/Gain',modelName+"/Radiator heat W to kW", ...
    'Gain','0.001','Position',[485 320 585 370]);

add_outport(modelName,'Motor temperature C',[700 45 730 59],1);
add_outport(modelName,'Coolant temperature C',[700 235 730 249],2);
add_outport(modelName,'Motor-to-coolant heat kW',[1070 158 1100 172],3);
add_outport(modelName,'Radiator rejection kW',[635 338 665 352],4);

add_line(modelName,'Drive-unit heat kW/1','Heat kW to W/1');
add_line(modelName,'Heat kW to W/1','Motor energy balance/1');
add_line(modelName,'Motor energy balance/1','Inverse motor capacity/1');
add_line(modelName,'Inverse motor capacity/1','Motor temperature/1');
add_line(modelName,'Motor temperature/1','Motor temperature C/1');
add_line(modelName,'Motor temperature/1','Motor minus coolant/1');
add_line(modelName,'Coolant temperature/1','Motor minus coolant/2');
add_line(modelName,'Motor minus coolant/1','Motor-to-coolant conductance/1');
add_line(modelName,'Motor-to-coolant conductance/1','Motor energy balance/2');
add_line(modelName,'Motor-to-coolant conductance/1','Coolant energy balance/1');
add_line(modelName,'Motor-to-coolant conductance/1','Motor heat W to kW/1');
add_line(modelName,'Motor heat W to kW/1','Motor-to-coolant heat kW/1');
add_line(modelName,'Coolant energy balance/1','Inverse coolant capacity/1');
add_line(modelName,'Inverse coolant capacity/1','Coolant temperature/1');
add_line(modelName,'Coolant temperature/1','Coolant temperature C/1');
add_line(modelName,'Coolant temperature/1','Coolant minus ambient/1');
add_line(modelName,'Ambient temperature C/1','Coolant minus ambient/2');
add_line(modelName,'Coolant minus ambient/1','Radiator heat transfer/1');
add_line(modelName,'Radiator UA W per K/1','Radiator heat transfer/2');
add_line(modelName,'Radiator heat transfer/1','Nonnegative radiator rejection/1');
add_line(modelName,'Nonnegative radiator rejection/1','Coolant energy balance/2');
add_line(modelName,'Nonnegative radiator rejection/1','Radiator heat W to kW/1');
add_line(modelName,'Radiator heat W to kW/1','Radiator rejection kW/1');

annotation = sprintf([ ...
    'UNCALIBRATED SENSITIVITY MODEL\n' ...
    'Motor capacity: %.0f J/K (assumed)\n' ...
    'Coolant capacity: %.0f J/K (assumed)\n' ...
    'Motor-to-coolant resistance: %.4f K/W (assumed)\n' ...
    'Radiator UA is an external scenario input, not a verified map.'], ...
    p.motorThermalCapacity_JK,p.coolantThermalCapacity_JK, ...
    p.motorToCoolantResistance_KW);
note = Simulink.Annotation(modelName,annotation);
note.Position = [30 500 630 600];

Simulink.BlockDiagram.arrangeSystem(modelName);
save_system(modelName,modelFile);
close_system(modelName,0);
end

function add_inport(modelName,name,position,portNumber)
add_block('simulink/Ports & Subsystems/In1',modelName+"/"+string(name), ...
    'Port',num2str(portNumber),'Position',position);
end

function add_outport(modelName,name,position,portNumber)
add_block('simulink/Ports & Subsystems/Out1',modelName+"/"+string(name), ...
    'Port',num2str(portNumber),'Position',position);
end

function value = number(value)
value = sprintf('%.15g',value);
end

function close_if_loaded(modelName)
if bdIsLoaded(modelName)
    close_system(modelName,0);
end
end
