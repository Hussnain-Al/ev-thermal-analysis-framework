function resistance_kPa = interpolate_inactive_pump_resistance(curve,flow_Lmin)
%INTERPOLATE_INACTIVE_PUMP_RESISTANCE Digitized passive pump restriction.
% This is not an active pump Q-H curve and must not be added to normal
% active-pump head unless flow is forced through a non-running pump.

% Resolve columns by normalized engineering meaning rather than relying on
% one exact table-variable spelling. MATLAB releases and user-edited CSV
% files can import a header such as "Flow (L/min)" as "Flow_L_min". The
% aliases below accept that harmless naming variation while still rejecting
% a missing or ambiguous schema.
flow = resolve_numeric_column(curve, ...
    ["flowlmin","flowlpm","flowlitermin","flowlitresperminute"], ...
    "coolant flow in L/min");
resistance = resolve_numeric_column(curve, ...
    ["inactivepumpresistancekpa","pumpresistancekpa", ...
     "pressuredropkpa","headlosskpa","resistancekpa"], ...
    "inactive-pump resistance in kPa");

if numel(flow) < 2 || numel(flow) ~= numel(resistance)
    error('EVThermal:InvalidInactivePumpCurve', ...
        'Inactive-pump curve columns must contain the same number of rows (at least two).');
end
if any(~isfinite(flow)) || any(~isfinite(resistance))
    error('EVThermal:InvalidInactivePumpCurve', ...
        'Inactive-pump curve contains missing or nonnumeric values.');
end
if any(diff(flow) <= 0)
    error('EVThermal:InvalidInactivePumpCurve', ...
        'Inactive-pump flow values must be strictly increasing.');
end
if flow_Lmin < min(flow) || flow_Lmin > max(flow)
    error('EVThermal:InactivePumpExtrapolation', ...
        'Requested flow is outside the inactive-pump curve.');
end
resistance_kPa = interp1(flow,resistance,flow_Lmin,'pchip');
end

function values = resolve_numeric_column(data,acceptedKeys,description)
% Convert headers to lower-case alphanumeric keys before alias matching.
names = string(data.Properties.VariableNames);
keys = lower(regexprep(names,'[^A-Za-z0-9]',''));
matches = find(ismember(keys,acceptedKeys));
if numel(matches) ~= 1
    error('EVThermal:InvalidInactivePumpSchema', ...
        ['Could not identify exactly one column for %s. Imported columns: %s. ' ...
         'Use an unambiguous header with the quantity and unit.'], ...
        description,strjoin(names,', '));
end

values = data{:,matches};
if iscell(values) || isstring(values) || ischar(values) || iscategorical(values)
    values = str2double(string(values));
end
if ~isnumeric(values) || ~isvector(values)
    error('EVThermal:InvalidInactivePumpCurve', ...
        'The column for %s must be a numeric vector.',description);
end
values = double(values(:));
end
