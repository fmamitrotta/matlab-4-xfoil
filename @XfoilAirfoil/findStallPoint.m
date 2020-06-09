function [alphaStall,clStall] = findStallPoint(obj)
%findStallPoint Find the stall point in the airfoil polar
%   findStallPoint(obj)
% Initialize clStall
clStall = 0;
% Initialize polar index
p = 1;
% Check that polar has at least 2 points
if isempty(obj.Polar) || length(obj.Polar) < 2
    warning(['No first valid point found in the ',...
        'polar. Aborting stall point calculation.'])
    clStall = nan;
    alphaStall = nan;
    return
end
% Get first valid point of the polar
while ~(obj.Polar(p).cl > 0 && obj.Polar(p+1).cl > 0)
    p = p + 1;
    % If no first valid point has been found return a nan
    if p == length(obj.Polar)
        warning(['No first valid point found in the ',...
            'polar. Aborting stall point calculation.'])
        alphaStall = nan;
        return
    end
end
% Evaluate stall angle
while clStall < obj.Polar(p).cl
    clStall = obj.Polar(p).cl;
    p = p + 1;
    if p > length(obj.Polar)
        alphaStall = obj.Polar(p-1).alpha;
        return
    end
end
alphaStall = obj.Polar(p-1).alpha;
end
