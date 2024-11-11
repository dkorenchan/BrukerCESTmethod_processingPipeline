% zspecSetLPeakBounds:   Sets start points, lower bounds, and upper bounds 
% for Lorentzian peak fitting
%
%   INPUTS:     NONE - Edit values directly in this file to adjust output!
%
%   OUTPUTS:
%       x   -   Struct containing start point (.st), lower bound (.lb) and
%               upper bound (.ub) arrays for the four parameters used to
%               fit Lorentzian peaks for each pool. The positional index of
%               each array value is as follows:
%               1     Amplitude
%               2     Full-width half-maximum, in ppm
%               3     Displacement from water protons, in ppm
%               4     Zero-order phase term for peak, in rad
%
function x = zspecSetLPeakBounds()
%Water pool
x.water.st= [0.9    1.4     0       0       ];      % initial value
x.water.lb= [0.02   0.3     0       0       ];%-pi/24  ];      % lower bound
x.water.ub= [1.0    10      0       0       ];%pi/24   ];      % upper bound

% OH pool
x.OH.st=    [0.01   1.2     0.8     0       ];      % initial value
x.OH.lb=    [0      1       0.6     0       ];      % lower bound
x.OH.ub=    [0.5    5       1       0       ];      % upper bound

% Amine pool
x.amine.st= [0.01   1       1.8     0       ];      % initial value
x.amine.lb= [0      0.2     1.3     0       ];      % lower bound
x.amine.ub= [0.5    3.5     2.3     0       ];      % upper bound

% % Amine pool (alt)
% x.Amine=[0.02 2 1.8];     % initial value
% lb.Amine=[.005 1 1.6];    % lower bound
% ub.Amine=[0.5 3.5 2.0];   % upper bound

%Amide pool
x.amide.st= [0.025  1       3.0     0       ];      % initial value
x.amide.lb= [0      0.2     2.5     0       ];      % lower bound
x.amide.ub= [0.8    5.0     3.5     0       ];      % upper bound

% %Amide pool (alt)
% x.Amide=[0.01 0.7 3.5];   % initial value
% lb.Amide=[0 0.5 3.4];     % lower bound
% ub.Amide=[0.4 3.0 3.6];   % upper bound

% NOE pool
x.NOE.st=   [0.1    1.5     -3.5    0       ];      % initial value
x.NOE.lb=   [0.0    1       -4      0       ];      % lower bound
x.NOE.ub=   [0.4    4.5     -3      0       ];      % upper bound

% MT pool
x.MT.st=    [0.1    20      0       0       ];  % initial value 
x.MT.lb=    [0.0    10      -1      0       ];  % lower bound
x.MT.ub=    [0.2    30      1       0       ];  % upper bound 

end