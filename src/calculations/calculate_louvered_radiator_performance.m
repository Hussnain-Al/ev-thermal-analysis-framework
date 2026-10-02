function result = calculate_louvered_radiator_performance( ...
    faceVelocity_ms,flow_Lmin,geometry,coolant,coolantIn_C,airIn_C,a)
%CALCULATE_LOUVERED_RADIATOR_PERFORMANCE Literature-based core estimate.
% Air side: Chang and Wang (1997) louvered-fin j-factor with straight-fin
% efficiency. Coolant side: fully developed laminar flow in the flat tube
% (Shah and London 1978). Heat rejection: crossflow e-NTU, both unmixed.
% Louver geometry is assumed (register R01-R03); the result is an estimate
% of achievable performance, not a supplier map.

arguments
    faceVelocity_ms double {mustBePositive}
    flow_Lmin (1,1) double {mustBePositive}
    geometry table
    coolant table
    coolantIn_C (1,1) double
    airIn_C (1,1) double
    a (1,1) struct
end

v = faceVelocity_ms(:);
mm = 1e-3;
nTubes = geometry.TubeQuantity(1);
tubeLength = geometry.TubeLength_mm(1)*mm;
tubeDepth = geometry.FlatTubeExternalWidth_mm(1)*mm;
tubeHeight = geometry.FlatTubeExternalDepth_mm(1)*mm;
wall = geometry.AssumedTubeWallThickness_mm(1)*mm;
finThickness = geometry.AssumedFinThickness_mm(1)*mm;
finHeight = geometry.FinHeight_mm(1)*mm;
finPitch = geometry.FinPitch_mm(1)*mm;
finLength = geometry.FinLength_mm(1)*mm;
nChannels = geometry.FinQuantity(1);
frontalArea = geometry.FrontalArea_m2(1);

louverPitch = a.R01*mm;
louverAngle_deg = a.R02;
louverLength = a.R03*finHeight;
tubePitch = finHeight+tubeHeight;

% Air properties at inlet temperature.
T_K = airIn_C+273.15;
rhoAir = 101325/(287.05*T_K);
muAir = 1.716e-5*(T_K/273.15)^1.5*(273.15+110.4)/(T_K+110.4);
cpAir = 1007;
prAir = 0.705;

finsPerChannel = finLength/finPitch;
finArea = nChannels*finsPerChannel*2*finHeight*tubeDepth;
tubeArea = nTubes*2*tubeDepth*tubeLength*(1-finThickness/finPitch);
airArea = finArea+tubeArea;
freeFlowArea = nChannels*finLength*finHeight*(1-finThickness/finPitch);
sigma = freeFlowArea/frontalArea;

coreVelocity = v/sigma;
reLouver = rhoAir*coreVelocity*louverPitch/muAir;
j = reLouver.^-0.49*(louverAngle_deg/90)^0.27*(finPitch/louverPitch)^-0.14* ...
    (finHeight/louverPitch)^-0.29*(tubeDepth/louverPitch)^-0.23* ...
    (louverLength/louverPitch)^0.68*(tubePitch/louverPitch)^-0.28* ...
    (finThickness/louverPitch)^-0.05;
% R11 carries the published +/-15% scatter of the correlation.
hAir = a.R11*j.*rhoAir.*coreVelocity*cpAir/prAir^(2/3);
m = sqrt(2*hAir/(a.R04*finThickness));
finHalfHeight = finHeight/2;
finEfficiency = tanh(m*finHalfHeight)./(m*finHalfHeight);
surfaceEfficiency = 1-finArea/airArea*(1-finEfficiency);

innerWidth = tubeDepth-2*wall;
innerHeight = tubeHeight-2*wall;
innerArea = innerWidth*innerHeight;
hydraulicDiameter = 4*innerArea/(2*(innerWidth+innerHeight));
tubeFlow_m3s = flow_Lmin/60000/nTubes;
coolantVelocity = tubeFlow_m3s/innerArea;
reCoolant = coolant.Density_kgm3*coolantVelocity*hydraulicDiameter/ ...
    coolant.Viscosity_Pas;
hCoolant = a.R06*a.R05/hydraulicDiameter;
coolantArea = nTubes*2*(innerWidth+innerHeight)*tubeLength;

UA = 1./(1./(surfaceEfficiency.*hAir*airArea)+1/(hCoolant*coolantArea));
cAir = rhoAir*v*frontalArea*cpAir;
cCoolant = flow_Lmin/60000*coolant.Density_kgm3*coolant.Cp_JkgK;
cMin = min(cAir,cCoolant);
cMax = max(cAir,cCoolant);
cr = cMin./cMax;
ntu = UA./cMin;
effectiveness = 1-exp(ntu.^0.22./cr.*(exp(-cr.*ntu.^0.78)-1));
heat_W = effectiveness.*cMin*(coolantIn_C-airIn_C);

dynamicPressure = coolant.Density_kgm3*coolantVelocity^2/2;
coolantPressureDrop_kPa = (a.R07/reCoolant*tubeLength/hydraulicDiameter+a.R08)* ...
    dynamicPressure/1000;

n = numel(v);
result = table(v,repmat(flow_Lmin,n,1),reLouver,j,hAir,finEfficiency, ...
    repmat(hCoolant,n,1),repmat(reCoolant,n,1),UA,effectiveness, ...
    heat_W/1000,repmat(coolantPressureDrop_kPa,n,1), ...
    'VariableNames',{'FaceVelocity_ms','CoolantFlow_Lmin', ...
    'LouverReynolds','ColburnJ','AirSideH_Wm2K','FinEfficiency', ...
    'CoolantSideH_Wm2K','CoolantReynolds','EstimatedUA_WK', ...
    'Effectiveness','EstimatedHeatRejection_kW', ...
    'EstimatedCoolantPressureDrop_kPa'});
end
