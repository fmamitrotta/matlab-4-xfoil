function hLine = plotAirfoil(obj,varargin)
%plotAirfoil Plot airfoil shape
%   hLine = plotAirfoil(obj,varargin)
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
% Get airfoil coordinates in xfoil style
coordinateArray = obj.getXfoilStyleCoordinates;
% Plot coordinates
hLine = plot(p.Results.targetAxes,coordinateArray(:,1),...
    coordinateArray(:,2));
% Set axis
axis image
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
% Set line color if desired
if ~isempty(p.Results.color)
    set(hLine,'Color',p.Results.color);
end
% Make the plot nicer
if ~p.Results.titleFlag
    % If title is not desired omit it from the plot
    % specifications structure
    plotSpecificationStruct = struct(...
        'targetAxes',p.Results.targetAxes,...
        'txtXlabel','$x/c$',...
        'txtYlabel','$y/c$');
else
    plotSpecificationStruct = struct(...
        'targetAxes',p.Results.targetAxes,...
        'txtTitle',obj.Name,...
        'txtXlabel','$x/c$','txtYlabel','$y/c$');
end
makePlotNicer(plotSpecificationStruct)
end

