function d = derive_corrected_parameters(cfg,a,curves,geometry)
%DERIVE_CORRECTED_PARAMETERS Model parameters implied by one assumption set.
% Returns the battery DC resistance and cell-to-coolant path, the winding-
% to-coolant resistance calibrated at the supplier rated point, and the
% estimated radiator UA at the normal-driving and fan-only face velocities.
% The same function serves the central values and the sensitivity ranges.

battery = cfg.batteryCooling;
terms = calculate_battery_literature_terms(battery,cfg.literatureGapFill.battery,a);
d.batteryTerms = terms;
d.dcResistance25_Ohm = terms.dcir25_Ohm;
d.cellToCoolantResistance_KW = terms.pathResistance_KW;

% Rated point from the supplier sheet: 60 kW at 125 Nm rated torque, so the
% rated speed is P/T (4584 rpm). The 143 C winding reference is at this point.
g = cfg.literatureGapFill.motor;
d.ratedSpeed_rpm = a.M01*1000/(g.ratedTorque_Nm*2*pi/60);
calibration = calibrate_winding_resistance(curves,d.ratedSpeed_rpm,a.M01,a.M02, ...
    g.referenceWinding_C-g.referenceCoolant_C);
d.motorToCoolantResistance_KW = calibration.ImpliedWindingToCoolant_KW;

thermal = cfg.motorCooling.thermal;
coolant = cfg.motorCooling.coolant;
coolantRow = coolant(coolant.Temperature_C==thermal.propertyTemperature_C,:);
radiator = calculate_louvered_radiator_performance([a.R09;a.R10], ...
    thermal.designFlow_Lmin,geometry,coolantRow, ...
    thermal.radiatorCoolantIn_C,thermal.airIn_C,a);
d.radiatorUA_WK = radiator.EstimatedUA_WK(1);
d.fanOnlyRadiatorUA_WK = radiator.EstimatedUA_WK(2);
end
