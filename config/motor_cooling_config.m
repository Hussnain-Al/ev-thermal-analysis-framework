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
% Supplier component pressure drops (motor cooling.doc): MCU and motor
% tested at 16 L/min, PDU/OBC/DCDC water-resistance curve.
motorCooling.files.componentPressureDrop = fullfile(rootDir,"data", ...
    "motor_cooling","component_pressure_drop.csv");

% Selected coolant: LubeMax Antifreeze/Coolant 50/50 (ethylene glycol,
% 50% v/v, ASTM D3306). The datasheet gives limits but no thermophysical
% table, so the property rows below remain 50% ethylene-glycol screening
% values; replace them with a supplier table when one is available.
motorCooling.coolantProduct = "LubeMax Antifreeze/Coolant 50/50";
motorCooling.coolantBoilingPoint_C = 107;           % ASTM D1120, unpressurized
motorCooling.coolantBoilingPointCapped_C = 129.4;   % with a 15 psi cap
motorCooling.coolantFreezePoint_C = -36.7;          % ASTM D1177
motorCooling.coolant = table([20;40;60],[1065;1055;1040], ...
    [4.50e-3;2.50e-3;1.50e-3],[3400;3500;3600], ...
    'VariableNames',{'Temperature_C','Density_kgm3','Viscosity_Pas','Cp_JkgK'});

thermal.designFlow_Lmin = 20;
thermal.hoseID_m = 0.020;
thermal.propertyTemperature_C = 60;
thermal.radiatorCoolantIn_C = 65;
thermal.airIn_C = 45;
thermal.airOut_C = 55;
thermal.airTemperatureRiseSensitivity_C = (5:1:15)';
thermal.airCp_JkgK = 1005;
thermal.ambientPressure_Pa = 101325;
thermal.airGasConstant_JkgK = 287.05;
motorCooling.thermal = thermal;

% Two-node transient calibration assumptions. They are exposed here because
% the archived source does not provide identified thermal capacitances or a
% measured motor-to-coolant resistance.
transient.driveUnitMass_kg = 83.5;
transient.outerCaseMaterial = "ADC12 aluminium";
% The complete three-in-one unit is not solid ADC12. Preserve the prior
% 45 kJ/K sensitivity value through an explicit effective specific heat.
transient.assumedEffectiveSpecificHeat_JkgK = 45000/83.5;
transient.motorThermalCapacity_JK = transient.driveUnitMass_kg* ...
    transient.assumedEffectiveSpecificHeat_JkgK;
transient.coolantThermalCapacity_JK = 17500;
% Winding-to-coolant resistance and radiator UA are derived in
% apply_literature_corrections. The values below are superseded and kept
% only for comparison (docs/CORRECTIONS.md).
transient.superseded.motorToCoolantResistance_KW = 0.015;
transient.superseded.radiatorUA_WK = 665;
transient.superseded.fanOnlyRadiatorUA_WK = 300;
transient.initialMotorTemperature_C = 45;
transient.initialCoolantTemperature_C = 45;
transient.designAmbient_C = 45;
transient.modelBoundary = ...
    "Two-node lumped screen with uncalibrated thermal capacitance, resistance and normal/fan-only radiator UA";
motorCooling.transient = transient;

loop.names = ["Hose 1";"Hose 2";"Hose 3";"Hose 4";"Hose 5";"Hose 6"];
loop.length_m = [1.02385;0.35000;1.55540;0.43617;0.29800;0.73536];
loop.bends90 = [4;2;5;1;3;4];
loop.returns180 = zeros(6,1);
loop.teesLine = [1;1;0;1;0;0];
loop.hoseID_m = thermal.hoseID_m;
loop.roughness_m = 0.010e-3;
loop.K90 = 1.5;
loop.K180 = 1.5;
loop.KteeLine = 0.9;
loop.referenceFlow_Lmin = 16;
loop.flowCases_Lmin = (8:2:20)';
loop.nominalTemperature_C = 40;
loop.nominalFlow_Lmin = 16;
motorCooling.loop = loop;

motorCooling.pump.referenceFlow_Lmin = 20;
motorCooling.pump.minimumHead_kPa = 60;
motorCooling.pump.checkTemperature_C = 60;
% Flow grid used to find the flow at which the loop loss reaches the pump's
% documented minimum head (the full pump curve is not available).
motorCooling.pump.flowSearch_Lmin = (4:0.05:30)';
end
