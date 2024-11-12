% WASSRload: Loads in WASSR data from 2dseq file, does thresholding and 
% Lorentzian fitting for B0 map
%
%   INPUTS:
%       load_dir    -   String containing path to WASSR 2dseq file
%       prefs       -   Struct containing user specific processing options
%       PV360flg    -   Logical; if true, will process according to
%                       ParaVision 360 format (default false)
%
%   OUTPUTS:    
%       b0map       -   Matrix (double) containing the B0 map values
%       m0map       -   Matrix (double) containing the amplitudes of the 
%                       fitted Lorentzians
%       noisemap    -   Matrix (double) containing the amplitudes of the 
%                       fitted noise
%
function [b0map,m0map,noisemap,info]=WASSR_load_proc(load_dir,prefs,PV360flg)
if nargin<2
    prefs=struct;
    PV360flg=false;
elseif nargin<3
    PV360flg=false;
end
[MI_wassr,M0_wassr,info]=read2dseq(load_dir,'wassr',prefs,PV360flg);

w1=info.satpwr_uT*42.577;  % saturation power in Hz
w_offset1=info.w_offset1;  % saturation offsets in Hz (lowest to highest)
% wSp = -150:1:150;     % interpolation frequency range

% Define noise region for SNR mask
fh=figure;
imagesc(M0_wassr); colormap(gray);
disp('WASSR data: draw background noise ROI (double-click in selected ROI when done)');
Noise_mask=imcrop;
close(fh); 

disp('WASSR data: thresholding images based upon SNR...')
Noise=M0_wassr(Noise_mask>0);
N=std(Noise);
Thmask=(M0_wassr>10*N);

% Apply SNR mask to images
Mzb0 = MI_wassr.*repmat(Thmask,[1 1 size(MI_wassr,3)]);

Mzb0vec=reshape(Mzb0,[],size(Mzb0,3));
idx=find(Mzb0vec(:,1)>0);
Mzb0fit=Mzb0vec(idx,:);

wnew=min(w_offset1):1:max(w_offset1);

% Initialize vectors to contain fitted values
b0fit=zeros(size(idx));
m0fit=zeros(size(idx));
noisefit=zeros(size(idx));

lorfcn=@lorentz_iN;

disp('WASSR data: Lorentzian fitting for B0 map...')
tic

parfor iii=1:length(Mzb0fit)
    mb0=Mzb0fit(iii,:);
    [~,yy0]=min(spline(w_offset1,mb0,wnew));
    x0=wnew(yy0);

    par0=[x0,50,w1*2,0.05]; %initial guess of A1, w1, A2, w2, A3, w3
    lb=[x0-200,1e-3,1,0];
    ub=[x0+200,1000,500,1];
    options=optimset('MaxFunEvals',1000000,'TolFun',1e-10,'TolX',1e-10,...
        'Display','off');
    % par = fminsearch(lorfcn,par0,options, wb0',mb0./max(mb0));
    par=lsqcurvefit(lorfcn,par0,w_offset1',mb0'./max(mb0),lb,ub,options);
    b0fit(iii)=par(1);
    m0fit(iii)= par(2);
    noisefit(iii)=par(4);
end

% Define final map vectors, fill in the fitted values, then reshape back to
% images
b0map=zeros(size(Mzb0vec,1),1);
m0map=zeros(size(Mzb0vec,1),1);
noisemap=zeros(size(Mzb0vec,1),1);

b0map(idx)=b0fit;
m0map(idx)=m0fit;
noisemap(idx)=noisefit;

b0map=reshape(b0map,size(Mzb0,[1,2]));
m0map=reshape(m0map,size(Mzb0,[1,2]));
noisemap=reshape(noisemap,size(Mzb0,[1,2]));

toc
end

% Lorentzian function used for fitting
%
function y_fit = lorentz_iN(par, delta)     %, delta, y)
denum = 1+(par(3)./(delta-par(1))).^2;
% y_fit = sqrt( par(4)^2+(par(2)./denum+par(4)).^2);
y_fit = par(4) + par(2)./denum;
% y_fit = sum(sum(abs(sqrt(par(4) + (par(2)./denum).^2)-y)));
end