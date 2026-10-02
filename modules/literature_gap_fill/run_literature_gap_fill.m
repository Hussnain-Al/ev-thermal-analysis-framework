function out = run_literature_gap_fill(cfg,motorHeat,motorCooling)
%RUN_LITERATURE_GAP_FILL Estimates for the blocked outputs using literature values.
% Each estimate is driven by data/literature/literature_assumption_register.csv
% and is reported separately from the evidence-based results. None of these
% outputs replaces a supplier map or a test; they show what comparable
% published designs imply and where the current assumptions disagree.

p = cfg.literatureGapFill;
outputDir = fullfile(cfg.project.outputDir,"literature_gap_fill");
ensure_output_folder(outputDir);
[a,out.register] = read_literature_assumptions(p.files.assumptionRegister);

out.operatingPoints = summarize_operating_points(motorHeat);
out.motorCalibration = calibration_sweep(cfg,p,motorHeat.curves,a);
[out.radiatorMap,out.radiatorDesignCheck] = estimate_radiator(cfg,p,motorCooling,a);
[out.batteryTerms,out.batteryEnvelope,out.batteryTransient,out.batteryTransientSummary] = ...
    estimate_battery(cfg,p,a);
[out.cabinAudit,out.cabinHeatBalance,out.cabinPullDown] = estimate_cabin(cfg,p,a);
[out.robustness,out.tornado] = evaluate_robustness(cfg,motorHeat,motorCooling,a,out.register);
out.referenceChecks = reference_checks(cfg,motorHeat,motorCooling,a, ...
    out.batteryTerms,out.cabinHeatBalance);

writetable(out.register,fullfile(outputDir,"literature_assumptions_used.csv"));
writetable(out.operatingPoints,fullfile(outputDir,"drive_operating_point_heat.csv"));
writetable(out.motorCalibration,fullfile(outputDir,"winding_resistance_calibration.csv"));
writetable(out.radiatorMap,fullfile(outputDir,"radiator_estimated_performance.csv"));
writetable(out.radiatorDesignCheck,fullfile(outputDir,"radiator_estimated_design_check.csv"));
writetable(out.batteryTerms.pathBudget,fullfile(outputDir,"battery_path_budget.csv"));
writetable(out.batteryEnvelope,fullfile(outputDir,"battery_coolant_envelope_comparison.csv"));
writetable(out.batteryTransientSummary,fullfile(outputDir,"battery_discharge_summary.csv"));
writetable(out.cabinAudit,fullfile(outputDir,"cabin_workbook_audit.csv"));
writetable(out.cabinHeatBalance,fullfile(outputDir,"cabin_heat_balance.csv"));
writetable(out.cabinPullDown,fullfile(outputDir,"cabin_pull_down_capacity.csv"));
writetable(out.robustness,fullfile(outputDir,"correction_robustness.csv"));
writetable(out.referenceChecks,fullfile(outputDir,"reference_checks.csv"));
writetable(out.tornado,fullfile(outputDir,"correction_sensitivity.csv"));

plot_operating_points(motorHeat,outputDir);
p.ratedSpeed_rpm = cfg.motorCooling.transient.ratedSpeedBasis_rpm;
plot_motor_calibration(out.motorCalibration,motorHeat,p,outputDir, ...
    height(cfg.motorHeat.operatingCases));
plot_radiator(out.radiatorMap,out.radiatorDesignCheck,motorCooling,cfg,outputDir);
plot_battery_heat_and_path(cfg.batteryCooling,p,out.batteryTerms,out.batteryEnvelope,outputDir);
plot_battery_transient(out.batteryTransient,cfg.batteryCooling,p,out.batteryTerms,outputDir);
plot_cabin(out.cabinAudit,out.cabinHeatBalance,out.cabinPullDown,cfg,outputDir);
plot_robustness(out.robustness,out.tornado,outputDir);
end

% -------------------------------------------------------------------------
% Calculations
% -------------------------------------------------------------------------
function summary = summarize_operating_points(motorHeat)
nCases = numel(motorHeat.details);
caseName = strings(nCases,1);
meanSpeed = zeros(nCases,1);
meanTorque = zeros(nCases,1);
heatWeightedEfficiency = zeros(nCases,1);
fractionBelow85 = zeros(nCases,1);
for i = 1:nCases
    d = motorHeat.details{i};
    motoring = d.RequestedWheelPower_kW>0;
    caseName(i) = d.Cycle(1);
    meanSpeed(i) = mean(d.MotorSpeed_rpm(motoring));
    meanTorque(i) = mean(d.RequestedMotorTorque_Nm(motoring));
    wheelEnergy = trapz(d.Time_s,max(d.RequestedWheelPower_kW,0));
    dcEnergy = trapz(d.Time_s,max(d.DCLinkPower_kW,0));
    heatWeightedEfficiency(i) = 100*wheelEnergy/dcEnergy;
    heat = d.DriveUnitHeat_kW;
    fractionBelow85(i) = 100*sum(heat(d.IntegratedEfficiency_pct<85))/max(sum(heat),eps);
end
summary = table(caseName,meanSpeed,meanTorque,heatWeightedEfficiency,fractionBelow85, ...
    'VariableNames',{'Case','MeanMotoringSpeed_rpm','MeanMotoringTorque_Nm', ...
    'EnergyWeightedMotoringEfficiency_pct','HeatShareBelow85pctEfficiency_pct'});
end

function result = calibration_sweep(cfg,p,curves,a)
result = calibrate_winding_resistance(curves,p.motor.ratedSpeedSweep_rpm,a.M01,a.M02, ...
    p.motor.referenceWinding_C-p.motor.referenceCoolant_C);
n = height(result);
result.CalibratedAtRatedPoint_KW = repmat( ...
    cfg.motorCooling.transient.motorToCoolantResistance_KW,n,1);
result.SupersededMotorToCoolant_KW = repmat( ...
    cfg.motorCooling.transient.superseded.motorToCoolantResistance_KW,n,1);
end

function [map,check] = estimate_radiator(cfg,p,motorCooling,a)
thermal = cfg.motorCooling.thermal;
coolant = cfg.motorCooling.coolant;
coolantRow = coolant(coolant.Temperature_C==thermal.propertyTemperature_C,:);
tables = cell(numel(p.radiator.coolantFlows_Lmin),1);
for i = 1:numel(p.radiator.coolantFlows_Lmin)
    tables{i} = calculate_louvered_radiator_performance( ...
        p.radiator.faceVelocity_ms,p.radiator.coolantFlows_Lmin(i), ...
        motorCooling.radiatorCandidate,coolantRow, ...
        thermal.radiatorCoolantIn_C,thermal.airIn_C,a);
end
map = vertcat(tables{:});

design = motorCooling.radiatorDesign;
atDesign = map(map.CoolantFlow_Lmin==thermal.designFlow_Lmin,:);
n = height(design);
estimatedAtRequiredVelocity_kW = interp1(atDesign.FaceVelocity_ms, ...
    atDesign.EstimatedHeatRejection_kW,design.RequiredCoreFaceVelocity_ms);
velocityForDuty_ms = nan(n,1);
for i = 1:n
    if design.SustainedHeatDuty_kW(i)<=max(atDesign.EstimatedHeatRejection_kW)
        velocityForDuty_ms(i) = interp1(atDesign.EstimatedHeatRejection_kW, ...
            atDesign.FaceVelocity_ms,design.SustainedHeatDuty_kW(i));
    end
end
estimatedUA_WK = interp1(atDesign.FaceVelocity_ms,atDesign.EstimatedUA_WK, ...
    design.RequiredCoreFaceVelocity_ms);
check = table(design.Case,design.SustainedHeatDuty_kW, ...
    design.RequiredCoreFaceVelocity_ms,estimatedAtRequiredVelocity_kW, ...
    velocityForDuty_ms,design.RequiredIdealUA_WK,estimatedUA_WK, ...
    repmat(cfg.motorCooling.transient.radiatorUA_WK,n,1), ...
    repmat(cfg.motorCooling.transient.superseded.radiatorUA_WK,n,1), ...
    repmat(atDesign.EstimatedCoolantPressureDrop_kPa(1),n,1), ...
    'VariableNames',{'Case','SustainedHeatDuty_kW', ...
    'RequiredFaceVelocity_10KRise_ms','EstimatedRejectionAtThatVelocity_kW', ...
    'EstimatedFaceVelocityForDuty_ms','RequiredIdealUA_WK', ...
    'EstimatedUAAtRequiredVelocity_WK','CorrectedNormalDrivingUA_WK', ...
    'SupersededTwoNodeUA_WK', ...
    'EstimatedCoolantPressureDrop_kPa'});
end

function [terms,envelope,transient,summary] = estimate_battery(cfg,p,a)
battery = cfg.batteryCooling;
terms = calculate_battery_literature_terms(battery,p.battery,a);
cRate = battery.cRates(:);
current = cRate*battery.capacity_Ah;
acrHeat = current.^2*battery.resistanceProxy_Ohm;
literatureHeat = current.^2*terms.dcir(25)+current*298.15*terms.peakDischargeEntropic_VK;
envelope = table(cRate,acrHeat, ...
    battery.absoluteOperatingLimit_C-acrHeat*battery.superseded.baseResistance_KW, ...
    battery.regenChargeCutoff_C-acrHeat*battery.superseded.baseResistance_KW, ...
    literatureHeat, ...
    battery.absoluteOperatingLimit_C-literatureHeat*terms.pathResistance_KW, ...
    battery.regenChargeCutoff_C-literatureHeat*terms.pathResistance_KW, ...
    'VariableNames',{'C_rate','ACRCellHeat_W','ReconstructedMaxCoolant60_C', ...
    'ReconstructedMaxCoolant55_C','LiteratureCellHeat_W', ...
    'LiteratureMaxCoolant60_C','LiteratureMaxCoolant55_C'});

paths = [terms.pathResistance_KW battery.superseded.baseResistance_KW];
traces = {};
for i = 1:numel(p.battery.cRates)
    for j = 1:numel(p.battery.coolantScenarios_C)
        for k = 1:numel(paths)
            traces{end+1,1} = simulate_battery_cell_discharge( ...
                p.battery.cRates(i),p.battery.coolantScenarios_C(j),paths(k), ...
                battery.capacity_Ah,terms,p.battery.timeStep_s); %#ok<AGROW>
        end
    end
end
transient = traces;
n = numel(traces);
rate = zeros(n,1);
coolant = zeros(n,1);
path = zeros(n,1);
peak = zeros(n,1);
jouleKJ = zeros(n,1);
reversibleKJ = zeros(n,1);
for i = 1:n
    t = traces{i};
    rate(i) = t.C_rate(1);
    coolant(i) = t.Coolant_C(1);
    path(i) = t.PathResistance_KW(1);
    peak(i) = max(t.CellTemperature_C);
    jouleKJ(i) = trapz(t.Time_s,t.JouleHeat_W)/1000;
    reversibleKJ(i) = trapz(t.Time_s,t.ReversibleHeat_W)/1000;
end
summary = table(rate,coolant,path,peak,peak>battery.regenChargeCutoff_C, ...
    peak>battery.absoluteOperatingLimit_C,jouleKJ,reversibleKJ, ...
    'VariableNames',{'C_rate','Coolant_C','PathResistance_KW', ...
    'PeakCellTemperature_C','Exceeds55C','Exceeds60C', ...
    'JouleHeat_kJ','ReversibleHeat_kJ'});
end

function [audit,balance,pullDown] = estimate_cabin(cfg,p,a)
audit = audit_cabin_workbook(cfg.cabinCooling.files.sourceWorkbook, ...
    p.cabin.workbookOutdoor_C,p.cabin.workbookIndoor_C);
rh = [a.K03;a.K02];
tables = cell(numel(rh),1);
for i = 1:numel(rh)
    components = calculate_cabin_heat_balance(a.K01,rh(i), ...
        cfg.cabinCooling.cabinSetpoint_C,cfg.cabinCooling.cabinRelativeHumidity_pct, ...
        p.cabin,a);
    components.Scenario = repmat(p.cabin.scenarioNames(i),height(components),1);
    components.OutdoorDryBulb_C = repmat(a.K01,height(components),1);
    components.OutdoorRH_pct = repmat(rh(i),height(components),1);
    tables{i} = components(:,{'Scenario','OutdoorDryBulb_C','OutdoorRH_pct', ...
        'Component','Load_kW'});
end
balance = vertcat(tables{:});

steady_kW = sum(balance.Load_kW(balance.Scenario==p.cabin.scenarioNames(end)));
mass_kJK = [a.C23 a.C24 a.C25];
minutes = p.cabin.pullDownTime_min;
capacity = steady_kW+mass_kJK.*(a.C26-cfg.cabinCooling.cabinSetpoint_C)./(minutes*60);
pullDown = array2table([minutes capacity],'VariableNames', ...
    {'PullDownTime_min','MeanCapacity_LowMass_kW', ...
    'MeanCapacity_CentralMass_kW','MeanCapacity_HighMass_kW'});
end

function [summary,tornado] = evaluate_robustness(cfg,motorHeat,motorCooling,a,register)
% For each correction: one-at-a-time sensitivity to every assumption that
% feeds it, the combined extremes, and whether the conclusion survives.
geometry = motorCooling.radiatorCandidate;
curves = motorHeat.curves;
g = cfg.literatureGapFill;
transient = cfg.motorCooling.transient;
battery = cfg.batteryCooling;

pathFn = @(x) path_of(cfg,x);
[pathT,pathC] = evaluate_assumption_sensitivity(pathFn,a,register, ...
    ["B13";"B14";"B15";"B18";"B22";"B23";"P01";"P02";"P03";"P04";"P05";"P06"]);
uaFn = @(x) normal_ua(cfg,x,curves,geometry);
[uaT,uaC] = evaluate_assumption_sensitivity(uaFn,a,register, ...
    ["R09";"R01";"R02";"R03";"R04";"R05";"R06";"R11"]);
cabinFn = @(x) cabin_total(cfg,x);
[cabinT,cabinC] = evaluate_assumption_sensitivity(cabinFn,a,register, ...
    ["K02";"C10";"C11";"C12";"C13";"C14";"C15";"C16";"C17";"C19";"C20";"C21";"C22"]);

% Winding resistance: the supplier rated point fixes the speed, so only the
% controller-loss row is varied.
rise = g.motor.referenceWinding_C-g.motor.referenceCoolant_C;
m02 = register(register.ID=="M02",:);
atLow = calibrate_winding_resistance(curves,transient.ratedSpeedBasis_rpm,a.M01,m02.Low,rise);
atHigh = calibrate_winding_resistance(curves,transient.ratedSpeedBasis_rpm,a.M01,m02.High,rise);
centralR = transient.motorToCoolantResistance_KW;
motorT = table("M02",m02.Parameter,centralR, ...
    atLow.ImpliedWindingToCoolant_KW,atHigh.ImpliedWindingToCoolant_KW, ...
    'VariableNames',{'Assumption','Parameter','Central','OutputAtLow','OutputAtHigh'});
motorC = struct('Central',centralR, ...
    'Minimum',transient.motorToCoolantResistanceRange_KW(1), ...
    'Maximum',transient.motorToCoolantResistanceRange_KW(2));

% 5-95% bands from joint Halton samples of the same register rows. The
% winding resistance has a single uncertain input, so it has no band.
nSamples = g.uncertaintySamples;
pathValues = sample_assumption_distribution(pathFn,a,register, ...
    ["B13";"B14";"B15";"B18";"B22";"B23";"P01";"P02";"P04";"P06"],nSamples);
uaValues = sample_assumption_distribution(uaFn,a,register, ...
    ["R09";"R01";"R02";"R03";"R04";"R05";"R06";"R11"],nSamples);
cabinValues = sample_assumption_distribution(cabinFn,a,register, ...
    ["K02";"C10";"C11";"C12";"C13";"C14";"C15";"C16";"C17";"C19";"C20";"C21";"C22"], ...
    nSamples);
bands = [percentile_linear(pathValues,[5 95])'; ...
    percentile_linear(uaValues,[5 95])'; ...
    NaN NaN; ...
    percentile_linear(cabinValues,[5 95])'];

names = ["Battery cell-to-coolant path (K/W)";"Radiator UA, normal driving (W/K)"; ...
    "Winding-to-coolant resistance (K/W)";"Cabin load, humid heat (kW)"];
previous = [battery.superseded.baseResistance_KW; ...
    transient.superseded.radiatorUA_WK; ...
    transient.superseded.motorToCoolantResistance_KW; ...
    cfg.cabinCooling.recoveredCabinDuty_kW];
combined = [pathC;uaC;motorC;cabinC];
central = [combined.Central]';
minimum = [combined.Minimum]';
maximum = [combined.Maximum]';
% Conclusions: path and UA are below the superseded values, the winding
% resistance is above it, and the cabin load exceeds the recorded subtotal.
holds = [maximum(1)<previous(1);maximum(2)<previous(2); ...
    minimum(3)>previous(3);minimum(4)>previous(4)];
holdsWithinBand = [bands(1,2)<previous(1);bands(2,2)<previous(2); ...
    holds(3);bands(4,1)>previous(4)];
claim = ["Superseded 3.10 K/W lies above the whole range"; ...
    "Superseded 665 W/K lies above the whole range"; ...
    "Superseded 0.015 K/W lies below the whole range"; ...
    "Load exceeds the recorded 4.156 kW subtotal"];
summary = table(names,central,bands(:,1),bands(:,2),minimum,maximum, ...
    previous,claim,holdsWithinBand,holds, ...
    'VariableNames',{'Correction','Central','P05','P95','CombinedMinimum', ...
    'CombinedMaximum','SupersededValue','Claim','ClaimHoldsWithin5to95', ...
    'ClaimHoldsAcrossRange'});

pathT.Correction = repmat(names(1),height(pathT),1);
uaT.Correction = repmat(names(2),height(uaT),1);
motorT.Correction = repmat(names(3),height(motorT),1);
cabinT.Correction = repmat(names(4),height(cabinT),1);
tornado = [pathT;uaT;motorT;cabinT];
tornado = tornado(:,{'Correction','Assumption','Parameter','Central', ...
    'OutputAtLow','OutputAtHigh'});
end

function checks = reference_checks(cfg,motorHeat,motorCooling,a,batteryTerms,cabinBalance)
% Compare stated model assumptions with the project's supplier references.
transient = cfg.motorCooling.transient;
curves = motorHeat.curves;

% 1. Supplier peak point: 103 C winding after 30 s at 125 kW / 280 Nm, 60 C coolant.
m = cfg.literatureGapFill.motor;
peakPower_kW = m.peakPower_kW;
peakControllerLoss_kW = m.peakControllerLoss_kW;
torque = m.peakTorque_Nm;
speed = peakPower_kW*1000/(torque*2*pi/60);
eta = estimate_integrated_drive_efficiency(speed,torque,curves);
peakMotorLoss_kW = peakPower_kW/eta-peakPower_kW-peakControllerLoss_kW;
time_s = (0:m.peakDuration_s)';
peakTrace = table(repmat("Supplier peak",numel(time_s),1),time_s, ...
    repmat(peakMotorLoss_kW,numel(time_s),1), ...
    'VariableNames',{'Cycle','Time_s','DriveUnitHeat_kW'});
peakParameters = transient;
peakParameters.initialMotorTemperature_C = 60;
peakParameters.initialCoolantTemperature_C = 60;
peakResult = simulate_motor_coolant_thermal(peakTrace,60,peakParameters);
impliedWindingCapacity_kJK = peakMotorLoss_kW*m.peakDuration_s/(m.peakWinding_C-60);

% 2. SVOLT thermal references, adiabatic lumped cell from full charge.
oneC = simulate_battery_cell_discharge(1,25,Inf,cfg.batteryCooling.capacity_Ah, ...
    batteryTerms,1);
threeC = simulate_battery_cell_discharge(3,25,Inf,cfg.batteryCooling.capacity_Ah, ...
    batteryTerms,1);
rise1C = oneC.CellTemperature_C(oneC.Time_s==600)-25;
rise3C = threeC.CellTemperature_C(threeC.Time_s==30)-25;

% 3. Rated compressor capacity against the humid-heat cabin load.
humid = cabinBalance.Scenario==cfg.literatureGapFill.cabin.scenarioNames(end);
cabinLoad_kW = sum(cabinBalance.Load_kW(humid));

% 4. Cell resistance: SVOLT pulse-power ceiling and the GFL sibling-cell test.
b = cfg.batteryCooling;
pulseCurrent_A = b.pulsePower_W/b.pulseCutoff_V;
pulseCeiling_mOhm = 1000*(b.plateauOCV_V-b.pulseCutoff_V)/pulseCurrent_A;
sibling = read_project_csv(b.files.siblingRateTest, ...
    {'DischargedCapacity_Ah','Voltage0p5C_V','Voltage1C_V','Voltage2C_V','Voltage3C_V'}, ...
    {'DischargedCapacity_Ah','Voltage0p5C_V','Voltage1C_V','Voltage2C_V','Voltage3C_V'});
siblingR_mOhm = 1000*(sibling.Voltage0p5C_V-sibling.Voltage1C_V)/ ...
    (0.5*b.siblingCapacity_Ah)*b.siblingCapacity_Ah/b.capacity_Ah;
siblingAtDepth_mOhm = siblingR_mOhm(sibling.DischargedCapacity_Ah==b.siblingReferenceDepth_Ah);
mid = sibling.DischargedCapacity_Ah>=20 & sibling.DischargedCapacity_Ah<=80;
siblingFinding = sprintf(['Within %.0f%%; over 20-80 Ah depth the scaled test gives ' ...
    '%.2f-%.2f mOhm, inside the %.2f-%.2f mOhm band'], ...
    100*abs(b.dcResistance25_Ohm*1000/siblingAtDepth_mOhm-1), ...
    min(siblingR_mOhm(mid)),max(siblingR_mOhm(mid)), ...
    1000*b.dcResistance25Range_Ohm(1),1000*b.dcResistance25Range_Ohm(2));

% 5. Coolant datasheet limits (LubeMax 50/50).
peakCoolant_C = max(motorCooling.summary.PeakCoolantTemperature_C);
screen2C = calculate_battery_requirements_screen(2,cfg.batteryCooling);

check = ["Drive unit after 30 s at 125 kW peak";"Winding thermal capacitance"; ...
    "Cell rise, 1C for 600 s";"Cell rise, 3C for 30 s"; ...
    "Cabin load against rated compressor"; ...
    "Peak propulsion coolant temperature, all cases"; ...
    "Coolant needed for sustained 2C (60 C cell)"; ...
    "Cell DC resistance, high end of band"; ...
    "Cell DC resistance, central"];
reference = ["Supplier 103 C winding";"Implied by supplier peak point"; ...
    "SVOLT limit 15 C";"SVOLT limit 10 C";"DM18A1 rated 2.9 kW (6000 rpm, about 0 C / 57 C)"; ...
    "LubeMax 50/50 boiling point, unpressurized";"LubeMax 50/50 freeze point"; ...
    "Ceiling from SVOLT 10 s pulse power (1456 W to 2.5 V)"; ...
    "GFL 100 Ah vendor rate test, 0.5C-1C at 50 Ah, scaled to 134 Ah"];
referenceValue = [103;impliedWindingCapacity_kJK;15;10; ...
    cfg.cabinCooling.compressorRatedCapacity_kW; ...
    cfg.motorCooling.coolantBoilingPoint_C;cfg.motorCooling.coolantFreezePoint_C; ...
    pulseCeiling_mOhm;siblingAtDepth_mOhm];
modelValue = [peakResult.MotorTemperature_C(end); ...
    transient.motorThermalCapacity_JK/1000;rise1C;rise3C;cabinLoad_kW; ...
    peakCoolant_C;screen2C.MaximumCoolantForDischarge_C; ...
    1000*b.dcResistance25Range_Ohm(2);1000*b.dcResistance25_Ohm];
unit = ["degC";"kJ/K";"K";"K";"kW";"degC";"degC";"mOhm";"mOhm"];
peakFinding = sprintf(['Within %.1f K: the winding node, fitted only to the rated ' ...
    'heating curve, also reproduces the 30 s peak'],peakResult.MotorTemperature_C(end)-103);
capacityFinding = sprintf(['Rated heating curve gives %.1f kJ/K (time constant %.0f s, ' ...
    'fit RMS %.1f K); the peak point implies %.1f kJ/K'], ...
    transient.motorThermalCapacity_JK/1000,transient.windingTimeConstant_s, ...
    transient.windingFitRms_K,impliedWindingCapacity_kJK);
finding = [string(peakFinding); ...
    string(capacityFinding); ...
    "Consistent; the limit would need about 3.7 mOhm, so it does not test the resistance"; ...
    "Consistent; not a discriminating test"; ...
    "Compressor is below the cabin load before any battery chiller duty"; ...
    "Large boiling margin even without the pressure cap"; ...
    "Above the freeze point but far below a practical chiller supply: 2C sustained is not a cooling target"; ...
    "Consistent; a minimum power only caps the resistance, so it does not test the central value"; ...
    string(siblingFinding)];
checks = table(check,reference,referenceValue,modelValue,unit,finding, ...
    'VariableNames',{'Check','Reference','ReferenceValue','ModelValue','Unit','Finding'});
end

function value = path_of(cfg,a)
terms = calculate_battery_literature_terms(cfg.batteryCooling, ...
    cfg.literatureGapFill.battery,a);
value = terms.pathResistance_KW;
end

function value = normal_ua(cfg,a,curves,geometry)
d = derive_corrected_parameters(cfg,a,curves,geometry);
value = d.radiatorUA_WK;
end

function value = cabin_total(cfg,a)
components = calculate_cabin_heat_balance(cfg.cabinCooling.designAmbient_C,a.K02, ...
    cfg.cabinCooling.cabinSetpoint_C,cfg.cabinCooling.cabinRelativeHumidity_pct, ...
    cfg.literatureGapFill.cabin,a);
value = sum(components.Load_kW);
end

% -------------------------------------------------------------------------
% Figures
% -------------------------------------------------------------------------
function plot_robustness(summary,tornado,outputDir)
fig = figure('Visible','off','Color','w','Position',[100 100 1500 900]);
layout = tiledlayout(2,2,'TileSpacing','compact');
for i = 1:height(summary)
    nexttile;
    rows = tornado(tornado.Correction==summary.Correction(i),:);
    swing = abs(rows.OutputAtHigh-rows.OutputAtLow);
    [~,order] = sort(swing,'ascend');
    rows = rows(order,:);
    hold on;
    patch([summary.CombinedMinimum(i) summary.CombinedMaximum(i) ...
        summary.CombinedMaximum(i) summary.CombinedMinimum(i)], ...
        [0.4 0.4 height(rows)+0.6 height(rows)+0.6],[0.92 0.94 0.98], ...
        'EdgeColor','none','DisplayName','All worst-case ends combined');
    if ~isnan(summary.P05(i))
        patch([summary.P05(i) summary.P95(i) summary.P95(i) summary.P05(i)], ...
            [0.4 0.4 height(rows)+0.6 height(rows)+0.6],[0.78 0.86 1.0], ...
            'EdgeColor','none','DisplayName','5-95% of sampled ranges');
    end
    for k = 1:height(rows)
        lo = min(rows.OutputAtLow(k),rows.OutputAtHigh(k));
        hi = max(rows.OutputAtLow(k),rows.OutputAtHigh(k));
        patch([lo hi hi lo],[k-0.3 k-0.3 k+0.3 k+0.3],[0.25 0.45 0.85], ...
            'EdgeColor','none','HandleVisibility','off');
        % Mark the end that the assumption's high value produces.
        plot(rows.OutputAtHigh(k),k,'k>','MarkerSize',4,'HandleVisibility','off');
    end
    xline(summary.Central(i),'k-','LineWidth',1.5,'DisplayName','Adopted value');
    xline(summary.SupersededValue(i),'r--','LineWidth',1.8, ...
        'DisplayName','Superseded value');
    yticks(1:height(rows));
    yticklabels(rows.Assumption+": "+rows.Parameter);
    set(gca,'FontSize',7,'TickLabelInterpreter','none');
    grid on;
    if summary.ClaimHoldsAcrossRange(i)
        verdict = "holds at every combined extreme";
    elseif summary.ClaimHoldsWithin5to95(i)
        verdict = "holds within 5-95%, not at every extreme";
    else
        verdict = "does not hold";
    end
    title(summary.Correction(i)+" - claim "+verdict,'FontSize',9);
    legend('Location','best','FontSize',7);
end
title(layout,'Do the corrections survive their assumption ranges?');
exportgraphics(fig,fullfile(outputDir,"gap_correction_robustness.png"),'Resolution',150);
close(fig);
end

function plot_operating_points(motorHeat,outputDir)
curves = motorHeat.curves;
fig = figure('Visible','off','Color','w','Position',[100 100 1300 520]);
layout = tiledlayout(1,2,'TileSpacing','compact');
nexttile;
contourf(curves.efficiencyRPM,curves.efficiencyTorque_Nm, ...
    100*curves.integratedEfficiency',[50 70 80 85 88 90 92 93 94 95.5], ...
    'LineColor',[1 1 1],'HandleVisibility','off');
colormap(gca,parula(12));
cb = colorbar;
cb.Label.String = 'Integrated efficiency (%)';
hold on;
plot(curves.torqueRPM,curves.maxTorque_Nm,'k-','LineWidth',1.6, ...
    'DisplayName','Peak torque envelope');
markers = {'.','.','d','d'};
colors = lines(numel(motorHeat.details));
for i = 1:numel(motorHeat.details)
    d = motorHeat.details{i};
    motoring = d.RequestedWheelPower_kW>0;
    if strcmp(markers{min(i,4)},'d')
        plot(d.MotorSpeed_rpm(1),d.RequestedMotorTorque_Nm(1),'d', ...
            'MarkerSize',9,'MarkerFaceColor',colors(i,:),'MarkerEdgeColor','w', ...
            'DisplayName',d.Cycle(1));
    else
        scatter(d.MotorSpeed_rpm(motoring),d.RequestedMotorTorque_Nm(motoring), ...
            10,[0.85 0.15 0.15]*(i==2)+[0.95 0.95 0.95]*(i==1), ...
            'filled','MarkerEdgeColor','k','LineWidth',0.2, ...
            'DisplayName',d.Cycle(1));
    end
end
xlim([0 12000]); ylim([0 300]);
xlabel('Drive-unit speed (rpm)'); ylabel('Torque (Nm)');
title('Where each schedule operates on the efficiency map');
legend('Location','northeast');

nexttile;
speedEdges = linspace(0,12000,13);
torqueEdges = linspace(0,300,13);
heat_Wh = zeros(12,12);
for i = 1:2
    d = motorHeat.details{i};
    s = discretize(d.MotorSpeed_rpm,speedEdges);
    t = discretize(abs(d.RequestedMotorTorque_Nm),torqueEdges);
    ok = ~isnan(s) & ~isnan(t);
    heat_Wh = heat_Wh+accumarray([s(ok) t(ok)],d.DriveUnitHeat_kW(ok)*1000/3600,[12 12]);
end
imagesc(speedEdges(1:end-1)+500,torqueEdges(1:end-1)+12.5,heat_Wh');
set(gca,'YDir','normal');
colormap(gca,flipud(hot(64)));
cb = colorbar;
cb.Label.String = 'Drive-unit heat (Wh)';
hold on;
plot(curves.torqueRPM,curves.maxTorque_Nm,'k-','LineWidth',1.6);
xlim([0 12000]); ylim([0 300]);
xlabel('Drive-unit speed (rpm)'); ylabel('|Torque| (Nm)');
title('Heat energy by operating region (NYCC + HWFET)');
title(layout,'Gap fill 1: operating-point density on the supplied map (calculated, no new assumption)');
exportgraphics(fig,fullfile(outputDir,"gap_drive_operating_points.png"),'Resolution',150);
close(fig);
end

function plot_motor_calibration(cal,motorHeat,p,outputDir,nCases)
fig = figure('Visible','off','Color','w','Position',[100 100 1300 480]);
layout = tiledlayout(1,2,'TileSpacing','compact');
nexttile;
plot(cal.AssumedRatedSpeed_rpm,cal.ImpliedWindingToCoolant_KW,'LineWidth',2, ...
    'DisplayName','Implied winding-to-coolant R');
hold on;
yline(cal.SupersededMotorToCoolant_KW(1),'r--','LineWidth',1.5, ...
    'DisplayName','Superseded R = 0.015 K/W');
ratedSpeed = p.ratedSpeed_rpm;
plot(ratedSpeed,cal.CalibratedAtRatedPoint_KW(1),'bo','MarkerFaceColor','b', ...
    'DisplayName',sprintf('Adopted: supplier rated point, %.0f rpm / %.0f Nm', ...
    ratedSpeed,p.motor.ratedTorque_Nm));
grid on; ylim([0 1.2*max(cal.ImpliedWindingToCoolant_KW)]);
xlabel('Assumed rated operating speed (rpm)');
ylabel('Winding-to-coolant resistance (K/W)');
title('Supplier 143 C rated-rise point implies a higher resistance');
legend('Location','southeast');

nexttile;
hold on;
rMid = cal.CalibratedAtRatedPoint_KW(1);
coolant = linspace(45,75,31)';
nCycles = numel(motorHeat.details)-nCases;
colors = lines(nCases);
for i = 1:nCases
    row = nCycles+i;
    q = motorHeat.summary.AverageMotorLoss_kW(row)*1000;
    name = motorHeat.summary.Cycle(row);
    plot(coolant,coolant+q*rMid,'-','Color',colors(i,:),'LineWidth',2, ...
        'DisplayName',sprintf('%s: implied R %.3f K/W, motor loss only',name,rMid));
    plot(coolant,coolant+q*cal.SupersededMotorToCoolant_KW(1),'--', ...
        'Color',colors(i,:),'LineWidth',1.2, ...
        'DisplayName',sprintf('%s: superseded R',name));
end
yline(p.motor.insulationClassH_C,'k:','Class H insulation 180 C','HandleVisibility','off');
yline(150,':','Typical design hot-spot target 150 C','HandleVisibility','off');
grid on; ylim([40 200]);
xlabel('Coolant at drive unit (C)'); ylabel('Winding hot-spot (C)');
title('Steady winding hot-spot at sustained design duty');
legend('Location','southeast','FontSize',7);
title(layout,'Gap fill 2: winding resistance back-calculated from the supplier rated point (143 C at 60 kW, 60 C coolant)');
exportgraphics(fig,fullfile(outputDir,"gap_motor_resistance_calibration.png"),'Resolution',150);
close(fig);
end

function plot_radiator(map,check,motorCooling,cfg,outputDir)
fig = figure('Visible','off','Color','w','Position',[100 100 1300 480]);
layout = tiledlayout(1,2,'TileSpacing','compact');
nexttile;
hold on;
flows = unique(map.CoolantFlow_Lmin);
for i = 1:numel(flows)
    rows = map.CoolantFlow_Lmin==flows(i);
    plot(map.FaceVelocity_ms(rows),map.EstimatedHeatRejection_kW(rows), ...
        'LineWidth',2,'DisplayName',sprintf('%g L/min coolant',flows(i)));
end
for i = 1:height(check)
    if isnan(check.EstimatedFaceVelocityForDuty_ms(i))
        label = sprintf('%s: exceeds the core at %.0f m/s',check.Case(i), ...
            max(map.FaceVelocity_ms));
    else
        label = sprintf('%s: needs %.1f m/s',check.Case(i), ...
            check.EstimatedFaceVelocityForDuty_ms(i));
    end
    yline(check.SustainedHeatDuty_kW(i),'--',label, ...
        'HandleVisibility','off','LabelHorizontalAlignment','left');
end
grid on;
xlabel('Core-face air velocity (m/s)'); ylabel('Heat rejection (kW)');
title('Estimated heat rejection, 65 C coolant in, 45 C air in');
legend('Location','southeast');

nexttile;
rows = map.CoolantFlow_Lmin==cfg.motorCooling.thermal.designFlow_Lmin;
plot(map.FaceVelocity_ms(rows),map.EstimatedUA_WK(rows),'LineWidth',2, ...
    'DisplayName','Estimated achieved UA (20 L/min)');
hold on;
requirementColors = [0.85 0.15 0.15;0.55 0.25 0.75;0.10 0.55 0.35];
for i = 1:height(motorCooling.radiatorDesign)
    yline(motorCooling.radiatorDesign.RequiredIdealUA_WK(i),'--', ...
        'Color',requirementColors(i,:),'LineWidth',1.4, ...
        'DisplayName',"Required ideal UA, "+motorCooling.radiatorDesign.Case(i));
end
yline(cfg.motorCooling.transient.superseded.radiatorUA_WK,':','LineWidth',1.3, ...
    'DisplayName','Superseded two-node UA (665 W/K)');
grid on;
xlabel('Core-face air velocity (m/s)'); ylabel('UA (W/K)');
title('Estimated achieved UA vs requirement and model input');
legend('Location','east');
title(layout,'Gap fill 3: candidate core performance from Chang-Wang louver correlation (louver geometry assumed)');
exportgraphics(fig,fullfile(outputDir,"gap_radiator_performance_map.png"),'Resolution',150);
close(fig);
end

function plot_battery_heat_and_path(battery,p,terms,envelope,outputDir)
fig = figure('Visible','off','Color','w','Position',[100 100 1600 480]);
layout = tiledlayout(1,3,'TileSpacing','compact');
nexttile;
soc = linspace(0,100,201)';
current = battery.capacity_Ah;
plot(soc,repmat(current^2*terms.dcir(25),size(soc)),'LineWidth',2, ...
    'DisplayName','Joule, DCIR at 25 C');
hold on;
plot(soc,repmat(current^2*terms.dcir(45),size(soc)),'LineWidth',2, ...
    'DisplayName','Joule, DCIR at 45 C');
plot(soc,repmat(current^2*battery.resistanceProxy_Ohm,size(soc)),'k--', ...
    'DisplayName','Superseded ACR heat');
plot(soc,-current*298.15*terms.entropic_VK(soc),'LineWidth',2, ...
    'DisplayName','Reversible (entropic), 25 C');
yline(0,'k-','HandleVisibility','off');
grid on;
xlabel('State of charge (%)'); ylabel('Cell heat (W)');
title('Cell heat sources at 1C discharge');
legend('Location','northeast');

nexttile;
budget = terms.pathBudget;
nElements = height(budget);
stackData = [budget.Resistance_KW' 0; zeros(1,nElements) battery.superseded.baseResistance_KW];
barh([1 2],stackData,'stacked');
yticks([1 2]);
yticklabels({'Literature build-up','Reconstructed path'});
legend([budget.PathElement+compose(": %.3f",budget.Resistance_KW); ...
    sprintf("Reconstructed: %.2f",battery.superseded.baseResistance_KW)], ...
    'Location','southeast','FontSize',7);
grid on;
xlabel('Thermal resistance (K/W)');
title(sprintf('Cell-to-coolant resistance: %.2f vs %.2f K/W', ...
    terms.pathResistance_KW,battery.superseded.baseResistance_KW));

nexttile;
plot(envelope.C_rate,envelope.ReconstructedMaxCoolant60_C,'r--','LineWidth',2, ...
    'DisplayName','Reconstructed path, ACR, 60 C');
hold on;
plot(envelope.C_rate,envelope.ReconstructedMaxCoolant55_C,'r:','LineWidth',1.4, ...
    'DisplayName','Reconstructed path, ACR, 55 C');
plot(envelope.C_rate,envelope.LiteratureMaxCoolant60_C,'b-','LineWidth',2, ...
    'DisplayName','Literature path, DCIR(25 C) + peak entropic, 60 C');
plot(envelope.C_rate,envelope.LiteratureMaxCoolant55_C,'b:','LineWidth',1.4, ...
    'DisplayName','Literature path, DCIR(25 C) + peak entropic, 55 C');
yline(45,'k:','45 C ambient','HandleVisibility','off');
grid on; ylim([-40 65]);
xlabel('Sustained C-rate'); ylabel('Maximum allowable coolant temperature (C)');
title('Coolant envelope comparison');
legend('Location','southwest','FontSize',7);
title(layout,'Gap fill 4: battery heat terms and cell-to-coolant path from literature values');
exportgraphics(fig,fullfile(outputDir,"gap_battery_heat_and_path.png"),'Resolution',150);
close(fig);
end

function plot_battery_transient(traces,battery,p,terms,outputDir)
fig = figure('Visible','off','Color','w','Position',[100 100 1300 480]);
layout = tiledlayout(1,2,'TileSpacing','compact');
colors = lines(numel(p.battery.cRates));
for j = 1:numel(p.battery.coolantScenarios_C)
    nexttile;
    hold on;
    coolant = p.battery.coolantScenarios_C(j);
    for k = 1:numel(traces)
        t = traces{k};
        if t.Coolant_C(1)~=coolant
            continue
        end
        c = find(p.battery.cRates==t.C_rate(1),1);
        if abs(t.PathResistance_KW(1)-terms.pathResistance_KW)<1e-12
            style = '-'; width = 2; label = sprintf('%gC, literature path %.2f K/W', ...
                t.C_rate(1),terms.pathResistance_KW);
        else
            style = '--'; width = 1.2; label = sprintf('%gC, reconstructed %.2f K/W', ...
                t.C_rate(1),battery.superseded.baseResistance_KW);
        end
        plot(t.Time_s/60,t.CellTemperature_C,style,'Color',colors(c,:), ...
            'LineWidth',width,'DisplayName',label);
    end
    yline(battery.absoluteOperatingLimit_C,'r:','60 C absolute','HandleVisibility','off');
    yline(battery.regenChargeCutoff_C,':','55 C charge cutoff','HandleVisibility','off');
    grid on;
    xlabel('Time from full charge (min)'); ylabel('Cell temperature (C)');
    title(sprintf('%s, %g C',p.battery.coolantScenarioNames(j),coolant));
    legend('Location','southoutside','NumColumns',3,'FontSize',7);
end
title(layout,'Gap fill 5: constant-current discharge transient (single lumped cell, DCIR + entropic heat)');
exportgraphics(fig,fullfile(outputDir,"gap_battery_discharge_transient.png"),'Resolution',150);
close(fig);
end

function plot_cabin(audit,balance,pullDown,cfg,outputDir)
fig = figure('Visible','off','Color','w','Position',[100 100 1700 520]);
layout = tiledlayout(1,3,'TileSpacing','compact');
nexttile;
barh([audit.RecordedInWorkbook_W audit.Recomputed_W]);
yticks(1:height(audit)); yticklabels(audit.Surface);
set(gca,'YDir','reverse');
legend({sprintf('Recorded in workbook (%.0f W)',sum(audit.RecordedInWorkbook_W)), ...
    sprintf('Recomputed, same inputs (%.0f W)',sum(audit.Recomputed_W))}, ...
    'Location','east');
grid on; xlabel('Load (W)');
title('Workbook audit: body and glazing rows');

nexttile;
scenarios = unique(balance.Scenario,'stable');
components = unique(balance.Component,'stable');
data = zeros(numel(scenarios),numel(components));
for i = 1:numel(scenarios)
    data(i,:) = balance.Load_kW(balance.Scenario==scenarios(i))';
end
recovered = cfg.cabinCooling.recoveredCabinDuty_kW;
groups = [scenarios;"Workbook (recorded)"];
bars = bar(categorical(groups,groups), ...
    [data zeros(numel(scenarios),1); zeros(1,numel(components)) recovered], ...
    'stacked');
palette = cabin_palette();
for k = 1:numel(components)
    bars(k).FaceColor = palette(k,:);
end
bars(end).FaceColor = [0.55 0.55 0.55];
set(gca,'XTickLabelRotation',0);
ylim([0 1.6*max(sum([data;recovered zeros(1,numel(components)-1)],2))]);
legend([components;"Recovered workbook subtotal (as recorded)"], ...
    'Location','northwest','FontSize',7);
grid on; ylabel('Load (kW)');
title('Steady cabin load at 15:00, 25 C / 50% RH cabin');

nexttile;
plot(pullDown.PullDownTime_min,pullDown{:,2:4},'LineWidth',2);
xline(30,':','30 min target');
legend({'Effective interior mass, low','central','high'},'Location','northeast');
grid on;
xlabel('Pull-down time (min)'); ylabel('Mean cooling capacity (kW)');
title('Average capacity to pull down 80 C soak to 25 C');
title(layout,'Gap fill 6: cabin workbook audit and heat-balance rebuild (Fayazbakhsh and Bahrami structure)');
exportgraphics(fig,fullfile(outputDir,"gap_cabin_heat_balance.png"),'Resolution',150);
close(fig);
end

function ensure_output_folder(folder)
if ~isfolder(folder)
    mkdir(folder);
end
end

function palette = cabin_palette()
% Nine distinguishable component colours, shared with the cabin module.
palette = [0.12 0.35 0.75;0.55 0.70 0.95;0.90 0.55 0.10;0.55 0.35 0.10; ...
    0.10 0.55 0.35;0.55 0.85 0.65;0.50 0.20 0.70;0.80 0.65 0.95;0.40 0.40 0.45];
end
