% Clear variables and close figures
clear
close all
% Add matlab-4-nastran folder and subfolders to Matlab path
addpath(genpath(['..',filesep,'..']));

%% Set parameters for NACA 2515 polar
% Velocity, chord and kinematic viscosity are fictitious parameters used to
% set the Reynolds number
iter = 40;
referenceVelocity = 3e6; % [m/s]
referenceChord = 1; % [m]
referenceNu = 1;    % [m^2/s]
nPanels = 320;
alphaLimit = [-2,10];

%% Generate NACA 2515 object
naca2515 = XfoilAirfoil(struct('type','NACA',...
    'digit','2515',...
    'iter',iter,...
    'referenceVelocity',referenceVelocity,...
    'referenceChord',referenceChord,...
    'referenceNu',referenceNu,...
    'nPanels',nPanels,...
    'alphaLimit',alphaLimit));

%% Plot airfoil geometry
naca2515.plotAirfoil('titleFlag',false);

%% Investigate effect of n-factor on lift and drag polars
% Generate vector of n-factor
nFactorVector = linspace(4,12,3);
% Retrieve standard colors for lines in plot
c = lines;
% Set angle of attack for the pressure coefficients calculation
alphaZoomIn = 6.6;
% Generate figure for lift and drag polars
figure
% Generate subplots for lift and drag polars
[ha,~] = tight_subplot(1,2,.04,.15,.1);
clAlphaAxes = ha(1);
hold(clAlphaAxes,'on')
clCdAxes = ha(2);
hold(clCdAxes,'on')
% Generate figure and axes for cl-alpha curve
figure
clAlphaZoomAxes = axes;
hold(clAlphaZoomAxes,'on')
% Generate figure and axes for cp vs x/c plot
figure
cpXcAxes = axes;
cpXcAxes.YDir = 'reverse';
hold(cpXcAxes,'on')
% Generate figure and axes for cf vs x/c plot
figure
cfXcAxes = axes;
hold(cfXcAxes,'on')
% Itearte through the different values of n-factor
for i=length(nFactorVector):-1:1
    % Update n-factor
    naca2515.Ncrit = nFactorVector(i);
    % Plot cl-alpha curve
    clAlphaCurveVector(i) = naca2515.plotClAlpha(...
        'targetAxes',clAlphaAxes,...
        'color',c(i+1,:),...
        'titleFlag',false);
    clAlphaCurveVector(i) = naca2515.plotClAlpha(...
        'targetAxes',clAlphaZoomAxes,...
        'color',c(i+1,:),...
        'titleFlag',false);
    % Plot cl-cd curve
    clCdCurveVector(i) = naca2515.plotClCd('targetAxes',clCdAxes,...
        'color',c(i+1,:),...
        'titleFlag',false);
    % Add name to legend array
    legendArray{i} = sprintf('$n=%.1f$',nFactorVector(i));
    % Plot cp vs x/c for the angle of attack given by alphaZoomIn
    alphaZoomInCpStruct = naca2515.calculateCpXc(alphaZoomIn);
    plot(cpXcAxes,...
        [alphaZoomInCpStruct.xc],[alphaZoomInCpStruct.cpBottom],...
        'color',c(i+1,:));
    plot(cpXcAxes,[alphaZoomInCpStruct.xc],[alphaZoomInCpStruct.cpTop],...
        'color',c(i+1,:));
    % Plot cf vs x/c for the angle of attack given by alphaZoomIn
    alphaZoomInBlParametersStruct = naca2515.calculateBl(alphaZoomIn);
    plot(cfXcAxes,[alphaZoomInBlParametersStruct.xc],...
        [alphaZoomInBlParametersStruct.cfBottom],...
        ':','color',c(i+1,:));
    cfXcCurveVector(i) = plot(cfXcAxes,...
        [alphaZoomInBlParametersStruct.xc],...
        [alphaZoomInBlParametersStruct.cfTop],...
        '-','color',c(i+1,:));
end
% Plot inviscid solution
naca2515.ViscousFlag = false;
naca2515.plotClAlpha(...
    'targetAxes',clAlphaAxes,...
    'linestyle','--',...
    'color','k',...
    'titleFlag',false);
clAlphaCurveVector(end+1) = naca2515.plotClAlpha(...
    'targetAxes',clAlphaZoomAxes,...
    'linestyle','--',...
    'color','k',...
    'titleFlag',false);
alphaZoomInCpStruct = naca2515.calculateCpXc(alphaZoomIn);
plot(cpXcAxes,[alphaZoomInCpStruct.xc],[alphaZoomInCpStruct.cpBottom],...
    'k--');
plot(cpXcAxes,[alphaZoomInCpStruct.xc],[alphaZoomInCpStruct.cpTop],...
    'k--');
% Set axes of subplots
linkaxes([clAlphaAxes,clCdAxes],'y')
xticklabels(clAlphaAxes,'auto')
yticklabels(clAlphaAxes,'auto')
xticklabels(clCdAxes,'auto')
set(clCdAxes,'ylabel',[])
% Add legend to first subplot
plotSpecificationStruct = struct(...
    'targetAxes',clAlphaAxes,...
    'lineHandleVector',clAlphaCurveVector,...
    'legendArray',{[legendArray,'Inviscid calculation']},...
    'legendLocation','northwest');
makePlotNicer(plotSpecificationStruct)
% Set limit of x-axis 
xlim(clAlphaZoomAxes,[5,9])
% Set legend and improve appearance of cp vs x/c plot
plotSpecificationStruct = struct(...
    'targetAxes',cpXcAxes,...
    'txtXlabel','$x/c$',...
    'txtYlabel','$C_p$',...
    'lineHandleVector',...
    clAlphaCurveVector,...
    'legendArray',{[legendArray,'Inviscid calculation']});
makePlotNicer(plotSpecificationStruct)
% Set legend and improve appearance of cf vs x/c plot
fullLineHandle = plot(cfXcAxes,nan,nan,'k-');
dottedLineHandle = plot(cfXcAxes,nan,nan,'k:');
plotSpecificationStruct = struct(...
    'targetAxes',cfXcAxes,...
    'txtXlabel','$x/c$',...
    'txtYlabel','$C_f$',...
    'lineHandleVector',...
    [cfXcCurveVector,dottedLineHandle,fullLineHandle],...
    'legendArray',{[legendArray,'Bottom side','Top side']});
makePlotNicer(plotSpecificationStruct)

%% Save figures
saveNiceFigure({'Naca2515CfXcAlpha6_6','Naca2515CpXcAlpha6_6',...
    'Naca2515ClAlpha','Naca2515Polars','Naca2515Geometry'});