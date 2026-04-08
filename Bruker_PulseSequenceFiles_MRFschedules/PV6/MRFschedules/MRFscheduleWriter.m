%% NAME OF FILE
filenameroot='CEST_3,5uT';


%% MRF PARAMETERS
niter=50;       % # of iterations

% NOTE: Make each array a COLUMN vector (niter x 1)
% TR [ms]
TR_ms=8000*ones(niter,1);

% Saturation/locking amplitudes [uT]
B1_uT=3.5*ones(niter,1);

% Offsets [ppm]
offsets_ppm=zeros(niter,1);
offsets_ppm(1)=100;
offsets_ppm(2:2:10)=9:-1:5;
offsets_ppm(3:2:11)=-9:1:-5;
offsets_ppm(10:2:end)=5:-.25:0;
offsets_ppm(11:2:end-1)=-5:.25:-.25;

% Excitation flip angle prior to imaging [deg]
excitFA_deg=90*ones(niter,1);

% Saturation/locking pulse duration [ms]
Tsat_ms=3000*ones(niter,1);

% Saturation [0] or spin-lock [1]
sat_or_SL=zeros(niter,1);

% Pre- and post-spin-lock preparation tip angle [deg]
% (leave as 0 to auto-calculate)
SLprepFA_deg=zeros(niter,1);


%% PARAMETER SAVING
% Convert numbers to strings
TR_ms_write=cellstr(num2str(TR_ms,'%5.0f'));
B1_uT_write=cellstr(num2str(B1_uT,'%2.1f'));
offsets_ppm_write=cellstr(num2str(offsets_ppm,'%2.2f'));
excitFA_deg_write=cellstr(num2str(excitFA_deg,'%3.1f'));
Tsat_ms_write=cellstr(num2str(Tsat_ms,'%5.0f'));
sat_or_SL_write=cellstr(num2str(sat_or_SL));
SLprepFA_deg_write=cellstr(num2str(SLprepFA_deg,'%3.1f'));

% Write values to cell array
savearray=cell(niter+2,7);
savearray(1,1)={niter};
savearray(2:end-1,1)=TR_ms_write;
savearray(2:end-1,2)=B1_uT_write;
savearray(2:end-1,3)=offsets_ppm_write;
savearray(2:end-1,4)=excitFA_deg_write;
savearray(2:end-1,5)=Tsat_ms_write;
savearray(2:end-1,6)=sat_or_SL_write;
savearray(2:end-1,7)=SLprepFA_deg_write;
% Include annotations at end to ID what values mean
savearray(end,1)={'TR[ms] |'};
savearray(end,2)={'Ampl[uT] |'};
savearray(end,3)={'Offset[ppm] |'};
savearray(end,4)={'Excit FA[deg] |'};
savearray(end,5)={'Sat/lock time[ms] |'};
savearray(end,6)={'SL[1] or sat[0] |'};
savearray(end,7)={'SL prep FA[deg]'};

% Save as .txt file
writecell(savearray,[filenameroot '.txt'],'Delimiter','tab');
disp(['MRF schedule saved as ' filenameroot '.txt']);