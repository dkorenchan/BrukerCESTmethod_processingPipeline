% fitAllZspec.m: Takes inputted z-spectra and desired parameters, and
% performs fitting of all the z-spectra, returning the fitted peak curves
% and amplitudes
%
% INPUTS:
%   ppm     -   Vector containing ppm values for z-spectra
%   zSpec   -   2D array of z-spectra. Spectral dimension is the 2nd
%               dimension
%   zppars  -   Struct containing the following fields for specifying how
%               z-spectra should be fit:
%                   .pools      -   Cell array of strings for names of 
%                                   peaks to be fit
%                   .peaktype   -   String of type of peak fitting: 
%                                   'Lorentzian' or 'Pseudo-Voigt'
%                   .water1st   -   Logical indicating whether water (and
%                                   other peaks with negative ppm
%                                   components) should be fit before all
%                                   other peaks
%
% OUTPUTS:
%   fittedAmpls         -   2D array of fitted peak amplitudes for all 
%                           pools. 1st dimension is the pools, matching the 
%                           order of zppars.pools. 2nd dimension is the 
%                           index of the input z-spectrum in zspec.
%   fittedPeaksIndiv    -   3D array of fitted peak curves. First 2 
%                           dimensions are same as fittedAmpls; 3rd
%                           dimension is the spectral dimension.
%   fittedPeaksAll      -   2D array of sum of all fitted peak curves. 1st
%                           dimension is the index of the input z-spectrum 
%                           in zspec. 2nd dimension is the spectral 
%                           dimension.
%
function [fittedAmpls,fittedPeaksIndiv,fittedPeaksAll]=...
    fitAllZspec(ppm,zSpec,zppars)
% Perform B0 correction, if specified
%DK: TO DO!

% Set up fitting parameters, based upon which type of peaks
if strcmp(zppars.peaktype,'Pseudo-Voigt')
    disp('Performing Pseudo-Voigt peak fitting of z-spectra...')
    npar=6; % # of parameters defining each Pseudo-Voigt peak
    pfitvals=zspecSetPVPeakBounds;
elseif strcmp(zppars.peaktype,'Lorentzian')
    disp('Performing Lorentzian peak fitting of z-spectra...')
    npar=4; % # of parameters defining each Lorentzian peak
    pfitvals=zspecSetLPeakBounds;
end

% Check for water, NOE, and MT pools specified, in order to fit first (if
% zppars.water1st=true)
firstnames=zppars.pools(strcmp(zppars.pools,'water')|...
    strcmp(zppars.pools,'NOE')|strcmp(zppars.pools,'MT')); 

% Initialize variables to store fitted data in
fittedAmpls=zeros(numel(zppars.pools),size(zSpec,1));
fittedPeaksIndiv=zeros([numel(zppars.pools),size(zSpec)]);
fittedPeaksAll=zeros(size(zSpec));

% Reduce broadcast variables for parallel loop 
pools=zppars.pools;
nPools=numel(zppars.pools);
water1stflg=zppars.water1st;

% Start parallel loop for voxelwise fitting 
tic;
parfor ii=1:size(zSpec,1)
    zfit=1-squeeze(zSpec(ii,:));

%     % If zppars.phaseMTR=true, first add linear phase to the 
%     % spectrum such that the signal amplitudes at each end of the 
%     % spectrum are equal
%     if zppars.phaseMTR
%         linphase=lsqnonlin(@(x) zspecMTRphase(x,ppm,...
%             1-squeeze(ZImgSelVox(ii,:))));
%         MTR=(1-squeeze(ZImgSelVox(ii,:))).*exp(-1i)
%     else
%     end

    % If zppars.water1st=true, fit for water, NOE, and MT pools using 
    % negative ppm values only prior to fitting other peaks
    if water1stflg
        EPfirst=zspecMultiPeakFit(ppm,zfit,firstnames,pfitvals);
    else
        for jj=1:nPools
            name=pools{jj};
            EPfirst.(name)=NaN(npar,1);
        end
    end
    
    % Then, fit the rest of the peaks
    [EP,~,~,full_fit,ind_fits]=zspecMultiPeakFit(ppm,zfit,pools,pfitvals,EPfirst);

    % Store peak amplitudes plus fitted peak vectors, and reset fixvals
    fittedPeaksAll(ii,:)=full_fit;
    for jj=1:nPools
        name=pools{jj};
        fittedAmpls(jj,ii)=EP.(name)(1);
        fittedPeaksIndiv(jj,ii,:)=ind_fits.(name);
    end
end
toc;
end