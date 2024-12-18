% zSpec_load_proc: Loads in z-spectroscopy data from 2dseq file, does SNR
% thresholding and voxelwise z-spectral peak fitting. If non-empty B0 map 
% is supplied as input, this is used for B0 correction prior to fitting
% z-spectra.
%
%   INPUTS:
%       load_dir    -   String containing path to WASSR 2dseq file
%       b0map       -   Matrix (double) containing B0 map values (in ppm); 
%                       can be specified as empty ([]) if no B0 correction 
%                       is to be performeds     
%       prefs       -   Struct containing user specific processing options
%       PV360flg    -   Logical; if true, will process according to
%                       ParaVision 360 format (default false)
%
%   OUTPUTS:    
%       zImg        -   Matrix (double) containing the z-spectral values
%                       for each imaging voxel. Dimensions are (spatial,
%                       spatial, spectral).
%       M0img       -   Matrix (double) containing the unsaturated image
%       fitAmplMaps -   Struct containing the maps of the fitted z-peak 
%                       amplitudes. Fieldnames pertain to the list of
%                       pools.
%       fitPeakMaps -   Struct containing the fitted z-peak profiles for 
%                       each imaging voxel. Fieldnames pertain to the list
%                       pools, plus a fieldname 'all' containing the sum of
%                       all the fitted peaks. Each array has the same 
%                       dimensions as zImg.
%       info        -   Struct containing acquisition information
%                       pertaining to z-spectral data.
%

function [zImg,M0img,fitAmplMaps,fitPeakMaps,info]=...
    zSpec_load_proc(load_dir,b0map,prefs,PV360flg)
%% DATA LOAD, SNR THRESHOLD
% Load in data
[rawImg,M0img,info]=read2dseq(load_dir,'cest',prefs,PV360flg);
rawImg=squeeze(rawImg); %so that (for a 1-slice acq) it'll have 3 dimensions
zImg=rawImg./repmat(M0img,[1,1,size(rawImg,3)]); %divide by M0 to get z-spec

% Define noise region for SNR mask
fh=figure;
imagesc(M0img); colormap(gray);
disp('Z-spectroscopic imaging data: draw background noise ROI (double-click in selected ROI when done)');
Noise_mask=imcrop;
close(fh); 

% Calculate noise
disp('Z-spectroscopic imaging data: thresholding images based upon SNR...')
Noise=M0img(Noise_mask>0);
% N=std(Noise);
% Thmask=(M0_wassr>N);
N=mean(Noise);
Thmask=(M0img>10*N);

% Apply SNR mask to images
zImg=zImg.*repmat(Thmask,[1 1 size(zImg,3)]);


%% USER GUI SPECIFICATIONS
% Bring up GUI for user to set processing parameters: which pools to fit,
% what type of lineshape (Lorentzian, Pseudo-Voigt), whether to use B0 
% correction (if WASSR data specified), etc.
%DK: TO DO!
zppars.pools={'water','NOE','MT','amide'};
zppars.peaktype='Pseudo-Voigt';
zppars.water1st=false;


%% Z-SPECTROSCOPY PROCESSING: (B0 CORRECTION,) FITTING

% Reshape z-spectral data and SNR threshold mask, then select all voxels 
% pertaining to SNR thresholding
zImgSelVox=reshape(zImg,prod(size(zImg,[1,2])),[]);
ThmaskIdxVec=find(reshape(Thmask,prod(size(Thmask,[1,2])),[]));
zImgSelVox=zImgSelVox(ThmaskIdxVec,:);

ppm=info.w_offsetPPM;

if ~isempty(b0map)
    disp('Z-spectroscopic imaging data: using loaded B0 map to perform B0 correction...')
    % Vectorize b0map just as for the zImgSelVox
    b0map=reshape(b0map,[],1);
    b0map=b0map(ThmaskIdxVec); %select same voxels as for zImgSelVox
    zImgSelVox=B0correction(b0map,ppm,zImgSelVox);
end

[fittedAmpls,fittedPeaksIndiv,fittedPeaksAll]=fitAllZspec(ppm,zImgSelVox,zppars);

% Fill in output maps in vector format, then reshape into 2D maps
for ii=1:numel(zppars.pools)
    fitAmplMaps.(zppars.pools{ii})=zeros(size(zImg,[1,2]));
    fitAmplMaps.(zppars.pools{ii})(ThmaskIdxVec)=fittedAmpls(ii,:);

    fPM.(zppars.pools{ii})=zeros(prod(size(zImg,[1,2])),size(zImg,3));
    for jj=1:numel(ThmaskIdxVec)
        idx=ThmaskIdxVec(jj);
        fPM.(zppars.pools{ii})(idx,:)=fittedPeaksIndiv(ii,jj,:);
    end
    fitPeakMaps.(zppars.pools{ii})=reshape(fPM.(zppars.pools{ii}),size(zImg));
end
fPM.all=zeros(prod(size(zImg,[1,2])),size(zImg,3));
for ii=1:numel(ThmaskIdxVec)
    idx=ThmaskIdxVec(ii);
    fPM.all(idx,:)=fittedPeaksAll(ii,:);
end
fitPeakMaps.all=reshape(fPM.all,size(zImg));

% Update zImg with B0-corrected spectra
zImgsize=size(zImg);
zImg=reshape(zImg,prod(size(zImg,[1,2])),[]);
for ii=1:numel(ThmaskIdxVec)
    zImg(ThmaskIdxVec(ii),:)=zImgSelVox(ii,:);
end
zImg=reshape(zImg,zImgsize);

end