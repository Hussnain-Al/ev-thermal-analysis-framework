function [oneAtATime,combined] = evaluate_assumption_sensitivity(outputFn,a,register,ids)
%EVALUATE_ASSUMPTION_SENSITIVITY One-at-a-time and combined-extreme ranges.
% outputFn maps an assumption struct to one scalar output. Each listed
% register row is moved to its Low and High value with all others central.
% The combined extremes then set every row to whichever end raised or
% lowered the output, which bounds the output when it is monotonic in each
% assumption. The pseudo-ID "ORIENTATION" stands the battery cell on its
% narrow face by moving B10 to Low and B12 to High together.

ids = string(ids(:));
central = outputFn(a);
n = numel(ids);
parameter = strings(n,1);
atLow = zeros(n,1);
atHigh = zeros(n,1);
lowStructs = cell(n,1);
highStructs = cell(n,1);
for i = 1:n
    [aLow,aHigh,parameter(i)] = vary(a,register,ids(i));
    lowStructs{i} = aLow;
    highStructs{i} = aHigh;
    atLow(i) = outputFn(aLow);
    atHigh(i) = outputFn(aHigh);
end
oneAtATime = table(ids,parameter,repmat(central,n,1),atLow,atHigh, ...
    'VariableNames',{'Assumption','Parameter','Central','OutputAtLow','OutputAtHigh'});

aMin = a;
aMax = a;
for i = 1:n
    if atHigh(i)>=atLow(i)
        aMax = copy_varied(aMax,highStructs{i},ids(i));
        aMin = copy_varied(aMin,lowStructs{i},ids(i));
    else
        aMax = copy_varied(aMax,lowStructs{i},ids(i));
        aMin = copy_varied(aMin,highStructs{i},ids(i));
    end
end
combined = struct('Central',central,'Minimum',outputFn(aMin), ...
    'Maximum',outputFn(aMax));
end

function [aLow,aHigh,parameter] = vary(a,register,id)
aLow = a;
aHigh = a;
if id=="ORIENTATION"
    rowB10 = register(register.ID=="B10",:);
    rowB12 = register(register.ID=="B12",:);
    aHigh.B10 = rowB10.Low;
    aHigh.B12 = rowB12.High;
    parameter = "Cell standing on its narrow face";
    return
end
row = register(register.ID==id,:);
if height(row)~=1
    error('EVThermal:UnknownAssumption','Unknown assumption ID: %s',id);
end
aLow.(char(id)) = row.Low;
aHigh.(char(id)) = row.High;
parameter = row.Parameter;
end

function target = copy_varied(target,source,id)
if id=="ORIENTATION"
    target.B10 = source.B10;
    target.B12 = source.B12;
else
    target.(char(id)) = source.(char(id));
end
end
