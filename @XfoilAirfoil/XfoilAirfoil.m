classdef XfoilAirfoil < matlab.mixin.Copyable
    %XfoilAirfoil Airfoil to be analyzed with Xfoil
    %   This class provides the definition for objects representing
    %   airfoils to be analyzed with the calculation software Xfoil. Also
    %   all the parameters needed to run Xfoil analysis are contained
    %   within this class. Furthermore, the class provides methods for a
    %   convenient manipulation and visualization of the calculation
    %   results.
    
    %% Properties
    properties
        Type                    % either NACA or Custom
        Digit                   % only for NACA airfoils
        Name                    % name of the airfoil
        Xc                      % nondimensional x-coordinates
        Ycl                     % nondimensional y-coordinates of lower surface
        Ycu                     % nondimensional y-coordinates of upper surface
        ViscousFlag = true;     % flag for viscous calculations, always set to true unless specified otherwise by the user
        Iter                    % maximum number of iterations for viscous calculations in XFOIL
        Tu = exp(-(9+8.43)/2.4)*100; % turbulence intensity corresponding to the value of Ncrit [%]
        ReferenceVelocity       % reference velocity [m/s]
        ReferenceChord          % reference chord [m]
        ReferenceNu             % reference kinematic viscosity [m^2/s]
        XtrTop                  % x/c coordinate of forced transition on top side
        XtrBottom               % x/c coordinate of forced transition on bottom side
        NPanels                 % number of panels
        AlphaLimit = [0,20];    % min and max alpha for cl-alpha curve calculation [deg]
        AlphaStep = 0.2;        % [deg]
        Xcm = 0.25;             % x/c coordinate of cm reference
        Mach                    % Mach number
        FlapHingeLocation       % vector including the x and y location of the flap hinge
        FlapDeflection = 0;     % flap deflection in degrees (+ down)
    end
    
    %% Dependent properties with public access
    properties (Dependent=true)
        Ncrit           % default log of the amplification factor of the most-amplified frequency which triggers transition
    end
    
    %% Dependent properties with private access
    properties (Dependent=true,SetAccess=private)
        Tc              % nondimensional thickness
        Zc              % nondimensional mean camber
        Re              % reference Reynolds number
        Polar           % airfoil polar calculated through XFOIL
    end
    
    %% Hidden properties
    properties (SetAccess=private,GetAccess=private,Hidden)
        PolarProxy      % extra private property to avoid repetitive runs of XFOIL for polar calculation
        CalculatePolarFlag = false;  % property that indicates whether the polar has to be calculated when requested (it is true when any parameter has changed since last calculation)
    end
    
    %% Methods with private access
    methods (Access=private)
        function changeCalculatePolarFlag(obj,oldProperty,newProperty)
            if ~isequal(oldProperty,newProperty)
                obj.CalculatePolarFlag = true;
            end
        end
    end
    
    %% Public methods
    methods
        %% Class constructor
        function obj = XfoilAirfoil(xfoilAirfoilStruct)
            %XfoilAirfoil constructor takes as input name, nondimensional x
            %and y coordinates, number of iterations for viscous
            %calculations, n critical, reference velocity, chord and
            %kinematic viscosity
            % Check that number of input variables is not zero
            if nargin ~= 0
                obj.Type = xfoilAirfoilStruct.type;
                % Check the type of airfoil requested
                switch lower(obj.Type)
                    case 'naca'
                        % Set digit and name properties
                        obj.Digit = xfoilAirfoilStruct.digit;
                        obj.Name = ['NACA ', obj.Digit];
                        % Run XFOIL to write the coordinates to file and
                        % acquire them in MATLAB
                        % Define files names and paths
                        matlabValidAirfoilName =...
                            matlab.lang.makeValidName(obj.Name);
                        coordinatesFilename = [matlabValidAirfoilName,...
                            '.dat'];
                        runFilepath = [cd, filesep,...
                            matlabValidAirfoilName, '_coordinatesRun.txt'];
                        % Open the file with write permission
                        runFileID = fopen(runFilepath, 'w');
                        % Load the NACA airfoil
                        fprintf(runFileID, 'NACA %s\n', obj.Digit);
                        % Write coordinates to text file
                        fprintf(runFileID, 'SAVE %s\n',...
                            coordinatesFilename);
                        % Quit Program
                        fprintf(runFileID, 'QUIT\n');
                        fclose(runFileID);
                        % Run XFOIL
                        currentDirectory = cd;
                        [~,~] = dos([currentDirectory(1:2), ' && cd ',...
                            cd, ' && xfoil.exe', ' < ', runFilepath]);
                        % Open coordinates file
                        coordinatesFileID = fopen(coordinatesFilename,...
                            'r');
                        % Scan file
                        coordinates = textscan(coordinatesFileID,...
                            '%f %f', 'headerlines',1);
                        % Close file
                        fclose(coordinatesFileID);
                        % Find the position of the 2 lowest x/c values
                        [~,I] = mink(coordinates{1},2);
                        % Acquire coordinates
                        obj.Xc = unique(coordinates{1})';
                        obj.Ycu = interp1(...
                            flip(coordinates{1}(1:min(I))),...
                            flip(coordinates{2}(1:min(I))),...
                            obj.Xc,'spline','extrap');
                        obj.Ycl = interp1(...
                            coordinates{1}(max(I):end),...
                            coordinates{2}(max(I):end),...
                            obj.Xc,'spline','extrap');
                    case 'custom'
                        % Set airfoil name as provided
                        obj.Name = xfoilAirfoilStruct.name;
                        % Coordinates are provided
                        % If xc is a column vector, transpose it
                        if size(xfoilAirfoilStruct.xc, 1) >  1
                            obj.Xc = xfoilAirfoilStruct.xc';
                        else
                            obj.Xc = xfoilAirfoilStruct.xc;
                        end
                        % If ycu is a column vector, transpose it
                        if size(xfoilAirfoilStruct.ycu, 1) >  1
                            obj.Ycu = xfoilAirfoilStruct.ycu';
                        else
                            obj.Ycu = xfoilAirfoilStruct.ycu;
                        end
                        % If ycl is a column vector, transpose it
                        if size(xfoilAirfoilStruct.ycl, 1) >  1
                            obj.Ycl = xfoilAirfoilStruct.ycl';
                        else
                            obj.Ycl = xfoilAirfoilStruct.ycl;
                        end
                    otherwise
                        % Error in the specification of the airfoil type
                        error(['Airfoil type was not set correctly. ',...
                            'Aborting run.'])
                end
                % Set the remaining properties of the object
                if isfield(xfoilAirfoilStruct,'nPanels')
                    obj.NPanels = xfoilAirfoilStruct.nPanels;
                end
                if isfield(xfoilAirfoilStruct,'alphaLimit')
                    obj.AlphaLimit = xfoilAirfoilStruct.alphaLimit;
                end
                if isfield(xfoilAirfoilStruct,'alphaStep')
                    obj.AlphaStep = xfoilAirfoilStruct.alphaStep;
                end
                if isfield(xfoilAirfoilStruct,'xcm')
                    obj.Xcm = xfoilAirfoilStruct.xcm;
                end
                if isfield(xfoilAirfoilStruct,'viscousFlag')
                    obj.ViscousFlag = xfoilAirfoilStruct.viscousFlag;
                end
                if isfield(xfoilAirfoilStruct,'iter')
                    obj.Iter = xfoilAirfoilStruct.iter;
                end
                if isfield(xfoilAirfoilStruct,'ncrit')
                    obj.Ncrit = xfoilAirfoilStruct.ncrit;
                end
                if isfield(xfoilAirfoilStruct,'tu')
                    obj.Tu = xfoilAirfoilStruct.tu;
                end
                if isfield(xfoilAirfoilStruct,'xtrTop') &&...
                        ~isnan(xfoilAirfoilStruct.xtrTop)
                    obj.XtrTop = xfoilAirfoilStruct.xtrTop;
                end
                if isfield(xfoilAirfoilStruct,'xtrBottom') &&...
                        ~isnan(xfoilAirfoilStruct.xtrBottom)
                    obj.XtrBottom = xfoilAirfoilStruct.xtrBottom;
                end
                if isfield(xfoilAirfoilStruct,'referenceVelocity')
                    obj.ReferenceVelocity =...
                        xfoilAirfoilStruct.referenceVelocity;
                end
                if isfield(xfoilAirfoilStruct,'referenceChord')
                    obj.ReferenceChord = xfoilAirfoilStruct.referenceChord;
                end
                if isfield(xfoilAirfoilStruct,'referenceNu')
                    obj.ReferenceNu = xfoilAirfoilStruct.referenceNu;
                end
                if isfield(xfoilAirfoilStruct,'mach')
                    obj.Mach = xfoilAirfoilStruct.mach;
                end
                if isfield(xfoilAirfoilStruct,'flapHingeLocation')
                    obj.FlapHingeLocation =...
                        xfoilAirfoilStruct.flapHingeLocation;
                end
                if isfield(xfoilAirfoilStruct,'flapDeflection')
                    obj.FlapDeflection = xfoilAirfoilStruct.flapDeflection;
                end
            end
        end
        
        %% ViscousFlag set method
        function set.ViscousFlag(obj,viscousFlag)
            obj.changeCalculatePolarFlag(obj.ViscousFlag,viscousFlag)
            obj.ViscousFlag = viscousFlag;
        end
        
        %% ReferenceVelocity property set method
        function set.ReferenceVelocity(obj,referenceVelocity)
            obj.changeCalculatePolarFlag(obj.ReferenceVelocity,...
                referenceVelocity)
            obj.ReferenceVelocity = referenceVelocity;
        end
        
        %% ReferenceChord property set method
        function set.ReferenceChord(obj,referenceChord)
            obj.changeCalculatePolarFlag(obj.ReferenceChord,...
                referenceChord)
            obj.ReferenceChord = referenceChord;
        end
        
        %% ReferenceNu property set method
        function set.ReferenceNu(obj,referenceNu)
            obj.changeCalculatePolarFlag(obj.ReferenceNu,...
                referenceNu)
            obj.ReferenceNu = referenceNu;
        end
        
        %% Tu property set method
        function set.Tu(obj,tu)
            obj.changeCalculatePolarFlag(obj.Tu,tu)
            obj.Tu = tu;
        end
        
        %% Ncrit property get method
        function ncrit = get.Ncrit(obj)
            ncrit = -8.43 - 2.4*log(obj.Tu/100);
        end
        
        %% Ncrit property set method
        function set.Ncrit(obj,ncrit)
            obj.Tu = exp(-(ncrit+8.43)/2.4)*100;
        end
        
        %% XtrTop property set method
        function set.XtrTop(obj,xtrTop)
            obj.changeCalculatePolarFlag(obj.XtrTop,xtrTop)
            obj.XtrTop = xtrTop;
        end
        
        %% XtrBottom property set method
        function set.XtrBottom(obj,xtrBottom)
            obj.changeCalculatePolarFlag(obj.XtrBottom,xtrBottom)
            obj.XtrBottom = xtrBottom;
        end
        
        %% NPanels property set method
        function set.NPanels(obj,nPanels)
            obj.changeCalculatePolarFlag(obj.NPanels,nPanels)
            obj.NPanels = nPanels;
        end
        
        %% AlphaLimit property set method
        function set.AlphaLimit(obj,alphaLimit)
            obj.changeCalculatePolarFlag(obj.AlphaLimit,alphaLimit)
            obj.AlphaLimit = alphaLimit;
        end
        
        %% Mach property set method
        function set.Mach(obj,mach)
            obj.changeCalculatePolarFlag(obj.Mach,mach)
            obj.Mach = mach;
        end
        
        %% FlapHingeLocation property set method
        function set.FlapHingeLocation(obj,flapHingeLocation)
            obj.changeCalculatePolarFlag(obj.FlapHingeLocation,...
                flapHingeLocation)
            obj.FlapHingeLocation = flapHingeLocation;
        end
        
        %% FlapDeflection property set method
        function set.FlapDeflection(obj,flapDeflection)
            obj.changeCalculatePolarFlag(obj.FlapDeflection,...
                flapDeflection)
            obj.FlapDeflection = flapDeflection;
        end
        
        %% Nondimensional thickness get method
        function tc = get.Tc(obj)
            tc = obj.Ycu - obj.Ycl;
        end
        
        %% Nondimensional mean camber get method
        function zc = get.Zc(obj)
            zc = 0.5*(obj.Ycu + obj.Ycl);
        end
        
        %% Reynolds property get method
        function reynoldsNumber = get.Re(obj)
            % Compute Reynolds number only if all reference quantities are
            % available
            if ~isempty(obj.ReferenceVelocity) &&...
                    ~isempty(obj.ReferenceChord) &&...
                    ~isempty(obj.ReferenceNu)
                reynoldsNumber = obj.ReferenceVelocity*...
                    obj.ReferenceChord/obj.ReferenceNu;
            else
                reynoldsNumber = [];
            end
        end
        
        %% Polar property get method
        function polar = get.Polar(obj)
            if obj.CalculatePolarFlag
                obj.calculatePolar;
                obj.CalculatePolarFlag = false;
            end
            polar = obj.PolarProxy;
        end
        
        %% Calculation methods
        % Calculate polar
        calculatePolar(obj)
        % Calculate integral values for a given angle of attack or lift coefficient
        [alpha,cl,cdrag,cdp,cm,topXtr,botXtr] = oper(obj,parameterType,...
            parameterValue)
        % Calculate pressure coefficient along x/c
        cpStruct = calculateCpXc(obj,parameterType,parameterValue)
        % Calculate boundary layer parameters along x/c
        blParameterStruct = calculateBl(obj,parameterType,parameterValue)
        % Find stall point
        [alphaStall,clStall] = findStallPoint(obj)
        % Get coordinates in XFOIL style
        coordinateArray = getXfoilStyleCoordinates(obj)
        % Write coordinates to .dat file
        write2DatFile(obj, coordinatesFilepath)
        
        %% Plot methods
        % Plot airfoil shape
        hLine = plotAirfoil(obj,varargin)
        % Plot cl-alpha curve
        hLine = plotClAlpha(obj,varargin)
        % Plot cd-alpha curve
        hLine = plotCdAlpha(obj,varargin)
        % Plot cm-alpha curve
        hLine = plotCmAlpha(obj,varargin)
        % Plot cl-cd curve
        hLine = plotClCd(obj,varargin)
        % Plot cd-cl curve
        hLine = plotCdCl(obj,varargin)
        % Plot cl/cd vs alpha curve
        hLine = plotClCdVsAlpha(obj,varargin)
        % Plot cl/cd vs alpha curve
        hLine = plotClCdVsCl(obj,varargin)
        % Plot cp vs x/c comparing viscous and inviscid solutions
        [hLineViscous,hLineInviscid] = plotCpXcViscousInviscid(obj,...
            parameterType,parameterValue,varargin)
    end
end
