function run_battery_requirements_simulink_checks()
%RUN_BATTERY_REQUIREMENTS_SIMULINK_CHECKS Generate and compile the screen.

if isempty(ver('simulink'))
    error('EVThermal:SimulinkRequired', ...
        'Simulink is required for the battery requirements screen check.');
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
startingFolder = pwd;
cleanupFolder = onCleanup(@() cd(startingFolder)); %#ok<NASGU>
cd(rootDir);
cfg = setup_project();

modelFile = build_battery_requirements_simulink(cfg,Overwrite=true);
cleanupModel = onCleanup(@() remove_generated_model(modelFile)); %#ok<NASGU>
[~,modelName] = fileparts(modelFile);
load_system(modelFile);

set_param(modelName,'SimulationCommand','update');
outports = find_system(modelName,'SearchDepth',1,'BlockType','Outport');
assert(numel(outports)==6);
assert(~isempty(find_system(modelName,'SearchDepth',1, ...
    'Name','Calculate cell ACR heat floor')));
assert(~isempty(find_system(modelName,'SearchDepth',1, ...
    'Name','Calculate required temperature difference')));

close_system(modelName,0);
fprintf('Battery requirements Simulink model generated and compiled successfully.\n');
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
