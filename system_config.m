function cfg = system_config(rootDir)
%SYSTEM_CONFIG User-editable inputs for the EV thermal analysis framework.
%
% Edit this file and the CSV/XLSX files in data/ when evaluating a different
% vehicle or component set. Calculation functions in src/ do not contain
% component ratings or vehicle-specific constants.

arguments
    rootDir (1,1) string = string(fileparts(mfilename('fullpath')))
end

%% Project and files
cfg.project.name = "EV Thermal Analysis Framework";
cfg.project.version = "2.0.5";
cfg.project.outputDir = fullfile(rootDir,"outputs");

cfg.files.driveLimitWorkbook = fullfile(rootDir,"data","components","drive_unit_limits.xlsx");
cfg.files.driveEfficiencyMap = fullfile(rootDir,"data","components","drive_unit_efficiency_map.csv");
cfg.files.compressorMap = fullfile(rootDir,"data","components","compressor_performance_map.csv");
cfg.files.inactivePumpCurve = fullfile(rootDir,"data","components","inactive_pump_resistance_curve.csv");
cfg.files.driveThermalReference = fullfile(rootDir,"data","components","drive_unit_thermal_reference.csv");
cfg.files.heatExchangerGeometry = fullfile(rootDir,"data","components","heat_exchanger_geometry.csv");
cfg.files.vehicleLoadCases = fullfile(rootDir,"data","cases","vehicle_load_cases.csv");
cfg.files.cabinLoadInputs = fullfile(rootDir,"data","cases","cabin_load_inputs.csv");
cfg.files.parameterRegister = fullfile(rootDir,"data","sample_parameter_register.csv");

cfg.cycles = table( ...
    ["Urban stop-start";"Highway"], ...
    ["urban_cycle";"highway_cycle"], ...
    [string(fullfile(rootDir,"data","cycles","urban_cycle.txt")); ...
     string(fullfile(rootDir,"data","cycles","highway_cycle.txt"))], ...
    'VariableNames',{'Name','FileStem','File'});

%% Vehicle model
cfg.vehicle.mass_kg = 1950;
cfg.vehicle.gravity_ms2 = 9.81;
cfg.vehicle.wheelDiameter_m = 0.724;
cfg.vehicle.wheelRadius_m = cfg.vehicle.wheelDiameter_m/2;
cfg.vehicle.gearRatio = 9.11;

% Flat-road force model: Froad = A + B*v^2.
% Replace these coefficients with coast-down data when available.
cfg.vehicle.roadLoadA_N = 566.4645;
cfg.vehicle.roadLoadB_N_per_ms2 = 0.4185918;
cfg.vehicle.grade_pct = 0;
cfg.vehicle.regenEnabled = true;

%% Battery model
cfg.battery.capacity_Ah = 134;
cfg.battery.nominalVoltage_V = 3.2;
cfg.battery.seriesCells = 108;
cfg.battery.cellsPerRow = 9;
cfg.battery.cellsPerModule = 18;
cfg.battery.modules = 6;
cfg.battery.resistanceProxy_Ohm = 0.40e-3;
cfg.battery.resistanceCases_Ohm = [0.30 0.40 0.60]*1e-3;
cfg.battery.cRates = [0.1 0.3 0.5 0.75 1 1.25 1.5 1.75 2];
cfg.battery.sideResistance_KW_each = 16.67;
cfg.battery.baseResistance_KW = 3.10;
cfg.battery.cellMass_kg = 2.420;
cfg.battery.cellCp_JkgK = 900;
cfg.battery.coolingOn_C = 35;
cfg.battery.coolingOff_C = 32;
cfg.battery.maximumCell_C = 60;
cfg.battery.initialCellTemperature_C = 45;
cfg.battery.coolantTemperature_C = 30;
cfg.vehicle.packNominalVoltage_V = ...
    cfg.battery.seriesCells*cfg.battery.nominalVoltage_V;

%% Coolant properties
% Replace with the selected coolant datasheet when available.
cfg.coolant = table([20;40;60],[1065;1055;1040], ...
    [4.50e-3;2.50e-3;1.50e-3],[3400;3500;3600], ...
    'VariableNames',{'Temperature_C','Density_kgm3','Viscosity_Pas','Cp_JkgK'});

%% Propulsion coolant and radiator model
cfg.propulsionCooling.designFlow_Lmin = 20;
cfg.propulsionCooling.hoseID_m = 0.020;
cfg.propulsionCooling.propertyTemperature_C = 40;
% Hot coolant leaving the drive unit is the radiator inlet. The radiator
% outlet is calculated from the same heat duty and coolant mass flow; it is
% not an independent boundary condition.
cfg.propulsionCooling.radiatorCoolantIn_C = 65;
cfg.propulsionCooling.airIn_C = 45;
cfg.propulsionCooling.airOut_C = 55;
cfg.propulsionCooling.airCp_JkgK = 1005;

%% Cooling-loop geometry and component losses
loop.names = ["Hose 1";"Hose 2";"Hose 3";"Hose 4";"Hose 5";"Hose 6";"Heat-exchanger route"];
loop.length_m = [1.02385;0.35000;1.55540;0.43617;0.29800;0.73536;4.64000];
loop.bends90 = [4;2;5;1;3;4;2];
loop.returns180 = [0;0;0;0;0;0;16];
loop.teesLine = [1;1;0;1;0;0;0];
loop.isExternalHose = [true;true;true;true;true;true;false];
loop.hoseID_m = cfg.propulsionCooling.hoseID_m;
loop.roughness_m = 0.010e-3;
loop.K90 = 1.5;
loop.K180 = 1.5;
loop.KteeLine = 0.9;
loop.referenceFlow_Lmin = 16;
loop.flowCases_Lmin = (8:2:20)';
loop.nominalTemperature_C = 40;
loop.nominalFlow_Lmin = 16;
loop.componentNames = ["Power electronics";"Drive unit";"Auxiliary heat exchanger"];
loop.componentDrop_kPa_atReference = [13.0;11.0;7.6];
cfg.coolingLoop = loop;
cfg.pump.referenceFlow_Lmin = 20;
cfg.pump.minimumHead_kPa = 60;
% Use the coolant-property row nearest normal hot-loop operation for the
% pump screening check. Keep colder rows as sensitivity cases only.
cfg.pump.checkTemperature_C = 60;

%% Cabin and refrigerant system
cfg.hvac.recoveredCabinDuty_kW = 4.156;
cfg.hvac.compressorMapSpeed_rpm = 6000;
cfg.hvac.compressorMapEvaporator_C = 4;
cfg.hvac.allocationPriority = "battery";

% Candidate values are sample screening points. Replace each row with a
% candidate evaluated at comparable refrigerant boundary conditions.
cfg.hvac.compressorCandidates = table( ...
    ["Candidate A";"Candidate B"],[18;27],[3.63;4.60],[1.50;2.30], ...
    [6000;6000],[312;312], ...
    ["Map point at 4 C evaporation";"Larger candidate screening point"], ...
    'VariableNames',{'Model','Displacement_cc','CoolingCapacity_kW', ...
    'InputPower_kW','Speed_rpm','Voltage_V','EvidenceCondition'});
end
