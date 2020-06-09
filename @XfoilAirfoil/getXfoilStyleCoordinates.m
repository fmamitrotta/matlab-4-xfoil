function coordinateArray = getXfoilStyleCoordinates(obj)
%xfoilStyleCoordinateArray Get airfoil's coordinates in Xfoil style
%   xfoilStyleCoordinateArray = xfoilStyleCoordinates(obj)
% If first top y/c is equal to first bottom y/c, then assemble
% in a way not to have a duplicate point
if obj.Ycu(1) == obj.Ycl(1)
    xc = [fliplr(obj.Xc), obj.Xc(2:end)];
    yc = [fliplr(obj.Ycu), obj.Ycl(2:end)];
else
    % Otherwise assemble the two vectors normally
    xc = [fliplr(obj.Xc), obj.Xc];
    yc = [fliplr(obj.Ycu), obj.Ycl];
end
% Assemble the final array
coordinateArray = [xc', yc'];
end
