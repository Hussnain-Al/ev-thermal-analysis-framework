function result = calculate_motor_operating_trace(cycle,vehicle,curves)
%CALCULATE_MOTOR_OPERATING_TRACE Drive-cycle operating points and drive heat.
% This function owns only the vehicle-to-integrated-drive calculation. It
% returns DC-link power for downstream battery analysis but contains no
% battery thermal parameters and no cooling-system calculation.

t = cycle.Time_s;
v = cycle.Speed_ms;
a = gradient(v,t);
wheelOmega = v/vehicle.wheelRadius_m;
motorOmega = wheelOmega*vehicle.gearRatio;
motorRPM = motorOmega*60/(2*pi);

roadForce_N = vehicle.roadLoadA_N + vehicle.roadLoadB_N_per_ms2.*v.^2;
inertiaForce_N = vehicle.mass_kg.*a;
gradeForce_N = vehicle.mass_kg*vehicle.gravity_ms2* ...
    sin(atan(vehicle.grade_pct/100));
requestedWheelForce_N = roadForce_N + inertiaForce_N + gradeForce_N;
requestedWheelPower_kW = requestedWheelForce_N.*v/1000;

% Motor shaft power: the reducer loss is added when motoring and taken off
% when regenerating.
etaReducer = vehicle.reducerEfficiency;
shaftPower_kW = requestedWheelPower_kW/etaReducer;
regenerating = requestedWheelPower_kW < 0;
shaftPower_kW(regenerating) = requestedWheelPower_kW(regenerating)*etaReducer;
reducerLoss_kW = abs(shaftPower_kW-requestedWheelPower_kW);

requestedMotorTorque_Nm = zeros(size(t));
moving = motorOmega > 1e-6;
requestedMotorTorque_Nm(moving) = ...
    shaftPower_kW(moving)*1000./motorOmega(moving);

maxTorque_Nm = interp1(curves.torqueRPM,curves.maxTorque_Nm, ...
    motorRPM,'linear','extrap');
maxPower_kW = interp1(curves.powerRPM,curves.maxPower_kW, ...
    motorRPM,'linear','extrap');
maxTorque_Nm = max(maxTorque_Nm,0);
maxPower_kW = max(maxPower_kW,0);
belowFirstPowerPoint = motorRPM < min(curves.powerRPM);
maxPower_kW(belowFirstPowerPoint) = ...
    maxTorque_Nm(belowFirstPowerPoint).*motorOmega(belowFirstPowerPoint)/1000;
torqueWithinCurve = abs(requestedMotorTorque_Nm) <= maxTorque_Nm + 1e-6;
powerWithinCurve = abs(shaftPower_kW) <= maxPower_kW + 1e-6;

eta = estimate_integrated_drive_efficiency( ...
    motorRPM,requestedMotorTorque_Nm,curves);
eta(~moving) = 1;

dcLinkPower_kW = zeros(size(t));
driveHeat_kW = zeros(size(t));
motoring = requestedWheelPower_kW >= 0;
dcLinkPower_kW(motoring) = shaftPower_kW(motoring)./eta(motoring);
driveHeat_kW(motoring) = ...
    dcLinkPower_kW(motoring)-shaftPower_kW(motoring);

regen = regenerating & vehicle.regenEnabled;
dcLinkPower_kW(regen) = shaftPower_kW(regen).*eta(regen);
driveHeat_kW(regen) = abs(shaftPower_kW(regen)).*(1-eta(regen));
reducerLoss_kW(regenerating & ~vehicle.regenEnabled) = 0;

result = cycle;
result.Acceleration_ms2 = a;
result.MotorSpeed_rpm = motorRPM;
result.RoadForce_N = roadForce_N;
result.InertiaForce_N = inertiaForce_N;
result.GradeForce_N = repmat(gradeForce_N,numel(t),1);
result.RequestedWheelPower_kW = requestedWheelPower_kW;
result.MotorShaftPower_kW = shaftPower_kW;
result.ReducerLoss_kW = reducerLoss_kW;
result.RequestedMotorTorque_Nm = requestedMotorTorque_Nm;
result.AvailableTorque_Nm = maxTorque_Nm;
result.AvailablePower_kW = maxPower_kW;
result.IntegratedEfficiency_pct = 100*eta;
% Split the motor-system loss: the controller (inverter) loss follows the
% supplier's controller figure against output power (through the origin,
% so the motor keeps the larger share at light load) and is rejected
% through its own cold plate to the coolant; the rest is motor loss,
% which heats the winding.
controllerLoss_kW = zeros(size(t));
if isfield(curves,'controllerPower_kW')
    controllerLoss_kW = interp1(curves.controllerPower_kW,curves.controllerLoss_kW, ...
        abs(shaftPower_kW),'linear','extrap');
    controllerLoss_kW = min(max(controllerLoss_kW,0),driveHeat_kW);
end
result.DCLinkPower_kW = dcLinkPower_kW;
result.DriveUnitHeat_kW = driveHeat_kW;
result.MotorLoss_kW = driveHeat_kW-controllerLoss_kW;
result.ControllerLoss_kW = controllerLoss_kW;
result.TorqueWithinCurve = torqueWithinCurve;
result.PowerWithinCurve = powerWithinCurve;
end
