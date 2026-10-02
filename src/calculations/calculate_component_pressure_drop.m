function [perComponent,total_kPa] = calculate_component_pressure_drop(data,flow_Lmin)
%CALCULATE_COMPONENT_PRESSURE_DROP Supplier component losses at one flow.
% A component with a measured curve is interpolated inside the curve. Outside
% it, and for a component with a single test point, the loss is scaled with
% flow squared from the nearest measured point. The supplier OBC curve rises
% with flow to the power of about 2.05 between 10 and 16 L/min, which
% supports the square law. Supplier points are not corrected for coolant
% temperature.

names = unique(data.Component,'stable');
loss_kPa = zeros(numel(names),1);
for i = 1:numel(names)
    rows = data(data.Component==names(i),:);
    rows = sortrows(rows,'Flow_Lmin');
    q = rows.Flow_Lmin;
    dp = rows.PressureDrop_kPa;
    if numel(q)>1 && flow_Lmin>=q(1) && flow_Lmin<=q(end)
        loss_kPa(i) = interp1(q,dp,flow_Lmin,'linear');
    elseif flow_Lmin<q(1)
        loss_kPa(i) = dp(1)*(flow_Lmin/q(1))^2;
    else
        loss_kPa(i) = dp(end)*(flow_Lmin/q(end))^2;
    end
end
perComponent = table(names,repmat(flow_Lmin,numel(names),1),loss_kPa, ...
    'VariableNames',{'Component','Flow_Lmin','PressureDrop_kPa'});
total_kPa = sum(loss_kPa);
end
