function [components,surfaces] = calculate_cabin_heat_balance( ...
    outdoor_C,outdoorRH_pct,indoor_C,indoorRH_pct,cabinCfg,a)
%CALCULATE_CABIN_HEAT_BALANCE Steady cabin load by heat-balance components.
% Structure follows Fayazbakhsh and Bahrami (SAE 2013-01-1507): sol-air
% conduction through opaque panels, glazing conduction, transmitted and
% absorbed solar, floor, occupants, fresh air and internal gains. Surface
% areas and U-values come from the recovered workbook. Solar irradiance uses
% the ASHRAE clear-sky model for 21 June at the configured solar hour.

% name, area m2, U W/(m2 K), glazing, outward azimuth from north, tilt from horizontal
names = ["East side panel";"East side windows";"East doors"; ...
    "West side panel";"West side windows";"West doors";"Rear body"; ...
    "Rear window";"Front body";"Windshield";"Roof";"Floor"];
area = [1.12;0.73;1.70;1.12;0.73;1.70;0.70;0.60;2.33;1.34;2.00;6.38];
U = [2.801;2.569;4.89;2.801;2.569;4.89;2.667;2.611;2.667;5.02;0.532;2.267];
glazing = [false;true;false;false;true;false;false;true;false;true;false;false];
azimuth_deg = [90;90;90;270;270;270;180;180;0;0;0;0];
tilt_deg = [90;90;90;90;90;90;90;60;90;35;0;180];

lat = deg2rad(cabinCfg.latitude_deg);
decl = deg2rad(cabinCfg.declination_deg);
hourAngle = deg2rad(15*(cabinCfg.solarHour-12));
sinAlt = sin(lat)*sin(decl)+cos(lat)*cos(decl)*cos(hourAngle);
alt = asin(sinAlt);
cosAz = (sin(decl)-sinAlt*sin(lat))/(cos(alt)*cos(lat));
sunAz = acos(min(max(cosAz,-1),1));
if hourAngle > 0
    sunAz = 2*pi-sunAz;
end
directNormal = 1088*exp(-0.205/sinAlt)*a.C10;
diffuseHorizontal = 0.134*directNormal;
groundReflectance = 0.2;

tilt = deg2rad(tilt_deg);
surfaceAz = deg2rad(azimuth_deg);
cosIncidence = cos(alt)*cos(sunAz-surfaceAz).*sin(tilt)+sinAlt*cos(tilt);
incident = directNormal*max(cosIncidence,0)+diffuseHorizontal*(1+cos(tilt))/2+ ...
    groundReflectance*(directNormal*sinAlt+diffuseHorizontal)*(1-cos(tilt))/2;
incident(tilt_deg>=180) = 0;

isFloor = names=="Floor";
isWindshield = names=="Windshield";
transmittance = repmat(a.C15,numel(names),1);
transmittance(isWindshield) = a.C14;
solAir_C = outdoor_C+a.C12*incident/a.C11;

opaque_W = U.*area.*(solAir_C-indoor_C).*(~glazing & ~isFloor);
glazingConduction_W = U.*area*(outdoor_C-indoor_C).*glazing;
solar_W = area.*incident.*(transmittance+a.C16*a.C17).*glazing;
floor_W = U.*area*(a.C13-indoor_C).*isFloor;
surfaces = table(names,area,U,glazing,incident,opaque_W+floor_W, ...
    glazingConduction_W,solar_W, ...
    'VariableNames',{'Surface','Area_m2','U_Wm2K','Glazing', ...
    'IncidentSolar_Wm2','OpaqueOrFloorConduction_W', ...
    'GlazingConduction_W','GlazingSolar_W'});

freshAir_kgs = a.C21*a.C18*1.2/1000;
wOut = humidity_ratio(outdoor_C,outdoorRH_pct);
wIn = humidity_ratio(indoor_C,indoorRH_pct);
component = ["Opaque conduction (sol-air)";"Glazing conduction"; ...
    "Transmitted solar";"Floor (road-side)";"Occupants sensible"; ...
    "Occupants latent";"Fresh-air sensible";"Fresh-air latent"; ...
    "Electronics and blower"];
load_kW = [sum(opaque_W);sum(glazingConduction_W);sum(solar_W); ...
    sum(floor_W);a.C18*a.C19;a.C18*a.C20; ...
    freshAir_kgs*1006*(outdoor_C-indoor_C); ...
    freshAir_kgs*2.45e6*max(wOut-wIn,0);a.C22]/1000;
components = table(component,load_kW,'VariableNames',{'Component','Load_kW'});
end

function w = humidity_ratio(T_C,rh_pct)
pv = rh_pct/100*610.94*exp(17.625*T_C/(T_C+243.04));
w = 0.622*pv/(101325-pv);
end
