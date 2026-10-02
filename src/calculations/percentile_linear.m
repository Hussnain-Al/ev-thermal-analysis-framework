function q = percentile_linear(values,percent)
%PERCENTILE_LINEAR Percentiles with linear interpolation (numpy default).
% Base MATLAB has no prctile, which needs the Statistics toolbox.

v = sort(values(:));
n = numel(v);
position = percent(:)/100*(n-1)+1;
lower = floor(position);
upper = min(lower+1,n);
weight = position-lower;
q = v(lower).*(1-weight)+v(upper).*weight;
end
