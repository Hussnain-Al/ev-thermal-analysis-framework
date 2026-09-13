function run_propulsion_thermal_simulink_checks()
%RUN_PROPULSION_THERMAL_SIMULINK_CHECKS Generate and compile the model.

if isempty(ver('simulink'))
    error('EVThermal:SimulinkRequired', ...
        'Simulink is required for the propulsion thermal model check.');
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
startingFolder = pwd;
cleanupFolder = onCleanup(@() cd(startingFolder)); %#ok<NASGU>
cd(rootDir);
cfg = setup_project();

modelFile = build_propulsion_thermal_sensitivity_simulink( ...
    cfg,Overwrite=true);
cleanupModel = onCleanup(@() remove_generated_model(modelFile)); %#ok<NASGU>
[~,modelName] = fileparts(modelFile);
load_system(modelFile);

set_param(modelName,'SimulationCommand','update');
inports = find_system(modelName,'SearchDepth',1,'BlockType','Inport');
outports = find_system(modelName,'SearchDepth',1,'BlockType','Outport');
assert(numel(inports)==3);
assert(numel(outports)==4);

p = cfg.motorCooling.transient;
assert(abs(str2double(get_param(modelName+"/Inverse motor capacity", ...
    'Gain'))-1/p.motorThermalCapacity_JK)<1e-15);
assert(abs(str2double(get_param(modelName+"/Inverse coolant capacity", ...
    'Gain'))-1/p.coolantThermalCapacity_JK)<1e-15);
assert(abs(str2double(get_param(modelName+"/Motor-to-coolant conductance", ...
    'Gain'))-1/p.motorToCoolantResistance_KW)<1e-12);

diagramDir = fullfile(rootDir,'outputs','simulink');
if ~isfolder(diagramDir)
    mkdir(diagramDir);
end
diagramFile = fullfile(diagramDir, ...
    'propulsion_thermal_sensitivity.png');
print(['-s' char(modelName)],'-dpng','-r180',diagramFile);
assert(isfile(diagramFile));

close_system(modelName,0);
fprintf(['Propulsion thermal Simulink model generated, compiled and ' ...
    'exported successfully.\n']);
end

function remove_generated_model(modelFile)
[~,modelName] = fileparts(modelFile);
if bdIsLoaded(modelName)
    close_system(modelName,0);
end
if isfile(modelFile)
    delete(modelFile);
end
end
