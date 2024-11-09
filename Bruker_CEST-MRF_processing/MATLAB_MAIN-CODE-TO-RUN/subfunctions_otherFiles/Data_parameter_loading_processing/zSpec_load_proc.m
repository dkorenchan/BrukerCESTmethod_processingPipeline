function [zImg,M0img,info]=zSpec_load_proc(load_dir,prefs,PV360flg)
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

disp('Z-spectroscopic imaging data: thresholding images based upon SNR...')
Noise=M0img(Noise_mask>0);
% N=std(Noise);
% Thmask=(M0_wassr>N);
N=mean(Noise);
Thmask=(M0img>15*N);

% Apply SNR mask to images
zImg = zImg.*repmat(Thmask,[1 1 size(zImg,3)]);

end