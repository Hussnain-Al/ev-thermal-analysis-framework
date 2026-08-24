function f = darcy_friction_factor(Re, relativeRoughness)
%DARCY_FRICTION_FACTOR Laminar, blended-transition or Colebrook Darcy factor.
% Laminar flow uses f=64/Re. Turbulent flow uses Colebrook. The uncertain
% transition interval is linearly blended to avoid a numerical discontinuity.

if Re <= 0
    error('Reynolds number must be positive.');
elseif Re < 2300
    f = 64/Re;
elseif Re > 4000
    f = colebrook_factor(Re, relativeRoughness);
else
    fLam = 64/2300;
    fTurb = colebrook_factor(4000, relativeRoughness);
    w = (Re-2300)/(4000-2300);
    f = (1-w)*fLam + w*fTurb;
end
end
