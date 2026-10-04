function trace = simulate_system_thermal(time_s,drive,cabinGrid_C,cabinLoad_kW, ...
    capacity_kW,p)
%SIMULATE_SYSTEM_THERMAL Closed-loop cabin, battery and propulsion thermal model.
% Five lumped nodes, explicit Euler at the trace step (1 s):
%   C_cab dTc/dt = Q_cab(Tc) - Q_evap
%   C_cell dTp/dt = Q_batt - (Tp - Tb)/R_pack
%   C_bc  dTb/dt = (Tp - Tb)/R_pack - Q_chiller
%   C_w   dTw/dt = f Q_motor - (Tw - Tcl)/R_w
%   C_cl  dTcl/dt = (Tw - Tcl)/R_w + f Q_controller - UA max(Tcl - Ta, 0)
% Controls (gains in p.control, tuned in run_system_thermal):
%   - cabin and battery-coolant PI controllers ask for evaporator and chiller
%     duty, with back-calculation anti-windup: each integrator is driven by
%     Ki e + (delivered - unsaturated demand) Ki/Kp, so it stops winding when
%     the compressor (or the priority logic) cannot deliver;
%   - cascade: the battery-coolant set point is lowered from its nominal
%     value by cascadeGain (T_cell - cellTarget), down to a floor;
%   - priority relay: the chiller is served first while the cells are above
%     p.control.priorityOn_C, until they fall to p.control.priorityOff_C;
%     otherwise the cabin is served first;
%   - derating: the requested DC power is scaled by f = min(BMS, motor)
%     factors from cell and winding temperature (regen uses the BMS charge
%     curve). Motor and controller losses scale with f (efficiency held at
%     the requested point); the power not delivered is reported.
% drive: table with Time_s, DCLinkPower_kW, MotorLoss_kW, ControllerLoss_kW.

n = numel(time_s);
c = p.control;
b = p.battery;
capacity_W = 1000*capacity_kW;
z = zeros(n,1);
Tc = z; Tp = z; Tb = z; Tw = z; Tcl = z; soc = z;
evap = z; chiller = z; cabinLoad = z; batteryHeat = z; factor = z;
delivered = z; unmet = z; priority = false(n,1); demandCab = z; demandBat = z;
coolantSetpoint = z;
Tc(1) = p.cabinInitial_C; Tp(1) = p.packInitial_C; Tb(1) = p.batteryCoolantInitial_C;
Tw(1) = p.motor.initialMotorTemperature_C; Tcl(1) = p.motor.initialCoolantTemperature_C;
soc(1) = b.cycleInitialSOC_pct;
Icab = 0; Ibat = 0; batteryFirst = false;
Tref_K = b.entropicReferenceTemperature_C+273.15;
for k = 1:n
    % Thermal management controllers.
    coolantSetpoint(k) = min(max(p.batteryCoolantSetpoint_C- ...
        c.cascadeGain_KK*(Tp(k)-c.cellTarget_C),c.coolantSetpointFloor_C), ...
        p.batteryCoolantSetpoint_C);
    eCab = Tc(k)-p.cabinSetpoint_C;
    eBat = Tb(k)-coolantSetpoint(k);
    rawCab = c.cabinKp_WK*eCab+Icab;
    rawBat = c.batteryKp_WK*eBat+Ibat;
    demandCab(k) = min(max(rawCab,0),capacity_W);
    demandBat(k) = min(max(rawBat,0),capacity_W);
    if ~batteryFirst && Tp(k)>=c.priorityOn_C
        batteryFirst = true;
    elseif batteryFirst && Tp(k)<=c.priorityOff_C
        batteryFirst = false;
    end
    priority(k) = batteryFirst;
    if batteryFirst
        chiller(k) = min(demandBat(k),capacity_W);
        evap(k) = min(demandCab(k),capacity_W-chiller(k));
    else
        evap(k) = min(demandCab(k),capacity_W);
        chiller(k) = min(demandBat(k),capacity_W-evap(k));
    end

    % Derating from cell and winding temperature.
    fMotor = ramp(Tw(k),c.motorDerate_C);
    request_kW = drive.DCLinkPower_kW(k);
    if request_kW>=0
        factor(k) = min(ramp(Tp(k),c.dischargeDerate_C),fMotor);
        unmet(k) = (1-factor(k))*request_kW;
    else
        factor(k) = min(ramp(Tp(k),c.chargeDerate_C),fMotor);
    end
    delivered(k) = factor(k)*request_kW;

    % Battery electrical side.
    current_A = 1000*delivered(k)/b.cycleVoltage_V;
    dUdT = interp1(b.entropicSOC_pct,1e-3*b.entropic_mVK,min(max(soc(k),0),100),'linear');
    batteryHeat(k) = b.seriesCells*(current_A^2*b.dcResistance25_Ohm- ...
        current_A*Tref_K*dUdT);

    qCab = 1000*interp1(cabinGrid_C,cabinLoad_kW,Tc(k),'linear','extrap');
    cabinLoad(k) = qCab;
    toCoolant = (Tp(k)-Tb(k))/p.packResistance_KW;
    toPropCoolant = (Tw(k)-Tcl(k))/p.motor.motorToCoolantResistance_KW;
    radiator = max(p.radiatorUA_WK*(Tcl(k)-p.ambient_C),0);
    if k<n
        dt = time_s(k+1)-time_s(k);
        Icab = Icab+dt*(c.cabinKi_WKs*eCab+(evap(k)-rawCab)*c.cabinKi_WKs/c.cabinKp_WK);
        Ibat = Ibat+dt*(c.batteryKi_WKs*eBat+(chiller(k)-rawBat)*c.batteryKi_WKs/c.batteryKp_WK);
        Tc(k+1) = Tc(k)+dt*(qCab-evap(k))/p.cabinCapacitance_JK;
        Tp(k+1) = Tp(k)+dt*(batteryHeat(k)-toCoolant)/p.packCapacitance_JK;
        Tb(k+1) = Tb(k)+dt*(toCoolant-chiller(k))/p.batteryCoolantCapacitance_JK;
        Tw(k+1) = Tw(k)+dt*(1000*factor(k)*drive.MotorLoss_kW(k)-toPropCoolant)/ ...
            p.motor.motorThermalCapacity_JK;
        Tcl(k+1) = Tcl(k)+dt*(toPropCoolant+1000*factor(k)*drive.ControllerLoss_kW(k)- ...
            radiator)/p.motor.coolantThermalCapacity_JK;
        soc(k+1) = soc(k)-100*current_A*dt/(b.capacity_Ah*3600);
    end
end
trace = table(time_s(:),Tc,Tp,Tb,Tw,Tcl,soc,drive.DCLinkPower_kW,delivered,unmet, ...
    factor,priority,coolantSetpoint,batteryHeat/1000,cabinLoad/1000,demandCab/1000,demandBat/1000, ...
    evap/1000,chiller/1000,(evap+chiller)/capacity_W, ...
    'VariableNames',{'Time_s','Cabin_C','Cell_C','BatteryCoolant_C', ...
    'DriveUnit_C','PropulsionCoolant_C','SOC_pct','RequestedDCPower_kW', ...
    'DeliveredDCPower_kW','UnmetDCPower_kW','DerateFactor','BatteryPriority', ...
    'CoolantSetpoint_C', ...
    'BatteryHeat_kW','CabinLoad_kW','CabinDemand_kW','BatteryDemand_kW', ...
    'EvaporatorDuty_kW','ChillerDuty_kW','CompressorUse'});
end

function f = ramp(T,limits)
% 1 at or below limits(1), 0 at or above limits(2), linear between.
f = min(max((limits(2)-T)/(limits(2)-limits(1)),0),1);
end
