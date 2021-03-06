function hLine = plotCmAlpha(obj,varargin)
%plotCmAlpha Plot cm-alpha curve
%   hLine = plotCmAlpha(obj,varargin)
% Create an InputParser object
p = inputParser;
% Add inputs to the parsing scheme
defaultDisplayPointsFlag = false;
defaultColor = [];
defaultLineStyle = [];
defaultTitleFlag = true;
addRequired(p,'obj',@(obj)isa(obj,'XfoilAirfoil'));
addParameter(p,'displayPointsFlag',defaultDisplayPointsFlag,...
    @islogical)
addParameter(p,'color',defaultColor,@isnumeric)
addParameter(p,'linestyle',defaultLineStyle)
addParameter(p,'titleFlag',defaultTitleFlag,@islogical)
addParameter(p,'targetAxes',gca)
% Set properties to adjust parsing
p.KeepUnmatched = true;
% Parse the inputs
parse(p,obj,varargin{:})
% If polar is not empty
if ~isempty(obj.Polar)
    % Plot cl-alpha curve
    hLine = plot(p.Results.targetAxes,...
        [obj.Polar.alpha],[obj.Polar.cm]);
    % Set line width
    set(hLine,'LineWidth',2);
    % Set line color if desired
    if ~isempty(p.Results.color)
        set(hLine,'Color',p.Results.color);
    end
    % Set line style if desired
    if ~isempty(p.Results.linestyle)
        set(hLine,'LineStyle',p.Results.linestyle);
    end
    % Plot markers at airfoil points if desired
    if p.Results.displayPointsFlag
        set(hLine,'Marker','o','MarkerSize',5,...
            'MarkerEdgeColor',[.2 .2 .2],...
            'MarkerFaceColor',[.7 .7 .7]);
    end
    % Make the plot nicer
    if ~p.Results.titleFlag
        % If title is not desired omit it from the plot
        % specifications structure
        plotSpecificationStruct = struct(...
            'targetAxes',p.Results.targetAxes,...
            'txtXlabel','$\alpha$ [$^\circ$]',...
            'txtYlabel','$c_m$');
    else
        txtTitle = [obj.Name,' $c_m-\alpha$ Curve'];
        if ~isempty(obj.Re)
            txtTitle = [txtTitle,' - ',...
                sprintf('$Re = %.1e$',obj.Re)];
        end
        plotSpecificationStruct = struct(...
            'targetAxes',p.Results.targetAxes,...
            'txtTitle',txtTitle,...
            'txtXlabel','$\alpha$ [$^\circ$]',...
            'txtYlabel','$c_m$');
    end
    makePlotNicer(plotSpecificationStruct)
end
end
