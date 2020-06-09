function [alpha,cl,cdrag,cdp,cm,topXtr,botXtr] = oper(obj,parameterType,...
    parameterValue)
%OPER Calculate integral values for a given angle of attack or lift
%coefficient
%   [alpha,cl,cdrag,cdp,cm,topXtr,botXtr] =
%   oper(obj,parameterType,parameterValue)
% Define files names and paths
matlabValidAirfoilName = matlab.lang.makeValidName(obj.Name);
coordinatesFilename = [matlabValidAirfoilName,'.dat'];
coordinatesFilepath = [cd,filesep,matlabValidAirfoilName,'.dat'];
runFilepath = [cd,filesep,matlabValidAirfoilName,'_run.txt'];
polarFilename = [matlabValidAirfoilName,'.polar'];
polarFilepath = [cd,filesep,matlabValidAirfoilName,'.polar'];
% Purge folder from previous polar file
[~,~] = dos(['del ',polarFilepath]);
% Save current directory name
currentDirectory = cd;
% If airfoil is not a NACA airfoil then create coordinates
% file and check the airfoil quality in XFOIL
if ~strcmpi(obj.Type,'naca')
    obj.write2DatFile(coordinatesFilepath);
    % Open the file with write permission
    runFileID = fopen(runFilepath, 'w');
    % Disable plotting option
    fprintf(runFileID,'PLOP\ng\n\n');
    % Load the airfoil coordinates file
    fprintf(runFileID,'LOAD %s\n',coordinatesFilename);
    % Quit Program
    fprintf(runFileID,'QUIT\n');
    fclose(runFileID);
    % Check that XFOIL does not give a warning (poor
    % airfoil definition)
    [~,result] = dos([currentDirectory(1:2),' && cd ',cd,...
        ' && xfoil.exe',' < ',runFilepath]);
    if isempty(obj.NPanels) && contains(result,...
            'WARNING: Poor input coordinate distribution')
        % If XFOIL gives a warning do not calculate any polar
        % and return
        warning(['Poor input coordinate distribution for ',...
            'XFOIL. Polar calculation aborted.'])
        obj.PolarProxy = [];
        return
    end
end
% Create final run file
% Open the file with write permission
runFileID = fopen(runFilepath,'w');
if strcmpi(obj.Type,'NACA')
    % Load NACA airfoil
    fprintf(runFileID,'NACA %s\n',obj.Digit);
else
    % Load the airfoil coordinates file
    fprintf(runFileID,'LOAD %s\n',coordinatesFilename);
end
% Disable plotting option
fprintf(runFileID,'PLOP\ng\n\n');
% Set flap if specified
if ~isempty(obj.FlapHingeLocation)
    fprintf(runFileID,'GDES\nFlap\n%.2f\n%.2f\n%.1f\n\n',...
        obj.FlapHingeLocation(1),obj.FlapHingeLocation(2),...
        obj.FlapDeflection);
end
% Change number of panels if indicated
if ~isempty(obj.NPanels)
    fprintf(runFileID,'PPAR\nn\n%d\n\n\n',obj.NPanels);
end
% Change the x/c reference for cm if different from 0.25
if obj.Xcm ~=0.25
    fprintf(runFileID,'XYCM\n%.2f\n0.0\n',obj.Xcm);
end
% Open the OPER menu
fprintf(runFileID,'OPER\n');
% Set Mach number if prescribed
if ~isempty(obj.Mach)
    fprintf(runFileID,'Mach %.4f\n',obj.Mach);
end
% Set iteration limit if prescribed
if ~isempty(obj.Iter)
    fprintf(runFileID,'ITER %d\n',obj.Iter);
end
% If polar is asked, set an alpha of 0 degrees
if strcmpi(parameterType,'polar')
    fprintf(runFileID,'ALFA 0.0\n');
else
    % Otherwise set the input parameter
    fprintf(runFileID,'%s %.3f\n',upper(parameterType),...
        parameterValue);
end
% Switch viscous calculation on if viscous flag is set
if obj.ViscousFlag
    fprintf(runFileID,'VISC %e\n',obj.Re);
    % Set Ncrit
    fprintf(runFileID,'VPAR\nN %.3f\n',obj.Ncrit);
    % If present, set forced transition
    if ~isempty(obj.XtrTop)
        fprintf(runFileID,'XTR\n%.3f\n',obj.XtrTop);
        if ~isempty(obj.XtrBottom)
            fprintf(runFileID,'%.3f\n',obj.XtrBottom);
        else
            fprintf(runFileID,'\n');
        end
    elseif ~isempty(obj.XtrBottom)
        fprintf(runFileID,'XTR\n\n%.3f\n',obj.XtrBottom);
    end
    fprintf(runFileID,'\n');
end
% Switch the polar accumulation on
fprintf(runFileID,'PACC\n');
% Save polar as file
fprintf(runFileID,'%s\n\n',polarFilename);
% If polar is requested
if strcmpi(parameterType,'polar')
    % If minimum alpha is lower then 0, then first calculate
    % polar for negative angles
    if obj.AlphaLimit(1) < 0
        fprintf(runFileID,'ASEQ %.1f %.1f %.1f\n',...
            -obj.AlphaStep,obj.AlphaLimit(1),-obj.AlphaStep);
        % Reinitialize boundary layer solution
        fprintf(runFileID,'INIT\n');
    end
    % Calculate the polar for the positive angles
    fprintf(runFileID,'ASEQ 0.0 %.1f %.1f\n',...
        obj.AlphaLimit(2),obj.AlphaStep);
else
    % Otherwise calculate according to input parameter
    for i=1:length(parameterValue)
        fprintf(runFileID,'%s %.3f\n',upper(parameterType),...
            parameterValue(i));
    end
end
% Switch off polar accumulation
fprintf(runFileID,'PACC\n\n');
% Quit Program
fprintf(runFileID,'QUIT\n');
% Close File
fclose(runFileID);
% Run XFOIL with the run file
[~,~] = dos([currentDirectory(1:2),' && cd ',cd,...
    ' && xfoil.exe',' < ',runFilepath]);
% Read polar file
polarFileID = fopen(polarFilepath, 'r');
% Save polar in a cell array inside another cell
polar  = textscan(polarFileID, '%s', 'delimiter', '\n',...
    'whitespace', '');
% Close polar file
fclose(polarFileID);
% Initialize polar counter
p = 1;
% Read first cell of the array
A = sscanf(polar{1}{p}, repmat('%f ', 1, 7));
% Find the cell where the actual polar starts (for that
% cell the length of the vector returned by the sscanf
% function is 7, since 7 is the number of parameters
% printed by xfoil for each angle of attack)
while length(A) ~= 7
    % Update polar counter
    p = p + 1;
    % If counter is lower than the length of the cell
    % array, then go to next cell
    if p <= length(polar{1})
        A = sscanf(polar{1}{p},repmat('%f ',1,7));
    else
        % Otherwise it means that no polar has been
        % calculated by XFOIL, so make the polar empty and
        % return
        warning('No output calculated by XFOIL.')
        alpha = nan;
        cl = nan;
        cdrag = nan;
        cdp = nan;
        cm = nan;
        topXtr = nan;
        botXtr = nan;
        return
    end
end
% For the remaining cells save the polar data
for i = length(polar{1}):-1:p
    A = sscanf(polar{1}{i}, repmat('%f ', 1, 7));
    alpha(i-p+1) = A(1);
    cl(i-p+1) = A(2);
    cdrag(i-p+1) = A(3);
    cdp(i-p+1) = A(4);
    cm(i-p+1) = A(5);
    topXtr(i-p+1) = A(6);
    botXtr(i-p+1) = A(7);
end
end

