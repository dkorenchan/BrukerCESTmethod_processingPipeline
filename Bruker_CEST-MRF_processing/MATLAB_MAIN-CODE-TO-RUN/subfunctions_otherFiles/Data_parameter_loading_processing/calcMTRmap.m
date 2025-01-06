% calcMTRmap: Calculates the MTR asymmetry map using the z-spectroscopic 
% imaging data. If a specific ppm value is specified, only the MTR
% asymmetry value pertaining to that value will be returned; otherwise, all
% MTR asymmetry values for each positive-negative offset pair will be
% returned. MTR asymmetry is Z_negativePPM - Z_positivePPM.
%
%   INPUTS:
%       zspecImgData    -   Array containing z-spectroscopic (imaging) data.
%                           Last dimension in the array is the
%                           spectroscopic dimension.
%       ppmOffsets      -   Numeric vector containing the saturation 
%                           offsets (in ppm) matching the spectroscopic
%                           dimension of zspecImgData
%       sel_ppm         -   (optional) Number pertaining to ppm value to 
%                           use to calculate MTR asymmetry map; otherwise,
%                           MTR asymmetry is calculated across all ppm
%                           values
%
%   OUTPUTS:
%       MTRmap          -   Array containing MTR asymmetry image or spectra. 
%                           All but the last dimension are identical to 
%                           zspecImgData. The last dimension will be 1 if
%                           sel_ppm was specified; otherwise it will be the
%                           length of positive-negative offset pairs
%                           identified
%       MTRppm          -   Vector of positive ppm values pertaining to the
%                           (now-reordered) MTRmap spectral dimension
%
function [MTRmap,MTRppm]=calcMTRmap(zspecImgData,ppmOffsets,sel_ppm)
% DK TO DO: Update to be compatible w/ computing the MTR profile for the
% ROI-average zspec: if/then loop for 2D vs 3D array; and make sel_ppm an
% optional input 
% Detect whether input sel_ppm was specified
if nargin<3
    selppmflg=false;
else
    selppmflg=true;
end

zsIDsize=size(zspecImgData);
if length(zsIDsize)>2 
    % Reshape zspecImgData to have only 2 dimensions
    zspecImgData=reshape(zspecImgData,[],zsIDsize(end));
end

% Reorder both ppmOffsets and zspecImgData (in spectroscopic dimension) to
% be increasing in offset
[ppmOffsets,sortIdx]=sort(ppmOffsets,'ascend');
zspecImgData=zspecImgData(:,sortIdx);

% Determine the z-spec values for the positive and negative ppm values
if selppmflg
    % Find the indices pertaining to positive and negative sel_ppm
    zImgPos=zspecImgData(:,abs(sel_ppm-ppmOffsets)==min(abs(sel_ppm-ppmOffsets)));
    zImgNeg=zspecImgData(:,abs(-sel_ppm-ppmOffsets)==min(abs(-sel_ppm-ppmOffsets)));
else
    % Go through the positive offsets and find the negative offset that is
    % closest in magnitude to each
    ppmPosIdx=find(ppmOffsets>0);
    ppmPosIdxPaired=ppmPosIdx;
    ppmNegIdxPaired=zeros(size(ppmPosIdxPaired));
    for ii=1:length(ppmPosIdxPaired)
        searchVec=abs(ppmOffsets(ppmOffsets<0)+ppmOffsets(ppmPosIdxPaired(ii)));
        ppmNegIdxPaired(ii)=find(searchVec==min(searchVec)); %find value closest to zero
    end
    % Finally, ID the positive and negative offset Z-values
    zImgPos=zspecImgData(:,ppmPosIdxPaired);
    zImgNeg=zspecImgData(:,ppmNegIdxPaired);
end

% Calculate the MTR asymmetry (and corresponding positive ppm offsets)
MTRmap=squeeze(zImgNeg-zImgPos);
MTRppm=ppmOffsets(ppmOffsets>0);

% Reshape MTRmap to match input zspecImgData (except the last dimension!)
MTRmsize=size(MTRmap);
if length(zsIDsize)>2    
    MTRmap=reshape(MTRmap,[zsIDsize(1:end-1) MTRmsize(end)]);
end
end