function cfg = apply_literature_corrections(cfg)
%APPLY_LITERATURE_CORRECTIONS Replace superseded assumptions with derived values.
% Each corrected parameter is derived from project evidence plus the sourced
% literature register, and carries a range from the register's low/high
% values. The superseded values stay in the domain configs under
% `superseded` so every result can be compared with what it replaced.

[a,register] = read_literature_assumptions( ...
    cfg.literatureGapFill.files.assumptionRegister);
curves = load_propulsion_curves(cfg.motorHeat.files.driveLimitWorkbook, ...
    cfg.motorHeat.files.driveEfficiencyMap);
geometry = read_radiator_geometry(cfg.motorCooling.files.radiatorGeometry);
d = derive_corrected_parameters(cfg,a,curves,geometry);

cfg.literature.values = a;
cfg.literature.register = register;

% Battery: DC resistance, peak entropic heat and cell-to-coolant path.
battery = cfg.batteryCooling;
battery.dcResistance25_Ohm = d.dcResistance25_Ohm;
ratio = register(register.ID=="B01",:);
battery.dcResistance25Range_Ohm = battery.resistanceProxy_Ohm./[ratio.High ratio.Low];
battery.entropicPeak_VK = d.batteryTerms.peakDischargeEntropic_VK;
battery.entropicReferenceTemperature_C = 25;
battery.entropicSOC_pct = cfg.literatureGapFill.battery.entropicSOC_pct;
battery.entropic_mVK = cfg.literatureGapFill.battery.entropic_mVK;
battery.cellToCoolantResistance_KW = d.cellToCoolantResistance_KW;
pathFn = @(x) derive_path(cfg,x);
[~,pathRange] = evaluate_assumption_sensitivity(pathFn,a,register, ...
    battery_path_ids());
battery.cellToCoolantResistanceRange_KW = [pathRange.Minimum pathRange.Maximum];
% Joint samples of DC resistance and path for the 5-95% band. Orientation
% is a drawing question, not a statistical one, so it stays at the listed
% orientation here and appears only in the worst-case range above.
nSamples = cfg.literatureGapFill.uncertaintySamples;
[~,samples] = sample_assumption_distribution(@(x) 0,a,register, ...
    ["B01";"B13";"B14";"B15";"B16";"B17";"B18";"B19";"B22";"B23"],nSamples);
battery.uncertainty.dcResistance25_Ohm = battery.resistanceProxy_Ohm./samples(:,1);
battery.uncertainty.cellToCoolantResistance_KW = zeros(nSamples,1);
ids = ["B13";"B14";"B15";"B16";"B17";"B18";"B19";"B22";"B23"];
for i = 1:nSamples
    x = a;
    for j = 1:numel(ids)
        x.(char(ids(j))) = samples(i,j+1);
    end
    battery.uncertainty.cellToCoolantResistance_KW(i) = derive_path(cfg,x);
end
battery.modelBoundary = ...
    "Sustained screen: 25 C DC resistance plus peak (low-SOC) entropic heat across the literature cell-to-coolant path";
cfg.batteryCooling = battery;

% Drive unit: winding resistance calibrated on the supplier rated point and
% radiator UA from the candidate core geometry.
transient = cfg.motorCooling.transient;
transient.motorToCoolantResistance_KW = d.motorToCoolantResistance_KW;
transient.ratedSpeedBasis_rpm = d.baseSpeed_rpm;
sweep = cfg.literatureGapFill.motor.ratedSpeedSweep_rpm;
rise = cfg.literatureGapFill.motor.referenceWinding_C- ...
    cfg.literatureGapFill.motor.referenceCoolant_C;
controller = register(register.ID=="M02",:);
lowLoss = calibrate_winding_resistance(curves,sweep,a.M01,controller.Low,rise);
highLoss = calibrate_winding_resistance(curves,sweep,a.M01,controller.High,rise);
allR = [lowLoss.ImpliedWindingToCoolant_KW;highLoss.ImpliedWindingToCoolant_KW];
transient.motorToCoolantResistanceRange_KW = [min(allR) max(allR)];

transient.radiatorUA_WK = d.radiatorUA_WK;
transient.fanOnlyRadiatorUA_WK = d.fanOnlyRadiatorUA_WK;
[~,uaRange] = evaluate_assumption_sensitivity( ...
    @(x) field_of(derive_corrected_parameters(cfg,x,curves,geometry),'radiatorUA_WK'), ...
    a,register,radiator_ids("R09"));
transient.radiatorUARange_WK = [uaRange.Minimum uaRange.Maximum];
[~,fanRange] = evaluate_assumption_sensitivity( ...
    @(x) field_of(derive_corrected_parameters(cfg,x,curves,geometry),'fanOnlyRadiatorUA_WK'), ...
    a,register,radiator_ids("R10"));
transient.fanOnlyRadiatorUARange_WK = [fanRange.Minimum fanRange.Maximum];
transient.modelBoundary = ...
    "Two-node screen: winding resistance calibrated on the supplier rated point, radiator UA estimated for the candidate core; thermal capacitances remain assumptions";
cfg.motorCooling.transient = transient;

% Cabin: replace the physically impossible 45 C / 70% RH pairing.
cfg.cabinCooling.ambientRelativeHumidity_pct = a.K02;
end

function value = derive_path(cfg,a)
terms = calculate_battery_literature_terms(cfg.batteryCooling, ...
    cfg.literatureGapFill.battery,a);
value = terms.pathResistance_KW;
end

function value = field_of(s,name)
value = s.(name);
end

function ids = battery_path_ids()
ids = ["ORIENTATION";"B13";"B14";"B15";"B16";"B17";"B18";"B19";"B22";"B23"];
end

function ids = radiator_ids(velocityId)
ids = [velocityId;"R01";"R02";"R03";"R04";"R05";"R06";"R11"];
end
