function trace = calculate_battery_cycle_heat(motorTrace,battery)
%CALCULATE_BATTERY_CYCLE_HEAT Battery heat driven by a drive-cycle power trace.
% Pack current follows the DC-link power of the drive unit:
%   I = P_dc / V_pack   (positive = discharge, negative = regen charging)
% Every series cell carries I. State of charge is integrated from the
% current, starting at battery.cycleInitialSOC_pct.
%
% Expected heat (Bernardi form, per cell):
%   Q = I^2 R_DC(25 C) - I T dU/dT(SOC)
% The entropic term follows the SOC and the current direction, so it can
% be negative. Highest possible heat (per cell):
%   Q_max = I^2 R_DC,high + |I| T |dU/dT|peak
% uses the high end of the DC-resistance range and the low-SOC entropic
% peak at every second, so it bounds the expected trace from above.

t = motorTrace.Time_s;
n = numel(t);
current_A = motorTrace.DCLinkPower_kW*1000/battery.packNominalVoltage_V;
soc_pct = zeros(n,1);
soc_pct(1) = battery.cycleInitialSOC_pct;
for k = 1:n-1
    soc_pct(k+1) = soc_pct(k)-100*current_A(k)*(t(k+1)-t(k))/ ...
        (battery.capacity_Ah*3600);
end
socForProfile = min(max(soc_pct,0),100);
referenceTemperature_K = battery.entropicReferenceTemperature_C+273.15;
dUdT_VK = interp1(battery.entropicSOC_pct,battery.entropic_mVK*1e-3, ...
    socForProfile,'linear');

cells = battery.seriesCells;
joule_kW = current_A.^2*battery.dcResistance25_Ohm*cells/1000;
entropic_kW = -current_A*referenceTemperature_K.*dUdT_VK*cells/1000;
upper_kW = (current_A.^2*battery.dcResistance25Range_Ohm(2)+ ...
    abs(current_A)*referenceTemperature_K*battery.entropicPeak_VK)*cells/1000;

trace = table(motorTrace.Cycle,t,motorTrace.DCLinkPower_kW,current_A, ...
    current_A/battery.capacity_Ah,soc_pct,joule_kW,entropic_kW, ...
    joule_kW+entropic_kW,upper_kW,motorTrace.DriveUnitHeat_kW, ...
    'VariableNames',{'Cycle','Time_s','DCLinkPower_kW','PackCurrent_A', ...
    'C_rate','SOC_pct','JouleHeat_kW','EntropicHeat_kW', ...
    'BatteryHeat_kW','BatteryHeatUpperBound_kW','DriveUnitHeat_kW'});
end
