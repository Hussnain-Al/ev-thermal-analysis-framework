function trace = simulate_motor_coolant_thermal(motorHeatTrace,ambient_C,p)
%SIMULATE_MOTOR_COOLANT_THERMAL Two-node winding/coolant energy balance.
% With MotorLoss_kW and ControllerLoss_kW in the trace, the motor loss heats
% the winding node and the controller loss goes straight to the coolant
% node; otherwise all of DriveUnitHeat_kW heats the winding node.

t = motorHeatTrace.Time_s;
n = numel(t);
if ismember('MotorLoss_kW',motorHeatTrace.Properties.VariableNames)
    windingHeat_kW = motorHeatTrace.MotorLoss_kW;
    coolantHeat_kW = motorHeatTrace.ControllerLoss_kW;
else
    windingHeat_kW = motorHeatTrace.DriveUnitHeat_kW;
    coolantHeat_kW = zeros(n,1);
end
motor_C = zeros(n,1);
coolant_C = zeros(n,1);
motorToCoolant_kW = zeros(n,1);
radiatorHeat_kW = zeros(n,1);
motor_C(1) = p.initialMotorTemperature_C;
coolant_C(1) = p.initialCoolantTemperature_C;

for k = 1:n
    motorToCoolant_kW(k) = ...
        (motor_C(k)-coolant_C(k))/p.motorToCoolantResistance_KW/1000;
    radiatorHeat_kW(k) = max( ...
        p.radiatorUA_WK*(coolant_C(k)-ambient_C)/1000,0);
    if k < n
        dt = t(k+1)-t(k);
        motor_C(k+1) = motor_C(k)+dt*1000* ...
            (windingHeat_kW(k)-motorToCoolant_kW(k))/ ...
            p.motorThermalCapacity_JK;
        coolant_C(k+1) = coolant_C(k)+dt*1000* ...
            (motorToCoolant_kW(k)+coolantHeat_kW(k)-radiatorHeat_kW(k))/ ...
            p.coolantThermalCapacity_JK;
    end
end

trace = table(motorHeatTrace.Cycle,t,motorHeatTrace.DriveUnitHeat_kW, ...
    motor_C,coolant_C,motorToCoolant_kW,radiatorHeat_kW, ...
    repmat(ambient_C,n,1), ...
    'VariableNames',{'Case','Time_s','DriveUnitHeat_kW', ...
    'MotorTemperature_C','CoolantTemperature_C', ...
    'MotorToCoolantHeat_kW','RadiatorHeatRejection_kW','Ambient_C'});
end
