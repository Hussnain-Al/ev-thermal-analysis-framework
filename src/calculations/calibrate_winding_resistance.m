function result = calibrate_winding_resistance(curves,ratedSpeed_rpm,ratedPower_kW, ...
    controllerLoss_kW,windingRise_C)
%CALIBRATE_WINDING_RESISTANCE Resistance implied by the supplier rated-rise point.
% The supplier reports the winding temperature at rated output with a stated
% coolant inlet. At steady state the motor-side loss crosses the winding-to-
% coolant resistance, so R = rise / (integrated loss - controller loss). The
% integrated loss comes from the supplied efficiency surface at the rated
% power and the assumed rated speed.

speed = ratedSpeed_rpm(:);
torque = ratedPower_kW*1000./(speed*2*pi/60);
eta = estimate_integrated_drive_efficiency(speed,torque,curves);
integratedLoss_kW = ratedPower_kW./eta-ratedPower_kW;
motorLoss_kW = integratedLoss_kW-controllerLoss_kW;
if any(motorLoss_kW<=0)
    error('EVThermal:InvalidWindingCalibration', ...
        'Controller loss exceeds the integrated loss at the rated point.');
end
result = table(speed,torque,100*eta,integratedLoss_kW,motorLoss_kW, ...
    windingRise_C./(motorLoss_kW*1000), ...
    'VariableNames',{'AssumedRatedSpeed_rpm','RatedTorque_Nm', ...
    'IntegratedEfficiency_pct','IntegratedLoss_kW','MotorAndReducerLoss_kW', ...
    'ImpliedWindingToCoolant_KW'});
end
