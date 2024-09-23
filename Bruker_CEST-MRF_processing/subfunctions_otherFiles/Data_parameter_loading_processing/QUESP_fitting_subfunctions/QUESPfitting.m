function [QUESP,kBA,fB,rsq]=QUESPfitting(Zlab,Zref,varyval,fitFcns,T1A_sec,...
    timepar,PlotFlag,fitidx,opts)
% Created: 07/13/18 by OP, based on Moritz Zaiss BMSimfit QUESP files
% Notes: 
%       *** IMPORTANT!! If parameters do NOT lead to saturation *** 
%       *** steady-state (i.e. if tp < 3*T1), then neither      ***
%       *** Inverse QUESP nor the Omega Plot will be valid!!    ***
% Changes log:
%   DK, 12/22/23    -   Added new optional input fitidx to fit a subset of
%                       points while plotting all of them on scatter plot
%   DK, 2/5/24      -   Changed input tp_sec to be a structure containing
%                       timing parameters timepar.tp and timepar.rd (both 
%                       in units of s). Also added warnings to user to use
%                       regular QUESP if tp < 3*T1 and to be careful if
%                       timepar.rd is not specified 
%   DK, 9/16/24     -   Updated to require variable fitFcns, which is a
%                       cell array of strings containing all desired
%                       fitting types (1-3 of the following: 'Regular', 
%                       'Inverse', 'OmegaPlot'), so as to save time while
%                       fitting with only one! Also reordered variables.
%                       Also made the output a struct rather than so many
%                       subvariables!
%------------------------input variables-------------------------------------%
% Zlab - Row vector of single offset Z-spectrum measurment
% Zref= Row vector of reference (negative frequency)
%                            offset Z-spectra measurment
% varyval - varied value as row vector (B1, [uT])
% fitFcns - cell array of strings containing one or more of the following
%           desired options for the fit function: 'Regular', 'Inverse', or 
%           'OmegaPlot'
%
% T1A_sec - T1 water value (s)
% timepar - Struct containing two timing parameters:
%   timepar.tp  - Saturation pulse duration (s)
%   timepar.rd  - Recovery delay after measurement (s)
%   NOTE:   if a single value, timepar will be used as timepar.tp, and a
%           warning will encourage the user to check whether Zi=1 is valid
%
% PlotFlag - fit ploting  (1/0), should be avoided in pixelwise fitting
% fitidx - optional, Indices of Zlab/Zref/varyval to fit (others excluded,
%   but still plotted)
% opts - optional, Fit start value and boundaries. 
%               boundaries for   fb        kb
%       e.g.: opts.Lower      = [0.0000135 0     ];
%             opts.StartPoint = [0.000135  4000  ];
%             opts.Upper      = [0.0135    1500000];
%           If not give, the above values will be used
%----------------------------------------------------------------------------%
%-----------------------output variables-------------------------------------%
%   QUESP    -   struct with the following possible fieldnames:
%       .Regular    -   Typical QUESP fitting
%       .Inverse    -   Inverse QUESP fitting
%       .OmegaPlot  -   Omega plot fitting
%           Each of these fieldnames above has the following additional
%           fieldnames (most important ones):
%               .kBA    - Array: [Fitted exchange rate solute-water,error] (Hz)
%               .fB     - Array: [Fitted fractional concentration solute,error]
%               .rsq    - Goodness of fit rsquare
%           Also (perhaps less important):
%               .w_x    - X data used for fitting
%               .MTR    - MTR values(?)
%               .fit    - Fit result
%
%   (these next outputs are especially useful when performed voxelwise
%   fitting with a parfor() loop! They only pertain to the FIRST ELEMENT 
%   of variable fitFcns)
%   kBA     -   Fitted exchange rate solute-water (Hz)
%   fB      -   Fitted fractional concentration solute
%   rsq     -   Goodness of fit rsquare
%   
%----------------------------------------------------------------------------%

%% Organize measurement parameters 
% If timepar is a single value, use it as tp; otherwise, read in struct
% values
if isstruct(timepar)
    P.tp=timepar.tp; %saturation pulse duration [s]
    P.rd=timepar.rd; %relaxation delay [s]
else
    P.tp=timepar; %saturation pulse duration [s]
    P.rd=Inf; %relaxation delay [s]
    warning(['Relaxation delay not specified! Zi = 1 assumption used -- ' ...
        'double-check that relaxation delay > 3*T1!'])
end

P.R1A=1./T1A_sec;	% R1 relaxation rate (water) [Hz]

% Check whether saturation steady-state assumption is valid
if 3*T1A_sec > P.tp
    warning(['Saturation time < 3*T1! Inverse QUESP + Omega Plot may not '...
        'be accurate due to invalid saturation steady-state assumption'])
end

% P.Zi=1;		% initial magnetization before saturation block, assuming long enough TR
P.Zi=1-exp(-P.R1A*P.rd);		% initial magnetization before saturation block
P.normalized=[];  % offset used for normalization 
P.pulsed=0;  	% pulse train (1) or cw (0) 
P.vary={'B1'};	% varied parameter (B1 for QUESP experiments)
P.varyval=varyval;
% P.varyval=[0 1 2 3 4 5 6 0 1 2 3 4 5 6]; % value of varied parameter (here B1 in µT)

P.fittypes=fitFcns;

%If fit start value and boundaries not input, using the below values
if ~exist('opts','var') %
    % --Fit start value and boundaries---%
    % Start values and boundaries have to be given!
    % boundaries for   fb        kb
    opts.Lower      = [0.0000135 0     ];
    opts.StartPoint = [0.000135  4000  ];
    opts.Upper      = [0.0135    1500000];
end

%If no indices specified for points to fit, fit all values
if ~exist('fitidx','var')
    fitidx=1:length(Zlab);
elseif isempty(fitidx)
    fitidx=1:length(Zlab);
end
P.fitidx=fitidx;


%% ---------------FITTING-----------------%
QUESP=QUESPfcn(Zlab,Zref,P,opts,PlotFlag);
kBA=QUESP.(fitFcns{1}).kBA(1);
fB=QUESP.(fitFcns{1}).fB(1);
rsq=QUESP.(fitFcns{1}).rsq;

end 
