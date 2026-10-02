function [values,register] = read_literature_assumptions(filePath)
%READ_LITERATURE_ASSUMPTIONS Import the literature-assumption register.
% Returns a struct whose fields are register IDs holding the central value,
% plus the full validated register table for traceability.

register = read_project_csv(filePath, ...
    {'ID','Domain','Parameter','Central','Low','High','Unit', ...
     'EvidenceClass','Source','Replaces'}, ...
    {'Central','Low','High'});
if numel(unique(register.ID))~=height(register)
    error('EVThermal:DuplicateAssumption', ...
        'Literature assumption IDs must be unique.');
end
if any(register.Low>register.Central | register.Central>register.High)
    error('EVThermal:InvalidAssumptionRange', ...
        'Each literature assumption must satisfy Low <= Central <= High.');
end
values = struct();
for i = 1:height(register)
    values.(char(register.ID(i))) = register.Central(i);
end
end
