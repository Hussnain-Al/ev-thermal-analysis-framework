function [segmentResults, summary] = calculate_cooling_loop_losses(g, flow_Lmin, density_kgm3, viscosity_Pas)
%CALCULATE_COOLING_LOOP_LOSSES Darcy plus K-losses with evidence scenarios.
% Major loss: dp = f*(L/D)*(rho*v^2/2).
% Minor loss: dp = K*(rho*v^2/2).
% Known component losses are scaled from their reference flow using dp~Q^2.
% Driving inputs: volume flow, fluid properties, geometry and component data.
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
    g.isExternalHose, K_total, major_kPa, minor_kPa, total_kPa, ...
    'VariableNames', {'Segment','Length_m','Bends90','Returns180','TeesLine', ...
    'IsExternalHose','K_total','MajorLoss_kPa','MinorLoss_kPa','HydraulicLoss_kPa'});

scale = (flow_Lmin/g.referenceFlow_Lmin)^2;
knownComponent_kPa = scale*sum(g.componentDrop_kPa_atReference);
externalMajor_kPa = sum(major_kPa(g.isExternalHose));
externalMinor_kPa = sum(minor_kPa(g.isExternalHose));
external_kPa = sum(total_kPa(g.isExternalHose));
radiatorRoute_kPa = sum(total_kPa(~g.isExternalHose));
summary = table(flow_Lmin, velocity_ms, Re, f,externalMajor_kPa,externalMinor_kPa, ...
    external_kPa, radiatorRoute_kPa, ...
    knownComponent_kPa, external_kPa+knownComponent_kPa, ...
    external_kPa+radiatorRoute_kPa+knownComponent_kPa, ...
    'VariableNames', {'Flow_Lmin','Velocity_ms','Reynolds','DarcyFrictionFactor', ...
    'ExternalHoseMajorLoss_kPa','ExternalFittingMinorLoss_kPa', ...
    'ExternalHoseAndFittings_kPa','ReconstructedRadiatorRouting_kPa', ...
    'KnownComponentAllowance_kPa','EvidenceBackedPartialSubtotal_kPa', ...
    'IllustrativeSubtotalIncludingRadiatorRoute_kPa'});
end
