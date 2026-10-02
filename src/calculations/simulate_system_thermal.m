function trace = simulate_system_thermal(time_s,batteryHeat_kW,cabinGrid_C, ...
    cabinLoad_kW,capacity_kW,p)
%SIMULATE_SYSTEM_THERMAL Cabin and battery loops sharing one compressor.
% Three lumped nodes, explicit Euler at the trace step:
%   C_cab  dTc/dt = Q_cab(Tc) - Q_evap
%   C_pack dTp/dt = Q_batt - (Tp - Tb)/R_pack
%   C_bc   dTb/dt = (Tp - Tb)/R_pack - Q_chiller
% Q_cab(Tc) is the heat-balance cabin load evaluated at the cabin
% temperature (interpolated on cabinGrid_C). Each loop asks for its current
% load plus a proportional correction toward its set point:
%   demand_cab = max(0, Q_cab(Tc) + K (Tc - Tset_cab))
%   demand_bat = max(0, (Tp - Tb)/R_pack + K (Tb - Tset_bat))
% When the demands exceed the compressor capacity both are scaled by the
% same factor (proportional sharing). Capacity is the rated capacity at the
% DM18A1 rating condition; there is no refrigerant-circuit model.

n = numel(time_s);
Tc = zeros(n,1); Tp = zeros(n,1); Tb = zeros(n,1);
evap = zeros(n,1); chiller = zeros(n,1); cabinLoad = zeros(n,1);
Tc(1) = p.cabinInitial_C;
Tp(1) = p.packInitial_C;
Tb(1) = p.batteryCoolantInitial_C;
capacity_W = 1000*capacity_kW;
for k = 1:n
    qCab = 1000*interp1(cabinGrid_C,cabinLoad_kW,Tc(k),'linear','extrap');
    flow = (Tp(k)-Tb(k))/p.packResistance_KW;
    demandCab = max(0,qCab+p.controllerGain_WK*(Tc(k)-p.cabinSetpoint_C));
    demandBat = max(0,flow+p.controllerGain_WK*(Tb(k)-p.batteryCoolantSetpoint_C));
    total = demandCab+demandBat;
    share = 1;
    if total>capacity_W
        share = capacity_W/total;
    end
    evap(k) = share*demandCab;
    chiller(k) = share*demandBat;
    cabinLoad(k) = qCab;
    if k<n
        dt = time_s(k+1)-time_s(k);
        Tc(k+1) = Tc(k)+dt*(qCab-evap(k))/p.cabinCapacitance_JK;
        Tp(k+1) = Tp(k)+dt*(1000*batteryHeat_kW(k)-flow)/p.packCapacitance_JK;
        Tb(k+1) = Tb(k)+dt*(flow-chiller(k))/p.batteryCoolantCapacitance_JK;
    end
end
trace = table(time_s(:),Tc,Tp,Tb,batteryHeat_kW(:),cabinLoad/1000, ...
    evap/1000,chiller/1000,(evap+chiller)/capacity_W, ...
    'VariableNames',{'Time_s','Cabin_C','Cell_C','BatteryCoolant_C', ...
    'BatteryHeat_kW','CabinLoad_kW','EvaporatorDuty_kW', ...
    'ChillerDuty_kW','CompressorUse'});
end
