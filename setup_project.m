function cfg = setup_project(cfg)
%SETUP_PROJECT Add framework folders to the MATLAB path and validate inputs.
%   cfg = SETUP_PROJECT() loads system_config.m from the project root.
%   cfg = SETUP_PROJECT(cfg) validates a caller-supplied configuration.

rootDir = fileparts(mfilename('fullpath'));
configFile = fullfile(rootDir,'system_config.m');
if ~isfile(configFile)
    error('EVThermal:MissingConfiguration', ...
        'Required configuration file not found: %s',configFile);
end

addpath(fullfile(rootDir,'src','calculations'),'-begin');
addpath(fullfile(rootDir,'src','io'),'-begin');
addpath(fullfile(rootDir,'src','validation'),'-begin');
addpath(fullfile(rootDir,'examples'),'-begin');
rehash;

if nargin < 1
    % The configuration is intentionally kept beside run_all.m so a clean
    % MATLAB Online session can resolve it without subfolder path setup.
    cfg = system_config(string(rootDir));
end
validate_system_config(cfg);
end
