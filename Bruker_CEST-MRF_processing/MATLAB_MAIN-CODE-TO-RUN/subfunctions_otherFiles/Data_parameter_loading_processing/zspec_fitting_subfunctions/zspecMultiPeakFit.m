function [EstimatedParams,CI,Residual,Sum_All_P,Indiv_P]=...
    zspecMultiPeakFit(w,OneMinZ,pNames,pPars,fixedVals,ppm_wt,PlotDispFlag)
% Purpose: Multi-peak model fit, either Lorentzian or Pseudo-Voigt
% Created: 09/28/18 by OP
% Updated most recently by DK, 11/11/24, to be parfor-compatible!
%------------------------input variables-------------------------------------%
% ----Measured (MR de facto scanned) values:
% w - offset frequency [ppm]
% OneMinZ=1-Z=1-Measured Z(delta_w) =1-Mz/Mz0
% pNames -  cell array of fieldnames of pPars and fixedVals corresponding to 
%           peaks to fit
% pPars -   structure contains start point, lower and upper bounds for peak 
%           fitting (used to detect whether Lorentzian or Pseudo-Voigt
%           shapes used)
% fixedVals -   optional structure of parameter values to fix parameters at 
%               for each peak while fitting (follows list of EstimatedParams 
%               below; specify NaN for parameters not to be fixed). May 
%               also contain additional fields: 
%               -   fixedVals.samePVchar: logical (for Pseudo-Voigt peaks); 
%                   if true, this will constrain peak character (alpha and 
%                   FWHMrat) to be same for all peaks
% ppm_wt -  optional (array of) ppm value(s) to focus fitting on (e.g. if 
%           small but important peak(s) need fitting) 
% PlotDispFlag - optional plot and display flag (true/false; default false)
%----------------------------------------------------------------------------%
%-----------------------output variables-------------------------------------%
%  EstimatedParams - estimated model parameters: struct containing a
%  parameter vector for each peak, either of length 3 (Lorentzian) or 5 
%  (Pseudo-Voigt):
%
%      ---For Lorentzian peaks ---
%1     Ai
%2     FWHM
%3     displacement free water protons
%4     linear phase term
%
%      ---For Pseudo-Voigt peaks---
%1     Ai       --  peak amplitude
%2     alpha    --  Gaussian proportion
%3     FWHMl    --  Lorentian FWHM
%4     FWHMrat  --  Ratio of Gaussian:Lorentzian FWHM (should be
%                   constrained between 1 and 2)
%5     omega_0  --  displacement
%6     phase    --  linear phase term for peak
%       
% Sum_All_P - Numeric vector of spectral sum of all peaks
% Indiv_P - struct containing numeric vector describing each peak fitted
%
% residual - Value of objective function at solution, returned as an array. In general, residual = fun(x,xdata)-ydata.
% CI - struct containing 95% confidence interval for each parameter fit
%----------------------------------------------------------------------------%
% Changes log:  8/30/23 -   Added option to weight fit twd specified ppm value  
%               9/21/23 -   Added ability to fit arbitrary # of peaks! New
%                           inputs pPars and pNames give fitting params +
%                           which peaks to actually fit. Adjusted other
%                           variables accordingly. Also, made script fit
%                           either Lorentz or Pseudo-Voigt based upon pPars
%               9/25/23 -   Added detection of whether only pools are water
%                           and (optionally) NOE - if so, only negative ppm
%                           values are fitted
%               11/10/23 -  Minor bug fix: better identification of
%                           negative ppm values to fit (now a larger
%                           region, 0ppm > x > -5ppm, to include NOE
%                           better)
%               11/28/23 -  Added ability to constrain PS peak
%                           character to be equal across all peaks
%               11/29/23 -  Added functionality to specify multiple ppm
%                           values for ppm_wt
%               12/27/23 -  Small bug fix: script would error if number of
%                           pools exceeded the number of colors in plotvis
%               2/23/24  -  Changed so that if Pseudo-Voigt character is
%                           constrained, it is only among non-water peaks
%               3/8/24   -  Added phasing terms to all peaks, 
%                           whether Lorentzian or Pseudo-Voigt. Had to
%                           adjust Lorentzian formulas to be complex-valued
%               8/27/24  -  Added MT pool as one of the pools to fit first
%                           with negative ppm values

%***************** set unspecified optional inputs***************
%---------------------------------------------------------------%
% First, detect whether fitting Lorentzian or Pseudo-Voigt based upon how 
% many parameters specified for peak fitting
if length(pPars.(pNames{1}).st)==4
    peakType='lorentz';
    nPars=4;
elseif length(pPars.(pNames{1}).st)==6
    peakType='pseudovoigt';
    nPars=6;
else
    error('Wrong number of peak fitting parameters specified! Check input pPars')
end

% Detect whether only pools specified are water and (optionally) NOE, for
% negative ppm fitting
if sum(strcmp(pNames,'water'))+sum(strcmp(pNames,'NOE'))+sum(strcmp(pNames,'MT')) == numel(pNames)
    negppmflg = true;
else
    negppmflg = false;
end

% Fill in unspecified parameters
if nargin < 5
    for ii = 1:numel(pNames)
        name = pNames{ii};
        fixedVals.(name) = NaN(nPars,1);
    end
    ppm_wt = NaN;
    PlotDispFlag = false;
elseif nargin < 6
    ppm_wt = NaN;
    PlotDispFlag = false;    
elseif nargin < 7
    PlotDispFlag = false;
end

% Fix specified values using non-NaN values in fixedVals
for ii = 1:numel(pNames)
    name = pNames{ii};
    vals = fixedVals.(name);
    for jj = 1:nPars
        if ~isnan(vals(jj))
            pPars.(name).st(jj) = vals(jj);
            pPars.(name).lb(jj) = vals(jj);
            pPars.(name).ub(jj) = vals(jj);
        end
    end
end

% Detect whether Pseudo-Voigt peak character will be identical for all
% fitted peaks
if isfield(fixedVals,'samePVchar')
    if fixedVals.samePVchar
        samePVcharflg=true;
    else
        samePVcharflg=false;
    end
else
    samePVcharflg=false;    
end

% Final values to be sent to function
Full_Model_x0=zeros(numel(pNames)*nPars,1);%initial value
Full_Model_lb=zeros(numel(pNames)*nPars,1);%lower bound
Full_Model_ub=zeros(numel(pNames)*nPars,1);%upper bound
for ii = 1:numel(pNames)
    name = pNames{ii};
    Full_Model_x0((nPars*(ii-1)+1):(nPars*ii))=pPars.(name).st;
    Full_Model_lb((nPars*(ii-1)+1):(nPars*ii))=pPars.(name).lb;
    Full_Model_ub((nPars*(ii-1)+1):(nPars*ii))=pPars.(name).ub;
end
%---------------------------------------------------------------------%
%*********************************************************************

%% -----------Fitting the data to the full multi-Lorentzian model------%
% options=optimset('MaxFunEvals',10000000000,'TolFun',1e-15); %The default TolFun is 1e-06

% If only water (and possibly NOE or MT) pools, fit negative ppm values only
if negppmflg
%     fitpts = (length(w)/2+1):(length(w)*2/3);
    fitpts=find(w<0 & w>-5);
%     fitpts=find(w<0 | w>8);   %used to fit negative ppm + the highest positive ppm vals for (water + NOE + MT)    
else
    fitpts = 1:length(w);
end

% [EstimatedParams,resnorm,Residual,~,~,~,jacobian]=...
%     lsqcurvefit(@ufzsFourPseudoVoigtModel,Full_Model_x0,w,OneMinZ,...
%     Full_Model_lb,Full_Model_ub);

% opt=optimoptions('lsqnonlin','MaxFunctionEvaluations',6000,...
%     'MaxIterations',4000,'FunctionTolerance',1e-12,'StepTolerance',1e-12);
[EPvec,resnorm,Residual,~,~,~,jacobian]=...
    lsqnonlin(@(x) peakFitFcn(x,pNames,w(fitpts),OneMinZ(fitpts),ppm_wt,...
    peakType,samePVcharflg),Full_Model_x0,Full_Model_lb,Full_Model_ub);%,opt);

notWaterIdx=find(~strcmp(pNames,'water'));
if samePVcharflg && ~isempty(notWaterIdx) %update alpha and FWHMrat with 
        %values from 1st non-water pool, 
        %which were overridden during optimization 
    for ii=notWaterIdx
        EPvec(nPars*(ii-1)+2)=EPvec(nPars*(notWaterIdx(1)-1)+2);
        EPvec(nPars*(ii-1)+4)=EPvec(nPars*(notWaterIdx(1)-1)+4);
    end
end
EPvec=EPvec.'; % transposing to get a column vector

% Nonlinear regression parameter confidence interval
CIvec=nlparci(EPvec,Residual,'jacobian',jacobian);

% Getting the full spectrum + individual peaks using the estimated parmeters
Sum_All_P=zeros(size(w));
for ii = 1:numel(pNames)
    name = pNames{ii};
    EstimatedParams.(name) = EPvec((nPars*(ii-1)+1):(nPars*ii));
    CI.(name) = CIvec((nPars*(ii-1)+1):(nPars*ii),:);
    switch peakType
        case 'lorentz'
            Indiv_P.(name) = zspecSingleLorentzianModel(EstimatedParams.(name),w);
        case 'pseudovoigt'
            Indiv_P.(name) = zspecSinglePseudoVoigtModel(EstimatedParams.(name),w);
    end
    Sum_All_P=Sum_All_P+Indiv_P.(name);
end

%% -----------------Ploting and variables display (optional)-------%

if PlotDispFlag 
    plotvis = {'b-','g-','r-','m-','c-','y-','k-'};
    figure
    h1=axes;
%     h1 = gca;
    plot(w,OneMinZ,'Marker','o','Color',[0.5 0.5 0.5],'MarkerFaceColor',[0.5 0.5 0.5],'LineWidth',1.5,'LineStyle','none')
    hold on; plot(w,Sum_All_P,'k-','LineWidth',2)
    for ii = 1:numel(pNames)
        name = pNames{ii};
        hold on; plot(w,Indiv_P.(name),plotvis{1+mod(ii-1,numel(plotvis))},...
            'LineWidth',2)
    end
    axis([min(w) max(w) 0 1]);
    set(h1, 'Xdir', 'reverse') %reversing axis display
    xlabel('\Delta\omega [ppm]')
    ylabel('Z(\Delta\omega)')
    legend([{'Raw data','Sum'},pNames])
    grid on
    
    %%--------- displaying resulting parameters-----------%
    % disp('Resulting fitted values:')
    for ii = 1:numel(pNames)
        name = pNames{ii};
        disp('--------------------------------')
        disp(['----- Pool: ' name ' -----'])   
        switch peakType
            case 'lorentz'
                disp(['Amplitude = ',num2str(EstimatedParams.(name)(1)),...
                    ' 95% CI = [',num2str(CI.(name)(1,1)),', ',...
                    num2str(CI.(name)(1,2)),']'])
                disp(['FWHM = ',num2str(EstimatedParams.(name)(2)),...
                    ' 95% CI = [',num2str(CI.(name)(2,1)),', ',...
                    num2str(CI.(name)(2,2)),']'])
                 disp(['Phase = ',num2str(EstimatedParams.(name)(4)*180/pi),...
                    ' 95% CI = [',num2str(CI.(name)(4,1)),', ',...
                    num2str(CI.(name)(4,2)),']'])                 
                disp(['Offset = ',num2str(EstimatedParams.(name)(3)),...
                    ' 95% CI = [',num2str(CI.(name)(3,1)),', ',...
                    num2str(CI.(name)(3,2)),']'])                
            case 'pseudovoigt'
                disp(['Amplitude = ',num2str(EstimatedParams.(name)(1)),...
                    ' 95% CI = [',num2str(CI.(name)(1,1)),', ',...
                    num2str(CI.(name)(1,2)),']'])
                disp(['% Gaussian = ',num2str(EstimatedParams.(name)(2)*100),...
                    ' 95% CI = [',num2str(CI.(name)(2,1)*100),', ',...
                    num2str(CI.(name)(2,2)*100),']'])
                disp(['FWHM_Lorentzian = ',num2str(EstimatedParams.(name)(3)),...
                    ' 95% CI = [',num2str(CI.(name)(3,1)),', ',...
                    num2str(CI.(name)(3,2)),']'])
                disp(['FWHM_Gaussian = ',num2str(EstimatedParams.(name)(3)*EstimatedParams.(name)(4)),...
                    ' 95% CI = [',num2str(CI.(name)(3,1)*CI.(name)(4,1)),', ',...
                    num2str(CI.(name)(3,2)*CI.(name)(4,2)),']'])
                disp(['Phase = ',num2str(EstimatedParams.(name)(6)*180/pi),...
                    ' 95% CI = [',num2str(CI.(name)(6,1)),', ',...
                    num2str(CI.(name)(6,2)),']']) 
                disp(['Offset = ',num2str(EstimatedParams.(name)(5)),...
                    ' 95% CI = [',num2str(CI.(name)(5,1)),', ',...
                    num2str(CI.(name)(5,2)),']'])
        end
        disp('--------------------------------')
    end

    % Displaying squared 2-norm of the residual: sum((fun(EstimatedParams,w)-Z).^2).
    fprintf('\n The fitting had a residual norm of %f\n',resnorm);
end
end

function res = peakFitFcn(x,pools,w,data,ppm_wt,peakType,PVcharConstrain)
if nargin < 7
    PVcharConstrain=false;
end

fit = zeros(size(w));
notWaterIdx=find(~strcmp(pools,'water'));
for iii = 1:numel(pools)
    switch peakType
        case 'lorentz'
            fit = fit + zspecSingleLorentzianModel(x((4*(iii-1)+1):(4*iii)),w);
        case 'pseudovoigt'
            if PVcharConstrain && ~strcmp(pools{iii},'water') 
                %override alpha and FWHMrat with values from 1st non-water 
                %pool (except for water) 
                x(6*(iii-1)+2)=x(6*(notWaterIdx(1)-1)+2);
                x(6*(iii-1)+4)=x(6*(notWaterIdx(1)-1)+4);
            end
            fit=fit+zspecSinglePseudoVoigtModel(x((6*(iii-1)+1):(6*iii)),w);
    end
end
res = data - fit;
if ~all(isnan(ppm_wt)) %apply ppm-specific weighting
    wt=zeros(size(w));
    for iii=1:numel(ppm_wt)
        wt=wt+exp( -(w-ppm_wt(iii)).^2 ./ 2 ./ (2/2/sqrt(2*log(2)))^2 )+.01; %Gaussian
%         wt = 1./(1+abs(w-ppm_wt));
    end
    res = res .* wt;
end
end

% zspecSingleLorentzianModel:    Generates single Lorentzian peak with input
%                               parameters
function Yhat_Single = zspecSingleLorentzianModel(p,x)
if length(p)<4
    p(4)=0;
end
% num=p(1).*0.25.*p(2).^2; %this is squared (also in the CEST literature) 
    %in contrast to the usual formula so that the peak MAX = 1,  
    %not the peak integral!
num=sqrt((p(2)/2)^2 + (x-p(3)).^2) * (p(2)/2); %at x=p(3), num=den
den=(p(2)/2)^2+(x-p(3)).^2;
ph=exp(-1i*p(4)); %zero-order phase term
Yhat_Single=p(1)*real(num./den.*ph); %p(1) dictates the amplitude
Yhat_Single=Yhat_Single-min(real(Yhat_Single)); %so that baseline remains at 0, w/ phasing
end 

% zspecSinglePseudoVoigtModel:   Generates single Pseudo-Voigt peak with 
%                               input parameters
function Yhat_Single = zspecSinglePseudoVoigtModel(p,x)
if length(p)<6
    p(6)=0;
end
sigma = p(3) / 2 / sqrt(2*log(2)) * p(4); 
% Pseudo-Voigt
G=exp( -(x-p(5)).^2 ./ 2 ./ sigma^2 );
% L=(p(3)/2)^2 ./ ( (x-p(5)).^2 + (p(3)/2)^2 ); %this is squared (also in the 
%     %CEST literature) in contrast to the usual formula so that the peak 
%     %MAX = 1, not the peak integral!
Lnum=sqrt((p(3)/2)^2 + (x-p(5)).^2) * p(3)/2; %at x=p(3), num=den
Lden=(x-p(5)).^2 + (p(3)/2)^2;
Lph=exp(-1i* ( atan((x-p(5))/(p(3)/2)) + p(6))); %includes zero-order phase term
L=Lnum./Lden.*Lph; 
% L=L-min(real(L)); %so that baseline remains at 0, w/ phasing
Yhat_Single = p(1)*real( p(2)*G + (1-p(2))*L ); %p(1) dictates the amplitude 
end 