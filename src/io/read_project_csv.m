function data = read_project_csv(filePath,requiredColumns,numericColumns)
%READ_PROJECT_CSV Import a framework CSV with an explicit, validated schema.
% MATLAB's automatic delimiter detection can interpret descriptive text as
% whitespace-delimited data. Framework CSV files are always comma-delimited,
% use their first row as column names, and preserve those names exactly.

if ~isfile(filePath)
    error('EVThermal:MissingInputFile', ...
        'Required CSV input file not found: %s',filePath);
end

requiredColumns = string(requiredColumns(:)');
if nargin < 3
    numericColumns = strings(1,0);
else
    numericColumns = string(numericColumns(:)');
end
unknownNumericColumns = setdiff(numericColumns,requiredColumns);
if ~isempty(unknownNumericColumns)
    error('EVThermal:InvalidCSVSchemaDefinition', ...
        'Numeric columns are absent from the required schema: %s', ...
        strjoin(unknownNumericColumns,', '));
end

data = readtable(filePath, ...
    'FileType','text', ...
    'Delimiter',',', ...
    'ExpectedNumVariables',numel(requiredColumns), ...
    'VariableNamesLine',1, ...
    'ReadVariableNames',true, ...
    'VariableNamingRule','preserve', ...
    'TextType','string');

actualColumns = string(data.Properties.VariableNames);
if width(data) ~= numel(requiredColumns)
    error('EVThermal:InvalidCSVColumnCount', ...
        ['%s must contain exactly %d comma-delimited columns but MATLAB ' ...
         'imported %d. Imported columns: %s'], ...
        filePath,numel(requiredColumns),width(data),strjoin(actualColumns,', '));
end

validate_table_columns(data,requiredColumns,filePath);
if height(data) < 1
    error('EVThermal:EmptyCSVInput', ...
        'CSV input contains a header but no data rows: %s',filePath);
end

% Enforce numeric interfaces after import. This avoids calculations
% receiving text merely because one CSV row contains a missing value.
for i = 1:numel(numericColumns)
    name = numericColumns(i);
    values = data.(char(name));
    if isnumeric(values)
        converted = double(values);
    else
        raw = strtrim(string(values));
        converted = str2double(raw);
        invalid = isnan(converted) & ~ismissing(raw) & raw ~= "" & ...
            lower(raw) ~= "nan";
        if any(invalid)
            firstBadRow = find(invalid,1,'first');
            error('EVThermal:InvalidCSVNumericValue', ...
                '%s contains a nonnumeric value in column %s at data row %d: %s', ...
                filePath,name,firstBadRow,raw(firstBadRow));
        end
    end
    data.(char(name)) = converted;
end
end
