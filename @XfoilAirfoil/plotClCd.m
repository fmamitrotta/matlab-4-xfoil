function hLine = plotClCd(obj,varargin)
%plotCdCl Plot cl-cd curve
%   hLine = plotClCd(obj,varargin)
% Create an InputParser object
p = inputParser;
% Add inputs to the parsing scheme
defaultDisplayPointsFlag = false;
defaultColor = [];
defaultTitleFlag = true;
addRequired(p,'obj',@(obj)isa(obj,'XfoilAirfoil'));
addParameter(p,'displayPointsFlag',defaultDisplayPointsFlag,@islogical)
addParameter(p,'color',defaultColor,@isnumeric)
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
        [obj.Polar.cd],[obj.Polar.cl]);
    % Set line width
    set(hLine,'LineWidth',2);
    % Set line color if desired
    if ~isempty(p.Results.color)
        set(hLine,'Color',p.Results.color);
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
        specStruct = struct(...
            'targetAxes',p.Results.targetAxes,...
            'txtXlabel','$c_d$',...
            'txtYlabel','$c_l$');
    else
        txtTitle = [obj.Name,' $c_l-c_d$ Curve'];
        if ~isempty(obj.Re)
            txtTitle = [txtTitle,' - ',...
                sprintf('$Re = %.1e$',obj.Re)];
        end
        specStruct = struct(...
            'targetAxes',p.Results.targetAxes,...
            'txtTitle',txtTitle,...
            'txtXlabel','$c_d$',...
            'txtYlabel','$c_l$');
    end
    makePlotNicer(specStruct)
end
end
