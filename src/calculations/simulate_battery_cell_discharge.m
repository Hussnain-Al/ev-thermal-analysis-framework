function trace = simulate_battery_cell_discharge(cRate,coolant_C,pathResistance_KW, ...
    capacity_Ah,terms,timeStep_s)
%SIMULATE_BATTERY_CELL_DISCHARGE Lumped cell during a full constant-current discharge.
% Heat follows the Bernardi form without the overpotential split:
% Q = I^2 R_DC(T) - I T dU/dT (discharge current positive). The coolant is a
% fixed boundary, so this answers "what cell temperature follows from this
% coolant temperature", not what the coolant loop can deliver.

current_A = cRate*capacity_Ah;
duration_s = 3600/cRate;
time_s = (0:timeStep_s:duration_s)';
n = numel(time_s);
soc_pct = 100-100*time_s/duration_s;
cell_C = zeros(n,1);
joule_W = zeros(n,1);
reversible_W = zeros(n,1);
cell_C(1) = coolant_C;
for k = 1:n
    joule_W(k) = current_A^2*terms.dcir(cell_C(k));
    reversible_W(k) = -current_A*(cell_C(k)+273.15)*terms.entropic_VK(soc_pct(k));
    if k < n
        cell_C(k+1) = cell_C(k)+timeStep_s* ...
            (joule_W(k)+reversible_W(k)-(cell_C(k)-coolant_C)/pathResistance_KW)/ ...
            terms.cellThermalCapacity_JK;
    end
end
trace = table(repmat(cRate,n,1),repmat(coolant_C,n,1), ...
    repmat(pathResistance_KW,n,1),time_s,soc_pct,cell_C,joule_W,reversible_W, ...
    'VariableNames',{'C_rate','Coolant_C','PathResistance_KW','Time_s', ...
    'SOC_pct','CellTemperature_C','JouleHeat_W','ReversibleHeat_W'});
end
