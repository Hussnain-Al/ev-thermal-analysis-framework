function results = calculate_coolant_transport(heat_kW, flow_Lmin, hoseID_m, density_kgm3, cp_JkgK)
%CALCULATE_COOLANT_TRANSPORT Velocity, mass flow and bulk temperature rise.
% Uses Qdot = m_dot*cp*dT with m_dot = density*volume flow. The result is a
% bulk coolant rise and does not predict local wall or winding temperature.

% Convert L/min to m^3/s and calculate mean hose velocity.
flow_m3s = flow_Lmin / 60000;
area_m2 = pi * hoseID_m^2 / 4;
velocity_ms = flow_m3s / area_m2;
massFlow_kgs = density_kgm3 * flow_m3s;
% Rearrange the steady-flow energy balance to dT = Qdot/(m_dot*cp).
rise_C = heat_kW(:) * 1000 / (massFlow_kgs * cp_JkgK);
results = table(repmat(flow_Lmin,numel(heat_kW),1), repmat(velocity_ms,numel(heat_kW),1), ...
    repmat(massFlow_kgs,numel(heat_kW),1), rise_C, ...
    'VariableNames', {'CoolantFlow_Lmin','HoseVelocity_ms','CoolantMassFlow_kgs','CoolantRise_C'});
end
