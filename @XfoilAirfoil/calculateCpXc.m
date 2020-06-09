function cpStruct = calculateCpXc(obj,parameterType,parameterValue)
%cpStruct Calculate pressure coefficient along the chord
%   cpStruct = calculateCpXc(obj,parameterType,parameterValue)
% If only one input, then assume calculation based on angle of
% attack
if nargin == 2
    parameterValue = parameterType;
    parameterType = 'alfa';
end
% Calculate cp vs x/c only if both ncrit and Reynolds number
% are available, or if inviscid calculation is desired
if (~isempty(obj.Ncrit) && ~isempty(obj.Re)) ||...
        ~obj.ViscousFlag
    % Check validity of airfoil
    if any(obj.Ycu < obj.Ycl)
        warning(['Invalid airfoil, top and bottom side ',...
            'intersect. Polar calculation aborted.'])
        return
    end
    % Display information to command window
    if obj.ViscousFlag
        fprintf(['Calculating cp vs x/c of',...
            ' airfoil ',obj.Name,' at %s = %.2f and ',...
            'Re = %.2e.\n'],lower(parameterType),...
            parameterValue,obj.Re)
    else
        fprintf(['Calculating cp vs x/c of',...
            ' airfoil ',obj.Name,' at %s = %.2f. ',...
            'Inviscid calculation.\n'],lower(parameterType),...
            parameterValue)
    end
    % Define files names and paths
    matlabValidAirfoilName =...
        matlab.lang.makeValidName(obj.Name);
    coordinatesFilename = [matlabValidAirfoilName,'.dat'];
    coordinatesFilepath =...
        [cd,filesep,matlabValidAirfoilName,'.dat'];
    runFilepath =...
        [cd,filesep,matlabValidAirfoilName,'_run.txt'];
    if obj.ViscousFlag
        cpFilename = sprintf('%s%s%s.cp',...
            matlabValidAirfoilName,...
            [upper(parameterType(1)),...
            lower(parameterType(2:end))],...
            matlab.lang.makeValidName(num2str(...
            parameterValue)));
    else
        cpFilename = sprintf('%s%s%sInviscid.cp',...
            matlabValidAirfoilName,...
            [upper(parameterType(1)),...
            lower(parameterType(2:end))],...
            matlab.lang.makeValidName(num2str(...
            parameterValue)));
    end
    cpFilepath =...
        [cd,filesep,cpFilename];
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
        [~,result] = dos([currentDirectory(1:2),' && cd ',...
            cd,' && xfoil.exe',' < ',runFilepath]);
        if isempty(obj.NPanels) && contains(result,...
                'WARNING: Poor input coordinate distribution')
            % If XFOIL gives a warning do not calculate any
            % polar and return
            warning(['Poor input coordinate distribution ',...
                'for XFOIL. Polar calculation aborted.'])
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
        fprintf(runFileID,['GDES\nFlap\n%.2f\n%.2f\n',...
            '%.1f\n\n'],obj.FlapHingeLocation(1),...
            obj.FlapHingeLocation(2),obj.FlapDeflection);
    end
    % Change number of panels if indicated
    if ~isempty(obj.NPanels)
        fprintf(runFileID,'PPAR\nn %d\n\n\n',obj.NPanels);
    end
    % Change the x/c reference for cm if different from 0.25
    if obj.Xcm ~=0.25
        fprintf(runFileID,'XYCM %.2f 0.0\n',obj.Xcm);
    end
    % Open the OPER menu
    fprintf(runFileID,'OPER\n');
    % Set iteration limit if prescribed
    if ~isempty(obj.Iter)
        fprintf(runFileID,'ITER %d\n',obj.Iter);
    end
    % Set the inviscid alpha
    fprintf(runFileID,'%s %.2f\n',upper(parameterType),...
        parameterValue);
    % If viscous calculation is desired
    if obj.ViscousFlag
        % Set viscous calculation with Reynolds number
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
        % Set viscous alpha
        fprintf(runFileID,'%s %.2f\n',upper(parameterType),...
            parameterValue);
    end
    % Save dump file
    fprintf(runFileID,'CPWR %s\n',cpFilename);
    % Quit Program
    fprintf(runFileID,'\nQUIT\n');
    % Close File
    fclose(runFileID);
    % Run XFOIL with the run file
    [~,~] = dos([currentDirectory(1:2),' && cd ',cd,...
        ' && xfoil.exe',' < ',runFilepath]);
    % Read polar file
    cpFileID = fopen(cpFilepath,'r');
    % Extract each boundary layer parameter distribution in one
    % cell
    blRaw  = textscan(cpFileID,'%f%f%f',...
        'delimiter','\n',...
        'whitespace','',...
        'HeaderLines',3);
    % Extract the xc values that are equal or below one (so
    % within the airfoil and not in the wake)
    xcVector = blRaw{1}(blRaw{1}<=1);
    % Retrieve the boundary layer parameters assumimg that the
    % values are given starting from the TE,
    % going through the top surface to the LE and back to the
    % LE through the bottom surface. Assume also that the
    % number of stations on the top and bottom surfaces is the
    % same
    xcVector = xcVector(length(xcVector)/2+1:end);
    cpTop = flip(blRaw{3}(1:length(xcVector)));
    cpBottom = blRaw{3}(length(xcVector)+1:...
        2*length(xcVector));
    % Assemble output structure
    cpStruct = struct('xc',num2cell(xcVector),...
        'cpTop',num2cell(cpTop),...
        'cpBottom',num2cell(cpBottom));
end
end
