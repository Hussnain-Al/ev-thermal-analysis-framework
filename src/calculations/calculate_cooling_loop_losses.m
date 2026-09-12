function [segmentResults, summary] = calculate_cooling_loop_losses(g, flow_Lmin, density_kgm3, viscosity_Pas)
%CALCULATE_COOLING_LOOP_LOSSES Darcy plus K-losses for known 20 mm hoses.
% Major loss: dp = f*(L/D)*(rho*v^2/2).
% Minor loss: dp = K*(rho*v^2/2).
% Unknown motor, controller, PDU and radiator losses are excluded.
% Driving inputs: volume flow, fluid properties and known hose geometry.
% Calculated responses: Reynolds number, friction factor and pressure loss.

% Convert flow and calculate Reynolds number for the common hose diameter.
flow_m3s = flow_Lmin/60000;
area_m2 = pi*g.hoseID_m^2/4;
velocity_ms = flow_m3s/area_m2;
Re = density_kgm3*velocity_ms*g.hoseID_m/viscosity_Pas;
f = darcy_friction_factor(Re, g.roughness_m/g.hoseID_m);
% Dynamic pressure is the common multiplier for straight-pipe and fitting loss.
dynamicPressure_Pa = density_kgm3*velocity_ms^2/2;
K_total = g.bends90*g.K90 + g.returns180*g.K180 + g.teesLine*g.KteeLine;
major_kPa = f*(g.length_m/g.hoseID_m)*dynamicPressure_Pa/1000;
minor_kPa = K_total*dynamicPressure_Pa/1000;
total_kPa = major_kPa + minor_kPa;

segmentResults = table(g.names, g.length_m, g.bends90, g.returns180, g.teesLine, ...
    K_total, major_kPa, minor_kPa, total_kPa, ...
    'VariableNames', {'Segment','Length_m','Bends90','Returns180','TeesLine', ...
    'K_total','MajorLoss_kPa','MinorLoss_kPa','HydraulicLoss_kPa'});

majorTotal_kPa = sum(major_kPa);
minorTotal_kPa = sum(minor_kPa);
hoseTotal_kPa = sum(total_kPa);
summary = table(flow_Lmin,velocity_ms,Re,f,majorTotal_kPa,minorTotal_kPa, ...
    hoseTotal_kPa, ...
    'VariableNames', {'Flow_Lmin','Velocity_ms','Reynolds','DarcyFrictionFactor', ...
    'HoseMajorLoss_kPa','FittingMinorLoss_kPa','HoseAndFittingLoss_kPa'});
end
