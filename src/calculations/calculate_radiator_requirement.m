function results = calculate_radiator_requirement(heat_kW, coolantIn_C, coolantOut_C, airIn_C, airOut_C, airCp_JkgK)
%CALCULATE_RADIATOR_REQUIREMENT First-order LMTD/UA and air-flow requirement.
% The terminal temperature differences define the log-mean temperature
% difference. Required conductance follows UA = Q/LMTD. Air mass flow is
% obtained independently from Q = m_air*cp_air*(Tout-Tin).

heat_kW = heat_kW(:);
n = numel(heat_kW);
coolantIn_C = expand_to_length(coolantIn_C,n,'coolant inlet');
coolantOut_C = expand_to_length(coolantOut_C,n,'coolant outlet');
dT1 = coolantIn_C-airOut_C;
dT2 = coolantOut_C-airIn_C;
if any(dT1<=0 | dT2<=0)
    error('EVThermal:InvalidRadiatorBoundary', ...
        'Both radiator terminal temperature differences must be positive.');
end
lmtd_K = zeros(n,1);
equalTerminal = abs(dT1-dT2)<1e-9;
lmtd_K(equalTerminal) = dT1(equalTerminal);
lmtd_K(~equalTerminal) = (dT1(~equalTerminal)-dT2(~equalTerminal)) ./ ...
    log(dT1(~equalTerminal)./dT2(~equalTerminal));
requiredUA_WK = heat_kW*1000 ./ lmtd_K;
airMassFlow_kgs = heat_kW(:)*1000 / (airCp_JkgK*(airOut_C-airIn_C));
results = table(heat_kW,coolantIn_C,coolantOut_C,lmtd_K,requiredUA_WK,airMassFlow_kgs, ...
    'VariableNames', {'RequiredDuty_kW','CoolantIn_C','CoolantOut_C', ...
    'AssumedLMTD_K','RequiredUA_WK','RequiredAirMassFlow_kgs'});
end

function value = expand_to_length(value,n,label)
value = value(:);
if isscalar(value)
    value = repmat(value,n,1);
elseif numel(value)~=n
    error('EVThermal:InvalidRadiatorBoundary', ...
        '%s temperature must be scalar or match the heat-duty vector.',label);
end
end
