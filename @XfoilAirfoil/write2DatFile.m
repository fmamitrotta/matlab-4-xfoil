function write2DatFile(obj,coordinatesFilepath)
%write2DatFile Write airfoil's coordinates to a .dat file
%   write2DatFile(obj,coordinatesFilepath)
% Get the airfoil coordinates in the XFOIL template
coordinateArray = obj.getXfoilStyleCoordinates;
% Write the data to file
fileID = fopen(coordinatesFilepath, 'w');
fprintf(fileID, '%s\n', obj.Name);
fprintf(fileID, '%.7f %.7f\n', coordinateArray');
fclose(fileID);
end
