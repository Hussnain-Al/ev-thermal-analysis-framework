%RUN_SANITY_CHECKS Regression, energy-balance and module-boundary checks.
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir,'-begin');
cfg = setup_project();
assert(strcmp(cfg.project.version,"4.6.0"));
assert(~isfield(cfg,'sharedCompressor'));

% Every active CSV is imported through the deterministic project reader.
csvChecks = { ...
    cfg.cabinCooling.files.loadInputs, ...
        {'LoadComponent','Load_kW','CabinSetpoint_C','InteriorRelativeHumidity_pct','SourceWorkbook','SourceStatus'}, ...
        {'Load_kW','CabinSetpoint_C','InteriorRelativeHumidity_pct'}; ...
    cfg.motorHeat.files.driveEfficiencyMap, ...
        {'Speed_rpm','Torque_Nm','IntegratedEfficiency_pct'}, ...
        {'Speed_rpm','Torque_Nm','IntegratedEfficiency_pct'}; ...
    cfg.motorHeat.files.controllerLossReference, ...
        {'OperatingPoint','OutputPower_kW','TotalControllerLoss_W','IGBTLossPerBridgeArm_W','DiodeLossPerBridgeArm_W','EvidenceStatus'}, ...
        {'OutputPower_kW','TotalControllerLoss_W','IGBTLossPerBridgeArm_W','DiodeLossPerBridgeArm_W'}; ...
    cfg.motorCooling.files.thermalReference, ...
        {'ReferenceCase','CoolantInlet_C','CoolantFlow_Lmin','ReportedWindingTemperature_C','Duration_s','EvidenceStatus'}, ...
        {'CoolantInlet_C','CoolantFlow_Lmin','ReportedWindingTemperature_C','Duration_s'}; ...
    cfg.motorCooling.files.inactivePumpCurve, ...
        {'Flow_Lmin','Flow_Lh','InactivePumpResistance_kPa','DigitizationUncertainty_kPa','EvidenceStatus'}, ...
        {'Flow_Lmin','Flow_Lh','InactivePumpResistance_kPa','DigitizationUncertainty_kPa'}; ...
    cfg.motorCooling.files.radiatorGeometry, ...
        propulsion_radiator_columns(),radiator_numeric_columns(); ...
    cfg.project.parameterRegister, ...
        {'ID','Domain','Parameter','Value','Unit','EvidenceClass','Limitation'}, ...
        {}};
for i = 1:size(csvChecks,1)
    imported = read_project_csv(csvChecks{i,1},csvChecks{i,2},csvChecks{i,3});
    assert(width(imported)==numel(csvChecks{i,2}));
end

% Battery output is sustained and independent of motor or compressor state.
battery = cfg.batteryCooling;
screen = calculate_battery_ohmic_heat([1;2],battery.capacity_Ah, ...
    battery.resistanceProxy_Ohm,battery.seriesCells);
assert(abs(screen.PackHeat_kW(1)-0.7756992)<1e-8);
assert(abs(screen.PackHeat_kW(2)-3.1027968)<1e-8);
% The superseded ACR/3.10 K/W result is still reproduced for comparison.
riseAtOneC = screen.CellHeat_W(1)*battery.superseded.baseResistance_KW;
assert(abs(riseAtOneC-22.26544)<1e-8);
assert(abs((battery.absoluteOperatingLimit_C-riseAtOneC)-37.73456)<1e-8);

% Corrected parameters derived from the literature register.
assert(abs(battery.dcResistance25_Ohm-0.40e-3/0.7)<1e-15);
assert(abs(battery.cellToCoolantResistance_KW-1.033126)<1e-5);
assert(battery.cellToCoolantResistanceRange_KW(2)<battery.superseded.baseResistance_KW);
assert(abs(battery.entropicPeak_VK-0.37e-3)<1e-15);
transientCfg = cfg.motorCooling.transient;
assert(abs(transientCfg.ratedSpeedBasis_rpm-60000/(125*2*pi/60))<1e-9);
assert(abs(transientCfg.motorToCoolantResistance_KW-0.033979)<1e-5);
assert(abs(transientCfg.motorToCoolantResistanceRange_KW(1)-0.030086)<1e-5);
assert(abs(transientCfg.motorToCoolantResistanceRange_KW(2)-0.039027)<1e-5);
assert(cfg.vehicle.reducerEfficiency==0.98);
assert(transientCfg.motorToCoolantResistanceRange_KW(1)> ...
    transientCfg.superseded.motorToCoolantResistance_KW);
assert(abs(transientCfg.radiatorUA_WK-139.678)<0.01);
assert(abs(transientCfg.fanOnlyRadiatorUA_WK-122.337)<0.01);
assert(transientCfg.radiatorUARange_WK(2)<transientCfg.superseded.radiatorUA_WK);
assert(cfg.cabinCooling.ambientRelativeHumidity_pct==44);

batteryRequirements = calculate_battery_requirements_screen([1;2],battery);
assert(abs(batteryRequirements.JouleHeat_W(1)-134^2*0.40e-3/0.7)<1e-10);
assert(abs(batteryRequirements.EntropicHeat_W(1)-134*298.15*0.37e-3)<1e-10);
assert(abs(batteryRequirements.RequiredCellToCoolantRise_C(1)- ...
    batteryRequirements.CellHeat_W(1)*battery.cellToCoolantResistance_KW)<1e-12);
assert(abs(batteryRequirements.MaximumCoolantForDischarge_C(1)-34.12759)<1e-4);
assert(all(batteryRequirements.MaximumCoolantForDischargeP05_C< ...
    batteryRequirements.MaximumCoolantForDischargeP95_C));
assert(numel(battery.uncertainty.cellToCoolantResistance_KW)== ...
    cfg.literatureGapFill.uncertaintySamples);
assert(abs(batteryRequirements.SupersededMaximumCoolantForDischarge_C(1)-37.73456)<1e-8);

% Core coolant transport and hydraulic regressions.
coolant = cfg.motorCooling.coolant;
nominal = coolant(coolant.Temperature_C==40,:);
transport = calculate_coolant_transport([1;2], ...
    cfg.motorCooling.thermal.designFlow_Lmin, ...
    cfg.motorCooling.thermal.hoseID_m, ...
    nominal.Density_kgm3,nominal.Cp_JkgK);
assert(abs(transport.HoseVelocity_ms(1)-1.061032954)<1e-8);

[~,hydraulic] = calculate_cooling_loop_losses( ...
    cfg.motorCooling.loop,20, ...
    coolant.Density_kgm3(coolant.Temperature_C==60), ...
    coolant.Viscosity_Pas(coolant.Temperature_C==60));
assert(abs(hydraulic.HoseAndFittingLoss_kPa-21.980)<0.15);
assert(hydraulic.HoseAndFittingLoss_kPa< ...
    cfg.motorCooling.pump.minimumHead_kPa);
assert(abs(cfg.motorCooling.transient.driveUnitMass_kg-83.5)<1e-12);
assert(abs(cfg.motorCooling.transient.motorThermalCapacity_JK-45000)<1e-8);

% Cabin workbook is the authoritative source for the surface-load subtotal.
surfaceLoads_W = readmatrix(cfg.cabinCooling.files.sourceWorkbook, ...
    'Sheet','Sheet1','Range','I2:I18');
assert(abs(sum(surfaceLoads_W,'omitnan')/1000-3.33594)<1e-8);

% verify_framework calls run_all before this script. When started directly,
% execute the complete workflow before checking integrated outputs.
if ~exist('results','var') || ~isstruct(results) || ...
        ~isfield(results,'cabinCooling')
    results = run_all(cfg); %#ok<NASGU>
end
assert(isfield(results,'motorHeat'));
assert(isfield(results,'motorCooling'));
assert(isfield(results,'batteryCooling'));
assert(isfield(results,'cabinCooling'));
assert(~isfield(results,'sharedCompressor'));
assert(height(results.motorHeat.summary)== ...
    height(cfg.cycles)+height(cfg.motorHeat.operatingCases));
assert(height(results.motorCooling.summary)==height(results.motorHeat.summary));
assert(height(results.batteryCooling.screen)==numel(battery.cRates));
assert(~ismember('EstimatedCellTemperature_C', ...
    results.batteryCooling.screen.Properties.VariableNames));
assert(~ismember('BatteryCoolingRequest_kW', ...
    results.batteryCooling.screen.Properties.VariableNames));
assert(all(abs(results.motorCooling.summary.EnergyBalanceResidual_kWh)<2e-3));
% Supplier component losses (MCU 13 kPa, motor 11 kPa at 16 L/min, OBC curve)
% push the 20 L/min loop past the pump's documented 60 kPa.
pumpCheck = results.motorCooling.hydraulics.pumpCheck;
assert(abs(pumpCheck.SupplierComponentLoss_kPa-49.375)<1e-9);
assert(abs(pumpCheck.LoopLoss_kPa-71.355)<0.15);
assert(~pumpCheck.DocumentedPointCoversLoop);
assert(abs(pumpCheck.FlowAtDocumentedHead_Lmin-18.33)<0.05);
[~,componentAt16] = calculate_component_pressure_drop( ...
    results.motorCooling.hydraulics.componentData,16);
assert(abs(componentAt16-31.6)<1e-12);
assert(height(results.motorCooling.radiatorDesign)==3);
assert(all(results.motorCooling.radiatorDesign.RequiredAirVolumeFlow_m3s>0));
assert(all(results.motorCooling.radiatorDesign.RequiredCoreFaceVelocity_ms>0));
assert(all(results.motorCooling.radiatorDesign.RequiredIdealUA_WK>0));
assert(all(results.motorCooling.radiatorDesign.TemperatureBoundaryFeasible));
assert(~ismember('IdealRamAirUpperBound_m3s', ...
    results.motorCooling.radiatorDesign.Properties.VariableNames));
assert(height(results.motorCooling.radiatorAirsideSensitivity)== ...
    3*numel(cfg.motorCooling.thermal.airTemperatureRiseSensitivity_C));
assert(all(results.motorCooling.radiatorAirsideSensitivity. ...
    RequiredCoreFaceVelocity_ms>0));
assert(all(results.motorCooling.radiatorAirsideSensitivity. ...
    TemperatureBoundaryFeasible));
baselineSensitivity = results.motorCooling.radiatorAirsideSensitivity( ...
    results.motorCooling.radiatorAirsideSensitivity.AirTemperatureRise_C==10,:);
assert(height(baselineSensitivity)==height(results.motorCooling.radiatorDesign));
for i = 1:height(results.motorCooling.radiatorDesign)
    row = baselineSensitivity.Case==results.motorCooling.radiatorDesign.Case(i);
    assert(sum(row)==1);
    assert(abs(baselineSensitivity.RequiredIdealUA_WK(row)- ...
        results.motorCooling.radiatorDesign.RequiredIdealUA_WK(i))<1e-10);
    assert(abs(baselineSensitivity.RequiredCoreFaceVelocity_ms(row)- ...
        results.motorCooling.radiatorDesign.RequiredCoreFaceVelocity_ms(i))<1e-10);
end
assert(results.motorCooling.radiatorCandidate.CoreDepth_mm==26);
assert(results.motorCooling.radiatorCandidate.FlatTubeExternalDepth_mm==2);
assert(results.motorCooling.radiatorCandidate.AssumedTubeWallThickness_mm==0.2);
assert(results.motorCooling.radiatorCandidate.AssumedFinThickness_mm==0.1);
assert(results.motorHeat.controllerLossReference.TotalControllerLoss_W(1)==1580);
assert(results.motorHeat.controllerLossReference.TotalControllerLoss_W(2)==3218);
assert(all(results.motorHeat.summary.MaximumTrailing60sHeat_kW<= ...
    results.motorHeat.summary.PeakOneSecondDriveUnitHeat_kW+1e-12));
assert(abs(results.cabinCooling.summary.WorkbookBodyAndGlazingLoad_kW- ...
    3.33594)<1e-8);

% Literature gap-fill layer: register integrity and regression values.
[lit,register] = read_literature_assumptions( ...
    cfg.literatureGapFill.files.assumptionRegister);
assert(all(register.Low<=register.Central & register.Central<=register.High));
assert(all(strlength(register.Source)>0));
gap = results.literatureGapFill;
terms = gap.batteryTerms;
assert(abs(terms.dcir25_Ohm-0.40e-3/lit.B01)<1e-12);
assert(abs(terms.pathResistance_KW-1.0331)<1e-3);
assert(terms.pathResistance_KW<cfg.batteryCooling.superseded.baseResistance_KW);
designCheck = gap.radiatorDesignCheck;
gradeRow = contains(designCheck.Case,"10%");
assert(abs(designCheck.EstimatedFaceVelocityForDuty_ms(gradeRow)-6.721)<0.01);
withinMap = ~isnan(designCheck.EstimatedUAAtRequiredVelocity_WK);
assert(all(designCheck.EstimatedUAAtRequiredVelocity_WK(withinMap)< ...
    designCheck.SupersededTwoNodeUA_WK(withinMap)));
assert(abs(designCheck.EstimatedCoolantPressureDrop_kPa(1)-0.583)<0.01);
assert(all(gap.motorCalibration.ImpliedWindingToCoolant_KW> ...
    cfg.motorCooling.transient.superseded.motorToCoolantResistance_KW));
assert(isequal(gap.robustness.ClaimHoldsAcrossRange,[true;true;true;false]));
assert(isequal(gap.robustness.ClaimHoldsWithin5to95,[true;true;true;true]));
assert(abs(gap.robustness.CombinedMaximum(1)-2.302559)<1e-5);
assert(abs(gap.robustness.CombinedMaximum(2)-200.590)<0.01);
assert(abs(gap.robustness.CombinedMinimum(4)-3.21884)<1e-4);
% Deterministic Halton 5-95% bands.
assert(abs(gap.robustness.P05(1)-0.777107)<1e-5);
assert(abs(gap.robustness.P95(1)-1.261279)<1e-5);
assert(abs(gap.robustness.P05(2)-125.0465)<1e-3);
assert(abs(gap.robustness.P95(2)-160.5949)<1e-3);
assert(abs(gap.robustness.P05(4)-4.58164)<1e-4);
assert(gap.robustness.P05(4)>cfg.cabinCooling.recoveredCabinDuty_kW);
screen2C = results.batteryCooling.screen(results.batteryCooling.screen.C_rate==2,:);
assert(abs(screen2C.MaximumCoolantForDischarge_C+12.94574)<1e-4);
assert(abs(screen2C.MaximumCoolantForDischargeP05_C+31.71208)<1e-4);
assert(abs(screen2C.MaximumCoolantForDischargeP95_C-5.28775)<1e-4);
screen1C = results.batteryCooling.screen(results.batteryCooling.screen.C_rate==1,:);
assert(abs(screen1C.MaximumCoolantForDischargeP05_C-27.94527)<1e-4);
assert(abs(screen1C.MaximumCoolantForDischargeP95_C-40.35662)<1e-4);

% Two-node peaks quoted in README and CORRECTIONS.md, with the corrected and
% the superseded parameters.
thermal = results.motorCooling.summary;
gradeRow = thermal.Case=="Sustained 10% grade";
lowRow = thermal.Case=="Low-speed hot-weather grade";
assert(abs(thermal.PeakMotorTemperature_C(gradeRow)-100.286)<0.01);
assert(abs(thermal.PeakCoolantTemperature_C(gradeRow)-53.996)<0.01);
assert(abs(thermal.PeakMotorTemperature_C(lowRow)-85.359)<0.01);
l6Row = thermal.Case=="Project L6: 8% continuous grade, full load";
assert(abs(thermal.PeakMotorTemperature_C(l6Row)-120.241)<0.01);
supersededParameters = cfg.motorCooling.transient;
supersededParameters.motorToCoolantResistance_KW = ...
    supersededParameters.superseded.motorToCoolantResistance_KW;
supersededParameters.radiatorUA_WK = supersededParameters.superseded.radiatorUA_WK;
oldGrade = simulate_motor_coolant_thermal(results.motorHeat.details{3},45, ...
    supersededParameters);
assert(abs(max(oldGrade.MotorTemperature_C)-82.509)<0.01);
assert(abs(max(oldGrade.CoolantTemperature_C)-48.389)<0.01);
supersededParameters.radiatorUA_WK = supersededParameters.superseded.fanOnlyRadiatorUA_WK;
oldLow = simulate_motor_coolant_thermal(results.motorHeat.details{4},45, ...
    supersededParameters);
assert(abs(max(oldLow.MotorTemperature_C)-70.537)<0.01);
assert(abs(results.cabinCooling.summary.CorrectedWorkbookSubtotal_kW- ...
    (1.871665+0.594+0.226))<1e-4);
assert(abs(results.cabinCooling.summary.HeatBalanceHumidHeat_kW-5.19253)<1e-4);
assert(abs(sum(gap.cabinAudit.RecordedInWorkbook_W)-3335.94)<0.01);
assert(abs(sum(gap.cabinAudit.Recomputed_W)-1871.67)<0.1);
humid = gap.cabinHeatBalance.Scenario==cfg.literatureGapFill.cabin.scenarioNames(end);
assert(abs(sum(gap.cabinHeatBalance.Load_kW(humid))-5.193)<0.01);
discharge = gap.batteryTransientSummary;
row = discharge.C_rate==2 & discharge.Coolant_C==25 & ...
    abs(discharge.PathResistance_KW-terms.pathResistance_KW)<1e-12;
assert(abs(discharge.PeakCellTemperature_C(row)-43.8140)<0.01);

% Drive-cycle battery heat: expected and highest-possible values, and the
% cycle selection interface.
cycleHeat = results.batteryCooling.cycleHeat.summary;
assert(height(cycleHeat)==numel(results.motorHeat.fileStems));
gradeHeat = cycleHeat(cycleHeat.FileStem=="sustained_grade",:);
assert(abs(gradeHeat.MeanBatteryHeat_kW-0.665362)<1e-5);
assert(abs(gradeHeat.MeanBatteryHeatUpperBound_kW-2.058102)<1e-5);
assert(abs(gradeHeat.FinalSOC_pct-65.64439)<1e-4);
assert(abs(gradeHeat.MeanCombinedHeat_kW-3.504776)<1e-5);
highwayHeat = cycleHeat(cycleHeat.FileStem=="highway_cycle",:);
assert(abs(highwayHeat.MeanBatteryHeat_kW-0.290523)<1e-5);
assert(abs(highwayHeat.MaxTrailing60sBatteryHeat_kW-0.515510)<1e-5);
urbanHeat = cycleHeat(cycleHeat.FileStem=="urban_cycle",:);
assert(abs(urbanHeat.MeanCombinedHeat_kW-0.885777)<1e-5);
l6Heat = cycleHeat(cycleHeat.FileStem=="project_l6_continuous_grade",:);
assert(abs(l6Heat.MeanDriveUnitHeat_kW-3.864308)<1e-5);
assert(abs(l6Heat.MeanBatteryHeat_kW-2.556141)<1e-5);
assert(abs(l6Heat.MeanBatteryHeatUpperBound_kW-6.420053)<1e-5);

% Supplier and specification reference checks.
checks = gap.referenceChecks;
assert(abs(checks.ModelValue(1)-69.2731)<1e-3);
assert(abs(checks.ReferenceValue(2)-9.7954)<1e-3);
assert(abs(checks.ModelValue(3)-2.1418)<1e-3);
assert(abs(checks.ModelValue(4)-0.9868)<1e-3);
assert(checks.ModelValue(5)>checks.ReferenceValue(5));
assert(checks.ReferenceValue(5)==2.9);
assert(abs(checks.ModelValue(6)-57.2428)<1e-3);
assert(abs(checks.ModelValue(7)+12.94574)<1e-4);
assert(abs(checks.ReferenceValue(7)+36.7)<1e-12);
% Cell resistance against the SVOLT pulse-power ceiling and the GFL test.
assert(abs(checks.ReferenceValue(8)-1000*(3.29-2.5)/(1456/2.5))<1e-9);
assert(checks.ModelValue(8)<checks.ReferenceValue(8));
assert(abs(checks.ReferenceValue(9)-0.039/50*100/134*1000)<1e-9);
assert(abs(checks.ModelValue(9)/checks.ReferenceValue(9)-1)<0.02);
% Compressor sizing: cabin (humid heat) plus battery chiller at the DM18A1
% rating condition. The design scenario is L6 with the expected battery heat.
sizing = results.compressorSizing;
assert(abs(sizing.designCapacity_kW-(5.19253+2.556141))<2e-4);
assert(contains(sizing.sizing.Scenario(1),"L6"));
assert(abs(sizing.sizing.DisplacementAt6000rpm_cc(1)-18*sizing.designCapacity_kW/2.9)<1e-9);
assert(abs(sizing.sizing.DisplacementAt6000rpm_cc(1)-48.095)<0.01);
assert(abs(sizing.sizing.DisplacementAtAlternativeSpeed_cc(1)-36.071)<0.01);
assert(abs(sizing.sizing.RequiredCapacity_kW(2)-(gap.robustness.P95(4)+2.556141))<1e-5);
assert(abs(sizing.sizing.RequiredCapacity_kW(3)-(5.19253+6.420053))<2e-4);
pullRow = contains(sizing.scenarios.Scenario,"pull-down");
assert(abs(sizing.scenarios.PullDownExtra_kW(pullRow)-40*55/1800)<1e-9);
assert(all(sizing.scenarios.RequiredCapacity_kW>2.9));
% Reducer loss is reported and kept out of the coolant heat.
assert(all(results.motorHeat.summary.AverageReducerLoss_kW>0));
assert(all(cycleHeat.MeanBatteryHeatUpperBound_kW>=cycleHeat.MeanBatteryHeat_kW));
for k = 1:numel(results.batteryCooling.cycleHeat.traces)
    trace = results.batteryCooling.cycleHeat.traces{k};
    assert(all(trace.BatteryHeatUpperBound_kW>=trace.BatteryHeat_kW-1e-12));
end
selectionCfg = cfg;
selectionCfg.project.outputDir = string(tempname);
single = run_battery_cycle_heat(selectionCfg,results.motorHeat,"highway_cycle");
assert(height(single.summary)==1 && single.summary.FileStem=="highway_cycle");
assert(abs(single.summary.MeanBatteryHeat_kW-highwayHeat.MeanBatteryHeat_kW)<1e-12);
try
    run_battery_cycle_heat(selectionCfg,results.motorHeat,"no_such_cycle");
    error('EVThermal:TestFailed','Unknown cycle names must be rejected.');
catch err
    assert(strcmp(err.identifier,'EVThermal:UnknownCycle'));
end
rmdir(selectionCfg.project.outputDir,'s');

fprintf('All simplified EV thermal framework checks passed.\n');

function names = radiator_numeric_columns()
names = {'CoreHeight_mm','CoreWidth_mm','CoreDepth_mm','FrontalArea_m2', ...
    'FlatTubeExternalWidth_mm','FlatTubeExternalDepth_mm', ...
    'AssumedTubeWallThickness_mm','TubeQuantity','TubeLength_mm', ...
    'FinWidth_mm','FinHeight_mm','FinPitch_mm','AssumedFinThickness_mm', ...
    'FinQuantity','FinLength_mm'};
end

function names = propulsion_radiator_columns()
names = {'Radiator','Application','CoreHeight_mm','CoreWidth_mm', ...
    'CoreDepth_mm','FrontalArea_m2','FlatTubeExternalWidth_mm', ...
    'FlatTubeExternalDepth_mm','AssumedTubeWallThickness_mm', ...
    'TubeQuantity','TubeLength_mm','FinWidth_mm','FinHeight_mm', ...
    'FinPitch_mm','AssumedFinThickness_mm','FinQuantity','FinLength_mm', ...
    'GeometryUse'};
end
