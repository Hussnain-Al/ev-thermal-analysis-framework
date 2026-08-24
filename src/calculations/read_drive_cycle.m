function cycle = read_drive_cycle(filePath, cycleName)
%READ_DRIVE_CYCLE Read a two-column time/speed trace with text headers.

fid = fopen(filePath,'r');
if fid < 0
    error('EVThermal:DriveCycleFile','Cannot open %s.',filePath);
end
cleanup = onCleanup(@() fclose(fid));

time_s = [];
speed_mph = [];
while ~feof(fid)
    line = fgetl(fid);
    values = sscanf(line,'%f%f');
    if numel(values) == 2
        time_s(end+1,1) = values(1); %#ok<AGROW>
        speed_mph(end+1,1) = values(2); %#ok<AGROW>
    end
end

if numel(time_s) < 2 || any(diff(time_s) <= 0)
    error('EVThermal:DriveCycleFormat','Invalid time/speed trace in %s.',filePath);
end

cycle = table(repmat(string(cycleName),numel(time_s),1),time_s,speed_mph, ...
    speed_mph*0.44704, ...
    'VariableNames',{'Cycle','Time_s','Speed_mph','Speed_ms'});
end
