%RUN_SANITY_CHECKS Regression, energy-balance and module-boundary checks.
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir,'-begin');
cfg = setup_project();
assert(strcmp(cfg.project.version,"4.5.0"));
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
assert(abs(battery.cellToCoolantResistance_KW-0.304729)<1e-5);
assert(battery.cellToCoolantResistanceRange_KW(2)<battery.superseded.baseResistance_KW);
assert(abs(battery.entropicPeak_VK-0.37e-3)<1e-15);
transientCfg = cfg.motorCooling.transient;
assert(abs(transientCfg.ratedSpeedBasis_rpm-4191.51017)<1e-4);
assert(abs(transientCfg.motorToCoolantResistance_KW-0.033086)<1e-5);
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
assert(abs(batteryRequirements.MaximumCoolantForDischarge_C(1)-52.36872)<1e-4);
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
assert(results.motorCooling.hydraulics.pumpCheck.DocumentedPointCoversModeledHoses);
assert(contains(results.motorCooling.hydraulics.pumpCheck.Conclusion, ...
    "radiator and component losses are excluded"));
assert(height(results.motorCooling.radiatorDesign)==2);
assert(all(results.motorCooling.radiatorDesign.RequiredAirVolumeFlow_m3s>0));
assert(all(results.motorCooling.radiatorDesign.RequiredCoreFaceVelocity_ms>0));
assert(all(results.motorCooling.radiatorDesign.RequiredIdealUA_WK>0));
assert(all(results.motorCooling.radiatorDesign.TemperatureBoundaryFeasible));
assert(~ismember('IdealRamAirUpperBound_m3s', ...
    results.motorCooling.radiatorDesign.Properties.VariableNames));
assert(height(results.motorCooling.radiatorAirsideSensitivity)== ...
    2*numel(cfg.motorCooling.thermal.airTemperatureRiseSensitivity_C));
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
assert(abs(terms.pathResistance_KW-0.3047)<1e-3);
assert(terms.pathResistance_KW<cfg.batteryCooling.superseded.baseResistance_KW);
designCheck = gap.radiatorDesignCheck;
gradeRow = contains(designCheck.Case,"10%");
assert(abs(designCheck.EstimatedFaceVelocityForDuty_ms(gradeRow)-6.2)<0.15);
assert(all(designCheck.EstimatedUAAtRequiredVelocity_WK< ...
    designCheck.SupersededTwoNodeUA_WK));
assert(abs(designCheck.EstimatedCoolantPressureDrop_kPa(1)-0.583)<0.01);
assert(all(gap.motorCalibration.ImpliedWindingToCoolant_KW> ...
    cfg.motorCooling.transient.superseded.motorToCoolantResistance_KW));
assert(isequal(gap.robustness.ClaimHoldsAcrossRange,[true;true;true;false]));
assert(isequal(gap.robustness.ClaimHoldsWithin5to95,[true;true;true;true]));
assert(abs(gap.robustness.CombinedMaximum(1)-1.69607)<1e-4);
assert(abs(gap.robustness.CombinedMaximum(2)-200.590)<0.01);
assert(abs(gap.robustness.CombinedMinimum(4)-3.21884)<1e-4);
% Deterministic Halton 5-95% bands.
assert(abs(gap.robustness.P05(1)-0.262387)<1e-5);
assert(abs(gap.robustness.P95(1)-0.376027)<1e-5);
assert(abs(gap.robustness.P05(2)-125.0465)<1e-3);
assert(abs(gap.robustness.P95(2)-160.5949)<1e-3);
assert(abs(gap.robustness.P05(4)-4.58164)<1e-4);
assert(gap.robustness.P05(4)>cfg.cabinCooling.recoveredCabinDuty_kW);
screen2C = results.batteryCooling.screen(results.batteryCooling.screen.C_rate==2,:);
assert(abs(screen2C.MaximumCoolantForDischarge_C-38.48406)<1e-4);
assert(abs(screen2C.MaximumCoolantForDischargeP05_C-32.27118)<1e-4);
assert(abs(screen2C.MaximumCoolantForDischargeP95_C-41.94481)<1e-4);
screen1C = results.batteryCooling.screen(results.batteryCooling.screen.C_rate==1,:);
assert(abs(screen1C.MaximumCoolantForDischargeP05_C-50.36281)<1e-4);
assert(abs(screen1C.MaximumCoolantForDischargeP95_C-53.52428)<1e-4);

% Two-node peaks quoted in README and CORRECTIONS.md, with the corrected and
% the superseded parameters.
thermal = results.motorCooling.summary;
gradeRow = thermal.Case=="Sustained 10% grade";
lowRow = thermal.Case=="Low-speed hot-weather grade";
assert(abs(thermal.PeakMotorTemperature_C(gradeRow)-98.550)<0.01);
assert(abs(thermal.PeakCoolantTemperature_C(gradeRow)-53.914)<0.01);
assert(abs(thermal.PeakMotorTemperature_C(lowRow)-84.324)<0.01);
supersededParameters = cfg.motorCooling.transient;
supersededParameters.motorToCoolantResistance_KW = ...
    supersededParameters.superseded.motorToCoolantResistance_KW;
supersededParameters.radiatorUA_WK = supersededParameters.superseded.radiatorUA_WK;
oldGrade = simulate_motor_coolant_thermal(results.motorHeat.details{3},45, ...
    supersededParameters);
assert(abs(max(oldGrade.MotorTemperature_C)-81.576)<0.01);
assert(abs(max(oldGrade.CoolantTemperature_C)-48.305)<0.01);
supersededParameters.radiatorUA_WK = supersededParameters.superseded.fanOnlyRadiatorUA_WK;
oldLow = simulate_motor_coolant_thermal(results.motorHeat.details{4},45, ...
    supersededParameters);
assert(abs(max(oldLow.MotorTemperature_C)-70.106)<0.01);
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
assert(abs(discharge.PeakCellTemperature_C(row)-36.78)<0.05);

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
