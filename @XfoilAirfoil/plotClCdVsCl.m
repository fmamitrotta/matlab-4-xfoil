function hLine = plotClCdVsCl(obj,varargin)
%plotClCdVsCl Plot cl/cd vs alpha curve
%   hLine = plotClCdVsCl(obj,varargin)
% Create an InputParser object
p = inputParser;
% Add inputs to the parsing scheme
defaultDisplayPointsFlag = false;
defaultColor = [];
defaultTitleFlag = true;
addRequired(p,'obj',@(obj)isa(obj,'XfoilAirfoil'));
addParameter(p,'displayPointsFlag',defaultDisplayPointsFlag,...
    @islogical)
addParameter(p,'color',defaultColor,@isnumeric)
addParameter(p,'titleFlag',defaultTitleFlag,@islogical)
addParameter(p,'targetAxes',gca)
% Set properties to adjust parsing
p.KeepUnmatched = true;
% Parse the inputs
parse(p,obj,varargin{:})
% If polar is not empty
if ~isempty(obj.Polar)
    % Plot cl/cd-cl curve
    hLine = plot(p.Results.targetAxes,...
        [obj.Polar.cl],[obj.Polar.cl]./[obj.Polar.cd]);
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
            'txtXlabel','$c_l$',...
            'txtYlabel','$c_l/c_d$');
    else
        % Assemble title string
        txtTitle = [obj.Name,' $c_l/c_d-c_l$ Curve'];
        if ~isempty(obj.Re)
            txtTitle = [txtTitle,' - ',...
                sprintf('$Re = %.1e$',obj.Re)];
        end
        % Plot specification structure
        specStruct = struct(...
            'targetAxes',p.Results.targetAxes,...
            'txtTitle',txtTitle,...
            'txtXlabel','$c_l$',...
            'txtYlabel','$c_l/c_d$');
    end
    makePlotNicer(specStruct)
end
end
