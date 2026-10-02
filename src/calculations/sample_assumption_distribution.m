function [values,samples] = sample_assumption_distribution(outputFn,a,register,ids,nSamples)
%SAMPLE_ASSUMPTION_DISTRIBUTION Propagate register ranges to one output.
% Each listed assumption follows a triangular distribution (Low, Central,
% High). Samples come from a Halton low-discrepancy sequence, so the result
% is deterministic: no random seed and no Statistics toolbox are needed.
% Assumptions not listed stay at their central value.

ids = string(ids(:));
u = halton_sequence(nSamples,numel(ids));
samples = zeros(nSamples,numel(ids));
for j = 1:numel(ids)
    row = register(register.ID==ids(j),:);
    if height(row)~=1
        error('EVThermal:UnknownAssumption','Unknown assumption ID: %s',ids(j));
    end
    samples(:,j) = triangular_inverse(u(:,j),row.Low,row.Central,row.High);
end
values = zeros(nSamples,1);
for i = 1:nSamples
    x = a;
    for j = 1:numel(ids)
        x.(char(ids(j))) = samples(i,j);
    end
    values(i) = outputFn(x);
end
end

function u = halton_sequence(n,d)
primes = [2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53];
if d>numel(primes)
    error('EVThermal:TooManyDimensions','At most %d assumptions can be sampled.',numel(primes));
end
u = zeros(n,d);
for j = 1:d
    base = primes(j);
    for i = 1:n
        f = 1;
        r = 0;
        k = i;
        while k>0
            f = f/base;
            r = r+f*mod(k,base);
            k = floor(k/base);
        end
        u(i,j) = r;
    end
end
end

function x = triangular_inverse(u,low,mode,high)
if high<=low
    x = repmat(low,size(u));
    return
end
split = (mode-low)/(high-low);
x = zeros(size(u));
left = u<split;
x(left) = low+sqrt(u(left)*(high-low)*(mode-low));
x(~left) = high-sqrt((1-u(~left))*(high-low)*(high-mode));
end
