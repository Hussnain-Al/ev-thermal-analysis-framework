function results = verify_framework()
%VERIFY_FRAMEWORK Run the complete analysis and all regression checks.
% Run this function from any folder after extracting the complete package.

rootDir = fileparts(mfilename('fullpath'));
startingFolder = pwd;
cleanup = onCleanup(@() cd(startingFolder)); %#ok<NASGU>
cd(rootDir);
rehash;

results = run_all();
run(fullfile(rootDir,'tests','run_sanity_checks.m'));
fprintf('EV Thermal Analysis Framework v%s verification completed.\n', ...
    results.config.project.version);
end
