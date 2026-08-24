function f = colebrook_factor(Re, relativeRoughness)
%COLEBROOK_FACTOR Iterative Darcy friction factor.
% Solves 1/sqrt(f) = -2*log10(epsilon/(3.7D)+2.51/(Re*sqrt(f))).
% The fixed-point iteration stops when successive Darcy factors differ by
% less than 1e-10.

f = 0.03;
for iteration = 1:100
    next = 1 / (-2*log10(relativeRoughness/3.7 + 2.51/(Re*sqrt(f))))^2;
    if abs(next-f) < 1e-10
        f = next;
        return;
    end
    f = next;
end
warning('Colebrook iteration reached the iteration limit.');
end
