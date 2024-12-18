% B0correction: Takes a B0 map and raw z-spectral imaging data and shifts
% the spectral data based upon the measured B0 shift. 
%
% Based upon code developed by Or Perlman, Oct 11, 2022
%
%   INPUTS:
%       B0map       -   Vectorized image containing the B0 map values (in
%                       ppm) for each voxel in the 1st dimension of raw_z
%       w_ppm       -   Vector of offsets used in scan (in ppm),
%                       pertaining to the spectral dimension of raw_z
%       raw_z       -   2D array of z-spectra pertaining to voxels. 1st 
%                       dimension is the voxel; 2nd dimension is spectral. 
%
%   OUTPUT:
%       B0corr_z    -   B0-corrected 3D z-spectra. Dimensions are the same as
%                       for raw_z.
%  
function B0corr_z=B0correction(B0map,w_ppm,raw_z)

%Initializing corrected masked Z images for after B0 correction
B0corr_z=zeros(size(raw_z));

parfor ind=1:size(B0corr_z,1)
    %current original z_spectrum
    Original_current_pixel_Z_vec=squeeze(raw_z(ind,:));

    %current B0 shift
    Current_B0=B0map(ind);%(Hz)

    %Correcting current pixel only if the B0shift is not zero
    if Current_B0~=0
        %Corrected Z-spectrum for this pixel
%         B0corr_z(ind,:)=spline(w_ppm-Current_B0,Original_current_pixel_Z_vec,w_ppm);
        B0corr_z(ind,:)=interp1(w_ppm-Current_B0,Original_current_pixel_Z_vec,w_ppm,...
            'makima');
    end
end

end
