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
% Proportional correction toward each set point (numerical choice; it
% sets how tightly the set points are held, not the capacity).
sys.controllerGain_WK = 1000;
% Every cycle is repeated to fill the window, so a 30-minute pull-down and
% a sustained duty are both visible.
sys.duration_s = 1800;
sys.comfortBand_C = 2;
% Front-end check: condenser air temperature rise used to size its air flow.
sys.condenserAirRise_C = 15;
sys.cycles = ["urban_cycle";"highway_cycle";"sustained_grade"; ...
    "low_speed_hot_weather";"project_l6_continuous_grade"];
sys.modelBoundary = ...
    "Lumped cabin, pack and battery-coolant nodes sharing rated compressor capacity; no refrigerant circuit";
end
