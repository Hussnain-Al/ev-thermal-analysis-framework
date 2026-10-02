function audit = audit_cabin_workbook(workbookPath,outdoor_C,indoor_C)
%AUDIT_CABIN_WORKBOOK Recompute the recovered surface rows consistently.
% The workbook applies Q = U A SCL to glazing and doors (SCL is a solar
% cooling load in W/m2 and should be multiplied by the shading coefficient,
% not U), copies the east glazing values into the west rows, and adds the
% Fahrenheit CLTD correction (78-ti)+(tm-85) using Celsius temperatures.
% This audit keeps every recorded input and recalculates:
%   glazing: A SC SCL + U A (tm-ti)
%   doors:   U A (tm-ti) (opaque)
%   opaque:  U A [CLTD_F*5/9 + (25.5-ti) + (tm-29.4)]

% readcell keeps blank orientation-header rows, so names and values stay
% aligned row by row.
raw = readcell(workbookPath,'Sheet','Sheet1','Range','A3:I18');
names = strings(size(raw,1),1);
values = nan(size(raw,1),8);
for r = 1:size(raw,1)
    if ischar(raw{r,1}) || isstring(raw{r,1})
        names(r) = string(raw{r,1});
    end
    for c = 2:9
        if isnumeric(raw{r,c}) && isscalar(raw{r,c})
            values(r,c-1) = double(raw{r,c});
        end
    end
end
area = values(:,1);
U = values(:,2);
SC = values(:,3);
SCL = values(:,4);
CLTDI = values(:,7);
recorded_W = values(:,8);

orientation = "";
label = strings(0,1);
recordedOut = zeros(0,1);
recomputed = zeros(0,1);
for i = 1:numel(names)
    if isnan(recorded_W(i))
        orientation = names(i);
        continue
    end
    if contains(names(i),"Window")
        q = area(i)*SC(i)*SCL(i)+U(i)*area(i)*(outdoor_C-indoor_C);
    elseif contains(names(i),"Door")
        q = U(i)*area(i)*(outdoor_C-indoor_C);
    else
        q = U(i)*area(i)*(CLTDI(i)*5/9+(25.5-indoor_C)+(outdoor_C-29.4));
    end
    label(end+1,1) = strtrim(orientation+" "+names(i)); %#ok<AGROW>
    recordedOut(end+1,1) = recorded_W(i); %#ok<AGROW>
    recomputed(end+1,1) = q; %#ok<AGROW>
end
audit = table(label,recordedOut,recomputed,recomputed-recordedOut, ...
    'VariableNames',{'Surface','RecordedInWorkbook_W','Recomputed_W', ...
    'Difference_W'});
end
