function result = calculate_drive_cycle_thermal(cycle, vehicle, battery, curves)
%CALCULATE_DRIVE_CYCLE_THERMAL Transient wheel-to-battery energy balance.
% Mathematical sequence:
%   1. Convert vehicle speed to wheel and drive-unit speed.
%   2. Calculate road, inertial and grade forces at each time step.
%   3. Calculate wheel power and the corresponding drive-unit torque.
%   4. Interpolate the operating limits and integrated efficiency map.
%   5. Apply the motoring/regeneration energy balance to obtain heat loss.
%   6. Convert DC power to pack current and estimate battery I^2R heat.
% Driving inputs: cycle speed/time, grade, vehicle properties and maps.
% Calculated responses: force, power, torque, efficiency, heat and current.

% Step 1: kinematics. The fixed reduction ratio maps wheel speed to the
% drive-unit shaft. No separate gearbox loss is added when the efficiency
% map already represents the integrated motor, inverter and reducer.
t = cycle.Time_s;
v = cycle.Speed_ms;
a = gradient(v,t);
wheelOmega = v/vehicle.wheelRadius_m;
motorRPM = wheelOmega*60/(2*pi)*vehicle.gearRatio;

% Step 2: longitudinal force balance, Fwheel = Froad + m*a + Fgrade.
% Froad uses the configured coast-down form A + B*v^2.
roadForce_N = vehicle.roadLoadA_N + vehicle.roadLoadB_N_per_ms2.*v.^2;
inertiaForce_N = vehicle.mass_kg.*a;
gradeForce_N = vehicle.mass_kg*vehicle.gravity_ms2* ...
    sin(atan(vehicle.grade_pct/100));
requestedWheelForce_N = roadForce_N + inertiaForce_N + gradeForce_N;
requestedWheelPower_kW = requestedWheelForce_N.*v/1000;

% Step 3: shaft torque follows P = T*omega. Torque is set to zero at rest
% to avoid division by zero.
motorOmega = wheelOmega*vehicle.gearRatio;
requestedMotorTorque_Nm = zeros(size(t));
moving = motorOmega > 1e-6;
requestedMotorTorque_Nm(moving) = requestedWheelPower_kW(moving)*1000./motorOmega(moving);

% Step 4: confirm the requested point is inside the supplied torque-speed
% and power-speed envelopes. These flags identify infeasible cycle points.
maxTorque_Nm = interp1(curves.torqueRPM,curves.maxTorque_Nm,motorRPM,'linear','extrap');
maxPower_kW = interp1(curves.powerRPM,curves.maxPower_kW,motorRPM,'linear','extrap');
maxTorque_Nm = max(maxTorque_Nm,0);
maxPower_kW = max(maxPower_kW,0);
belowFirstPowerPoint = motorRPM < min(curves.powerRPM);
maxPower_kW(belowFirstPowerPoint) = ...
    maxTorque_Nm(belowFirstPowerPoint).*motorOmega(belowFirstPowerPoint)/1000;
torqueWithinCurve = abs(requestedMotorTorque_Nm) <= maxTorque_Nm + 1e-6;
powerWithinCurve = abs(requestedWheelPower_kW) <= maxPower_kW + 1e-6;

eta = estimate_integrated_drive_efficiency(motorRPM,requestedMotorTorque_Nm,curves);
eta(~moving) = 1;

% Step 5: energy balance. During motoring, Pdc = Pwheel/eta and loss is the
% difference. During regeneration, only eta*|Pwheel| returns to the pack;
% the remainder becomes drive-unit heat.
batteryPower_kW = zeros(size(t));
driveHeat_kW = zeros(size(t));
motoring = requestedWheelPower_kW >= 0;
batteryPower_kW(motoring) = requestedWheelPower_kW(motoring)./eta(motoring);
driveHeat_kW(motoring) = batteryPower_kW(motoring)-requestedWheelPower_kW(motoring);

regen = requestedWheelPower_kW < 0 & vehicle.regenEnabled;
batteryPower_kW(regen) = requestedWheelPower_kW(regen).*eta(regen);
driveHeat_kW(regen) = abs(requestedWheelPower_kW(regen)).*(1-eta(regen));

% Step 6: pack electrical screening. Series-connected cells carry the same
% current, so Qpack = Nseries*I^2*Rcell. The resistance is a configurable
% effective value and must match the intended temperature and state of charge.
packCurrent_A = batteryPower_kW*1000/vehicle.packNominalVoltage_V;
cellHeat_W = packCurrent_A.^2*battery.resistanceProxy_Ohm;
packHeat_kW = cellHeat_W*battery.seriesCells/1000;

result = cycle;
result.Acceleration_ms2 = a;
result.MotorSpeed_rpm = motorRPM;
result.RoadForce_N = roadForce_N;
result.InertiaForce_N = inertiaForce_N;
result.GradeForce_N = repmat(gradeForce_N,numel(t),1);
result.RequestedWheelPower_kW = requestedWheelPower_kW;
result.RequestedMotorTorque_Nm = requestedMotorTorque_Nm;
result.AvailableTorque_Nm = maxTorque_Nm;
result.AvailablePower_kW = maxPower_kW;
result.IntegratedEfficiency_pct = 100*eta;
result.BatteryPower_kW = batteryPower_kW;
result.PackCurrent_A = packCurrent_A;
result.DriveUnitHeat_kW = driveHeat_kW;
result.BatteryHeat_kW = packHeat_kW;
result.TorqueWithinCurve = torqueWithinCurve;
result.PowerWithinCurve = powerWithinCurve;
end
