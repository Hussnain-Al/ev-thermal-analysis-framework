function run_system_thermal_simscape_checks()
%RUN_SYSTEM_THERMAL_SIMSCAPE_CHECKS Build, simulate and cross-check the Simscape model.
% The Simscape network must reproduce the MATLAB system model
% (simulate_system_thermal) on the L6 cycle for both compressor sizes.

if isempty(ver('simulink')) || isempty(ver('simscape'))
    error('EVThermal:SimscapeRequired', ...
        'Simulink and Simscape are required for the system thermal check.');
end
rootDir = fileparts(fileparts(mfilename('fullpath')));
startingFolder = pwd;
cleanupFolder = onCleanup(@() cd(startingFolder)); %#ok<NASGU>
cd(rootDir);
cfg = setup_project();
results = run_all(cfg);
sys = results.systemThermal;
disp(sys.summary);
disp(sys.frontEnd);

stem = "project_l6_continuous_grade";
i = find(cfg.systemThermal.cycles==stem,1);
for j = 1:numel(sys.capacity_kW)
    modelFile = build_system_thermal_simscape(cfg,sys,CycleStem=stem, ...
        Capacity_kW=sys.capacity_kW(j),Overwrite=true);
    cleanupModel = onCleanup(@() remove_generated_model(modelFile)); %#ok<NASGU>
    [~,modelName] = fileparts(modelFile);
    load_system(modelFile);
    simOut = sim(modelName,'ReturnWorkspaceOutputs','on');
    y = simOut.yout;
    reference = sys.traces{i,j};
    columns = ["Cabin_C","Cell_C","BatteryCoolant_C"];
    for k = 1:numel(columns)
        values = y{k}.Values;
        simscape_C = interp1(values.Time,squeeze(values.Data),reference.Time_s);
        difference = max(abs(simscape_C-reference.(columns(k))));
        fprintf('Simscape vs MATLAB, %s, %.2f kW, %s: max difference %.3f K, end %.3f vs %.3f C\n', ...
            stem,sys.capacity_kW(j),columns(k),difference,simscape_C(end), ...
            reference.(columns(k))(end));
        assert(difference<1.0,'EVThermal:SimscapeMismatch', ...
            'Simscape and MATLAB differ by %.3f K on %s.',difference,columns(k));
    end
    close_system(modelName,0);
    clear cleanupModel
end
fprintf('System thermal Simscape model built, simulated and matched the MATLAB model.\n');
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
