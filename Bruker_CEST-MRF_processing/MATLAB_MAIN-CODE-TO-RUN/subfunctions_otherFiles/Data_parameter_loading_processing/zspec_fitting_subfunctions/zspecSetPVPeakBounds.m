% zspecSetPVPeakBounds:  Sets start points, lower bounds, and upper bounds 
% for Pseudo-Voigt peak fitting
%
%   INPUTS:     NONE - Edit values directly in this file to adjust output!
%
%   OUTPUTS:
%       x   -   Struct containing start point (.st), lower bound (.lb) and
%               upper bound (.ub) arrays for the four parameters used to
%               fit Pseudo-Voigt peaks for each pool. The positional index 
%               of each array value is as follows:
%               1     Ai       --  peak amplitude
%               2     alpha    --  Gaussian proportion
%               3     FWHMl    --  Lorentian full-width half-maximum (FWHM), 
%                                  in ppm
%               4     FWHMrat  --  Ratio of Gaussian:Lorentzian FWHM (should 
%                                  be constrained between 1 and 2)
%               5     omega_0  --  displacement from water protons, in ppm
%               6     phase    --  zero-order phase term for Lorentzian 
%                                  component, in rad
%
function x = zspecSetPVPeakBounds()
%Water pool
x.water.st= [0.9    .3  1.4     1   0       0       ];  % initial value
x.water.lb= [0.5    0   0.3     1   0       0       ];%-pi/24  ];  % lower bound
x.water.ub= [1.0    1   10      2   0       0       ];%pi/24   ];  % upper bound

% OH pool
x.OH.st=    [0.01   .3  1.5     1   0.8     0       ];  % initial value 
x.OH.lb=    [0      0   1       1   0.6     0       ];  % lower bound
x.OH.ub=    [0.5    1   5.5     2   1       0       ];  % upper bound 

% Amine pool
x.amine.st= [0.01   .3  1       1   1.8     0       ];  % initial value
x.amine.lb= [0      0   0.2     1   1.3     0       ];  % lower bound
x.amine.ub= [0.5    1   2.0     2   2.3     0       ];  % upper bound

% Amide pool
x.amide.st= [0.025  .3  1       1   3.0     0       ];  % initial value
x.amide.lb= [0      0   0.2     1   2.5     0       ];  % lower bound
x.amide.ub= [0.8    1   4.0     2   3.5      0       ];  % upper bound

% NOE pool
x.NOE.st=   [0.1    .3  1.5     1   -3.5    0       ];  % initial value 
x.NOE.lb=   [0.0    0   1       1   -4      0       ];  % lower bound
x.NOE.ub=   [0.4    1   4.5     2   -3      0       ];  % upper bound 

% MT pool
x.MT.st=    [0.1    .3  20      1   0       0       ];  % initial value 
x.MT.lb=    [0.0    0   10      1   -1      0       ];  % lower bound
x.MT.ub=    [0.2    1   30     2   1       0       ];  % upper bound 
end