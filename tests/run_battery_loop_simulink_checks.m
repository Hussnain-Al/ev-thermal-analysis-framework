function run_battery_loop_simulink_checks()
%RUN_BATTERY_LOOP_SIMULINK_CHECKS Generate and compile the standalone model.

if isempty(ver('simulink'))
    error('EVThermal:SimulinkRequired', ...
        'Simulink is required for the battery-loop model check.');
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
startingFolder = pwd;
cleanupFolder = onCleanup(@() cd(startingFolder)); %#ok<NASGU>
cd(rootDir);
cfg = setup_project();

modelFile = build_battery_loop_simulink(cfg,Overwrite=true);
cleanupModel = onCleanup(@() remove_generated_model(modelFile)); %#ok<NASGU>
[~,modelName] = fileparts(modelFile);
load_system(modelFile);

set_param(modelName,'SimulationCommand','update');
outports = find_system(modelName,'SearchDepth',1,'BlockType','Outport');
assert(numel(outports)==6);
assert(~isempty(find_system(modelName,'SearchDepth',1, ...
    'Name','ACR heat floor per cell')));
assert(~isempty(find_system(modelName,'SearchDepth',1, ...
    'Name','Cell-to-coolant rise requirement')));

close_system(modelName,0);
fprintf('Battery-loop Simulink model generated and compiled successfully.\n');
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
