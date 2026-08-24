function validate_table_columns(data,requiredColumns,sourceName)
%VALIDATE_TABLE_COLUMNS Verify the minimum schema before calculation.
missing = setdiff(string(requiredColumns),string(data.Properties.VariableNames));
if ~isempty(missing)
    error('EVThermal:InvalidTableSchema', ...
        '%s is missing required columns: %s',sourceName,strjoin(missing,', '));
end
end
