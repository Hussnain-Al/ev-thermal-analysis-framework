function terms = calculate_battery_literature_terms(battery,gapBattery,a)
%CALCULATE_BATTERY_LITERATURE_TERMS DCIR model, entropic profile and path.
% DCIR = ACR / ratio at 25 C with Arrhenius temperature scaling. The cell-to-
% coolant path is built up as series resistances for a bottom-cooled
% prismatic cell (interior, internal base insulator, film, pad, cold-plate
% film).

terms.dcir25_Ohm = battery.resistanceProxy_Ohm/a.B01;
terms.activationEnergy_Jmol = a.B02*1000;
terms.dcir = @(T_C) terms.dcir25_Ohm*exp(terms.activationEnergy_Jmol/8.314* ...
    (1./(T_C+273.15)-1/298.15));
terms.entropic_VK = @(soc_pct) interp1(gapBattery.entropicSOC_pct, ...
    gapBattery.entropic_mVK*1e-3,soc_pct,'linear');
terms.peakDischargeEntropic_VK = -min(gapBattery.entropic_mVK)*1e-3;

baseArea_m2 = a.B10*1e-3*a.B11*1e-3;
height_m = a.B12*1e-3;
names = ["Cell interior (mean, axial)";"Jelly-roll to can base"; ...
    "Insulation film";"Thermal pad";"Cold-plate convection"];
resistance_KW = [height_m/(3*a.B13*baseArea_m2); ...
    a.B22*1e-3/(a.B23*baseArea_m2); ...
    a.B14*1e-3/(a.B15*baseArea_m2); ...
    a.B16*1e-3/(a.B17*baseArea_m2); ...
    1/(a.B18*baseArea_m2*a.B19)];
terms.pathBudget = table(names,resistance_KW, ...
    'VariableNames',{'PathElement','Resistance_KW'});
terms.pathResistance_KW = sum(resistance_KW);
terms.cellThermalCapacity_JK = a.B20*a.B21;
end
