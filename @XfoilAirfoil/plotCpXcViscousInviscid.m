function [hLineViscous,hLineInviscid] = plotCpXcViscousInviscid(obj,...
    parameterType,parameterValue,varargin)
%plotCpXcViscousInviscid Plot pressure coefficient along the chord
%comparing viscous and inviscid solutions
%   [hLineViscous,hLineInviscid] =
%   plotCpXcViscousInviscid(obj,parameterType,parameterValue,varargin)
% Create an InputParser object
p = inputParser;
% Add inputs to the parsing scheme
defaultTitleFlag = true;
addRequired(p,'obj',@(obj)isa(obj,'XfoilAirfoil'));
addRequired(p,'parameterType',@ischar);
addRequired(p,'parameterValue',@isnumeric);
addParameter(p,'titleFlag',defaultTitleFlag,@islogical)
addParameter(p,'targetAxes',gca)
% Set properties to adjust parsing
p.KeepUnmatched = true;
% Parse the inputs
parse(p,obj,parameterType,parameterValue,varargin{:})
% Viscous calculation
oldViscousFlag = obj.ViscousFlag;
obj.ViscousFlag = true;
cpXcViscous = obj.calculateCpXc(parameterType,parameterValue);
% Inviscid calculation
obj.ViscousFlag = false;
cpXcInviscid = obj.calculateCpXc(parameterType,parameterValue);
obj.ViscousFlag = oldViscousFlag;
% Plot viscous results
hLineViscous = plot(p.Results.targetAxes,...
    [flip([cpXcViscous.xc]),[cpXcViscous.xc]],...
    [flip([cpXcViscous.cpTop]),[cpXcViscous.cpBottom]]);
hold(p.Results.targetAxes,'on')
% Plot inviscid results
hLineInviscid = plot(p.Results.targetAxes,...
    [flip([cpXcInviscid.xc]),[cpXcInviscid.xc]],...
    [flip([cpXcInviscid.cpTop]),[cpXcInviscid.cpBottom]],...
    'k--');
% Reverse y-axis
p.Results.targetAxes.YDir = 'reverse';
% Make the plot nicer
if ~p.Results.titleFlag
    % If title is not desired omit it from the plot
    % specifications structure
    plotSpecificationStruct = struct('txtXlabel','$x/c$',...
        'txtYlabel','$C_p$',...
        'legendArray',{{'Viscous calculation',...
        'Inviscid calculation'}});
else
    % Distinguish between alpha or cl calculation
    if strcmpi(parameterType,'alpha')
        titleString = sprintf(['%s - $Re=%.1e - n_{crit}=%',...
            '.1f$ - $\\alpha=%.1f^\\circ$'],...
            obj.Name,obj.Re,obj.Ncrit,parameterValue);
    else
        titleString = sprintf(['%s - $Re=%.1e - n_{crit}=%',...
            '.1f$ - $c_l=%.1f^\\circ$'],...
            obj.Name,obj.Re,obj.Ncrit,parameterValue);
    end
    % Assemble specification structure
    plotSpecificationStruct = struct('txtTitle',titleString,...
        'txtXlabel','$x/c$',...
        'txtYlabel','$C_p$',...
        'legendArray',{{'Viscous calculation',...
        'Inviscid calculation'}});
end
makePlotNicer(plotSpecificationStruct)
end
