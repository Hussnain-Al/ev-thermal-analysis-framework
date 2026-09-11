function motorCooling = motor_cooling_config(rootDir)
%MOTOR_COOLING_CONFIG Propulsion coolant, radiator, hydraulic and pump inputs.

arguments
    rootDir (1,1) string
end

motorCooling.files.inactivePumpCurve = fullfile(rootDir,"data", ...
    "motor_cooling","inactive_pump_resistance_curve.csv");
motorCooling.files.thermalReference = fullfile(rootDir,"data", ...
    "motor_cooling","drive_unit_thermal_reference.csv");
motorCooling.files.radiatorGeometry = fullfile(rootDir,"data", ...
    "motor_cooling","propulsion_radiator_geometry.csv");

% 50/50 water-glycol screening properties. Replace with the selected
% coolant supplier's temperature-dependent properties before validation.
motorCooling.coolant = table([20;40;60],[1065;1055;1040], ...
    [4.50e-3;2.50e-3;1.50e-3],[3400;3500;3600], ...
    'VariableNames',{'Temperature_C','Density_kgm3','Viscosity_Pas','Cp_JkgK'});

thermal.designFlow_Lmin = 20;
thermal.hoseID_m = 0.020;
thermal.propertyTemperature_C = 40;
thermal.radiatorCoolantIn_C = 65;
thermal.airIn_C = 45;
thermal.airOut_C = 55;
thermal.airCp_JkgK = 1005;
motorCooling.thermal = thermal;

loop.names = ["Hose 1";"Hose 2";"Hose 3";"Hose 4";"Hose 5";"Hose 6"; ...
    "Heat-exchanger route"];
loop.length_m = [1.02385;0.35000;1.55540;0.43617;0.29800;0.73536;4.64000];
loop.bends90 = [4;2;5;1;3;4;2];
loop.returns180 = [0;0;0;0;0;0;16];
loop.teesLine = [1;1;0;1;0;0;0];
loop.isExternalHose = [true;true;true;true;true;true;false];
loop.hoseID_m = thermal.hoseID_m;
loop.roughness_m = 0.010e-3;
loop.K90 = 1.5;
loop.K180 = 1.5;
loop.KteeLine = 0.9;
loop.referenceFlow_Lmin = 16;
loop.flowCases_Lmin = (8:2:20)';
loop.nominalTemperature_C = 40;
loop.nominalFlow_Lmin = 16;
loop.componentNames = ["Power electronics";"Drive unit"; ...
    "Auxiliary heat exchanger"];
loop.componentDrop_kPa_atReference = [13.0;11.0;7.6];
motorCooling.loop = loop;

motorCooling.pump.referenceFlow_Lmin = 20;
motorCooling.pump.minimumHead_kPa = 60;
motorCooling.pump.checkTemperature_C = 60;
end
