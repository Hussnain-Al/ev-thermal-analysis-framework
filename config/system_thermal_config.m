function sys = system_thermal_config(rootDir)
%SYSTEM_THERMAL_CONFIG Coupled cabin, battery and compressor dynamic screen.
% The cabin and battery loops share the compressor; the propulsion loop has
% its own radiator and is reported alongside on the same drive cycle.

arguments
    rootDir (1,1) string %#ok<INUSA>
end

% Hot-soak start on the 45 C design day: cabin at the project hot-soak
% temperature (register C26), pack and battery coolant at ambient.
sys.packInitial_C = 45;
sys.batteryCoolantInitial_C = 45;
sys.cabinSetpoint_C = 25;
% Archived project battery configuration: 30 C coolant.
sys.batteryCoolantSetpoint_C = 30;
% Controls. PI gains are not set here: run_system_thermal derives them by
% lambda (IMC) tuning from each loop's own plant, so only the desired
% closed-loop time constants are chosen.
sys.control.cabinLambda_s = 60;
sys.control.batteryLambda_s = 60;
% Cascade: an outer proportional loop on cell temperature lowers the battery
% coolant set point below its 30 C nominal when the cells pass the target,
% down to a floor. The floor is 20 C: the 45 C / 44% RH design day has a
% 30 C dew point, so colder coolant risks condensation in an unsealed pack.
sys.control.cellTarget_C = 40;
sys.control.cascadeGain_KK = 2;
sys.control.coolantSetpointFloor_C = 20;
% Compressor priority: the battery chiller is served first from 50 C cell
% (5 K under the 55 C charge cut-off) until the cells fall to 48 C.
sys.control.priorityOn_C = 50;
sys.control.priorityOff_C = 48;
% Derating with margins under the SVOLT limits (60 C operating, 55 C
% charge): full power up to the first value, zero at the second.
sys.control.dischargeDerate_C = [50 58];
sys.control.chargeDerate_C = [45 53];
% Motor: full torque to the 150 C hot-spot target, zero at 170 C (class H
% insulation is 180 C).
sys.control.motorDerate_C = [150 170];
% Every cycle is repeated to fill the window, so a 30-minute pull-down and
% a sustained duty are both visible.
sys.duration_s = 1800;
sys.comfortBand_C = 2;
% Front-end check: condenser air temperature rise used to size its air flow.
sys.condenserAirRise_C = 15;
sys.cycles = ["urban_cycle";"highway_cycle";"sustained_grade"; ...
    "low_speed_hot_weather";"project_l6_continuous_grade"];
sys.modelBoundary = ...
    "Five lumped nodes with PI thermal-management control, compressor priority and BMS and motor derating; compressor is a rated capacity, no refrigerant circuit";
end
