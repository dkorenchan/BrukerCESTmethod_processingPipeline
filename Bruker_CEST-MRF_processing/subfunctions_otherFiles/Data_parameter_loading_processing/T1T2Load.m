% T1T2Load: Loads in T1 or T2 data from scanner-generated fitted DICOM maps
%
%   INPUTS:     
%       load_dir    -   String containing path to T1 or T2 map DICOM 
%                       (should end in '.../dicom/')
%       ext_dir     -   String containing path to dcm2niix
%                               executable, for DICOM > NIFTI conversion
%
%   OUTPUTS:    
%       img         -   Matrix (double) containing map of T1 or T2 values                           
%
function img = T1T2Load(load_dir,ext_dir)
% Check if conversion to NII already done - if not, do; otherwise, just
% load
home=pwd;
cd(load_dir);
if ~exist(fullfile(load_dir,'images.nii'),'file')
    system([fullfile(ext_dir,'dcm2niix*') ' .']);
    % NOTE: these next 2 lines only work if a single image series!
    system('mv *.json images.json');
    system('mv *.nii images.nii');
else
    disp('DICOM to NII conversion already performed here! Loading...')
end
img = load_untouch_nii(fullfile(load_dir,'images.nii'));
cd(home);

try
    img = squeeze(img.img(:,:,:,3));
catch
    img = squeeze(img.img(:,:,3));
end
% Adjust to match Bruker orientation
img = flip(img',1);
% Change to s from ms
img = img ./ 1000;
end