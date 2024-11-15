% calcMTRmap: Calculates the MTR asymmetry map for the specified ppm value
% using the z-spectroscopic imaging data
%
%   INPUTS:
%       zspecImgData    -   Array containing z-spectroscopic imaging data.
%                           Last dimension in the array is the
%                           spectroscopic dimension.
%       ppmOffsets      -   Numeric vector containing the saturation 
%                           offsets (in ppm) matching the spectroscopic
%                           dimension of zspecImgData
%       sel_ppm         -   Number pertaining to ppm value to use to
%                           calculate MTR asymmetry map
%
%   OUTPUTS:
%       MTRmap          -   Array containing MTR asymmetry image. The
%                           dimensions are identical to zspecImgData except
%                           it is one dimension less (since there is now no
%                           spectroscopic dimension)
%
function MTRmap=calcMTRmap(zspecImgData,ppmOffsets,sel_ppm)
% Find the indices pertaining to the positive and negative ppm values
zImgPos=zspecImgData(:,:,abs(sel_ppm-ppmOffsets)==min(abs(sel_ppm-ppmOffsets)));
zImgNeg=zspecImgData(:,:,abs(-sel_ppm-ppmOffsets)==min(abs(-sel_ppm-ppmOffsets)));
MTRmap=squeeze(zImgNeg-zImgPos);
end