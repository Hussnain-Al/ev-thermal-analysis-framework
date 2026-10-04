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
disp(sys.cabinMassSensitivity);
disp(sys.controllerGains);

% Every cycle with the recommended compressor, and L6 with the DM18A1.
runs = [(1:numel(cfg.systemThermal.cycles))' repmat(numel(sys.capacity_kW),numel(cfg.systemThermal.cycles),1); ...
    find(cfg.systemThermal.cycles=="project_l6_continuous_grade") 1];
columns = ["Cabin_C","Cell_C","BatteryCoolant_C","DriveUnit_C","PropulsionCoolant_C", ...
    "SOC_pct","DerateFactor"];
outports = [1 2 3 6 7 9 10];
tolerance = [1 1 1 1 1 0.5 0.1];
for r = 1:size(runs,1)
    i = runs(r,1); j = runs(r,2);
    stem = cfg.systemThermal.cycles(i);
    modelFile = build_system_thermal_simscape(cfg,sys,CycleStem=stem, ...
        Capacity_kW=sys.capacity_kW(j),Overwrite=true);
    cleanupModel = onCleanup(@() remove_generated_model(modelFile)); %#ok<NASGU>
    [~,modelName] = fileparts(modelFile);
    load_system(modelFile);
    simOut = sim(modelName,'ReturnWorkspaceOutputs','on');
    y = simOut.yout;
    reference = sys.traces{i,j};
    for k = 1:numel(columns)
        values = y{outports(k)}.Values;
        simscape = interp1(values.Time,squeeze(values.Data),reference.Time_s);
        difference = max(abs(simscape-reference.(columns(k))));
        fprintf('Simscape vs MATLAB, %s, %.2f kW, %s: max difference %.3f, end %.3f vs %.3f\n', ...
            stem,sys.capacity_kW(j),columns(k),difference,simscape(end), ...
            reference.(columns(k))(end));
        assert(difference<tolerance(k),'EVThermal:SimscapeMismatch', ...
            'Simscape and MATLAB differ by %.3f on %s (%s).',difference,columns(k),stem);
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
