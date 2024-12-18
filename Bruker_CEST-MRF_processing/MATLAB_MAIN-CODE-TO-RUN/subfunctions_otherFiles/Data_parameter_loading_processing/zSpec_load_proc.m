function [zImg,M0img,fitAmplMaps,fitPeakMaps,info]=...
    zSpec_load_proc(load_dir,prefs,PV360flg)
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
zImg = zImg.*repmat(Thmask,[1 1 size(zImg,3)]);


%% USER GUI SPECIFICATIONS
% Bring up GUI for user to set processing parameters: which pools to fit,
% what type of lineshape (Lorentzian, Pseudo-Voigt), whether to use B0 
% correction (if WASSR data specified), etc.
%DK: TO DO!
zppars.pools={'water','NOE','MT','amide'};
zppars.peaktype='Pseudo-Voigt';
zppars.water1st=false;


%% Z-SPECTROSCOPY PROCESSING: B0 CORRECTION, FITTING
           
% Reshape z-spectral data and SNR threshold mask, then select all voxels 
% pertaining to SNR thresholding
zImgSelVox=reshape(zImg,prod(size(zImg,[1,2])),[]);
ThmaskIdxVec=find(reshape(Thmask,prod(size(Thmask,[1,2])),[]));
zImgSelVox=zImgSelVox(ThmaskIdxVec,:);

ppm=info.w_offsetPPM;
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

end