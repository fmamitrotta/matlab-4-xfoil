# matlab-4-xfoil
Object-oriented Matlab framework for the use of Xfoil calculation program.

## Motivation
This project was created as a follow-up of my work for sevaral tasks dealing with airfoil analysis by means of the calculation software [Xfoil](https://web.mit.edu/drela/Public/web/xfoil/). The motivation behind the creation and maintenance of this project stems from the desire to have an object-oriented framework to programmatically interact with Xfoil, as opposed to the more classical functional or procedural scripts. Such object-oriented framework is considered to give advantages in terms of modularity and flexibility, together with the convenient opportunity to use specific methods for common user operations (e.g. plotting the airfoil geometry or polar curve).

## Installation
1. Download the package to a local folder (e.g. ~/matlab-4-xfoil/) by running: 
```console
git clone https://github.com/fmamitrotta/matlab-4-xfoil.git
```
2. Run Matlab and add the folder (~/matlab-4-xfoil/) to your Matlab path.

3. Use the `XfoilAirfoil` class to start running your Xfoil analyses and enjoy!

## Usage
Set the parameters for your airfoil analyses:
```matlab
% Fictitious velocity, chord and kinematic viscosity to set the Reynolds number
referenceVelocity = 3e6; % [m/s]
referenceChord = 1; % [m]
referenceNu = 1;    % [m^2/s]
% Number of iterations of inviscid-viscous coupling
iter = 40;
% Number of panels for the discretization of the airfoil
nPanels = 320;
% Range of angles of attack for the calculation of the airfoil polar
alphaLimit = [-2,10];
```
Select your airfoil (for example a NACA airfoil) and generate your `XfoilAirfoil` object:
```matlab
naca0012 = XfoilAirfoil(struct('type','NACA',...
    'digit','0012',...
    'iter',iter,...
    'referenceVelocity',referenceVelocity,...
    'referenceChord',referenceChord,...
    'referenceNu',referenceNu,...
    'nPanels',nPanels,...
    'alphaLimit',alphaLimit));
```

The airfoil polar is automatically calculated. You can use the class methods for a variety of tasks, such as plot the airfoil geometry, plot the airfoil lift curve or calculate the pressure coefficient along the chord at a given angle of attack:
```matlab
% Plot airfoil geometry
figure
naca0012.plotAirfoil;
% Plot airfoil lift curve
figure
naca0012.plotClAlpha;
% Calculate pressure coefficient along the chord for an angle of attack of 5 deg
alpha5CpStruct = naca0012.calculateCpXc(5);
```

The examples folder provides sample scripts demonstrating the use of the object-oriented framework.

## Contributing
Please don't hesistate to throw feedback and suggestions. Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[GPL-3.0](https://choosealicense.com/licenses/gpl-3.0/)
