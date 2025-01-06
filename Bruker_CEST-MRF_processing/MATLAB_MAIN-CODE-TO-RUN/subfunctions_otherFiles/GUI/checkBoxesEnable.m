% checkBoxesEnable: Checks to see whether user should be allowed to set
% roi(1).fixConcQUESPflg (i.e. whether all ROIs have valid specified
% nominal concentration values) or roi(1).useNomExchflg (i.e. whether all 
% ROIs have valid specified nominal exchange values). Update GUI elements 
% and output logical result.
%
%   INPUTS:
%       roi             -   Struct containing ROI data 
%       chkbxHandles    -   Struct containing handles to checkbox UI
%                           elements and associated labels
%
%   OUTPUTS:    
%       roi             -   Struct containing ROI data, now with updated
%                           flags indicating whether to use nominal or
%                           QUESP-calculated values
%
function roi=checkBoxesEnable(roi,chkbxHandles)

nROI=numel(roi);

% Check for nomConc-related checkbox
if isfield(roi,'nomConc')
    if sum(isnan([roi.nomConc])+isinf([roi.nomConc]))>0 || ...
            length([roi.nomConc])<nROI
        roi(1).fixConcQUESPflg=false;
        set(chkbxHandles.ncf,'Enable','off');
        set(chkbxHandles.ncft,'Enable','off');
    else
        set(chkbxHandles.ncf,'Enable','on');
        set(chkbxHandles.ncft,'Enable','on');
    end
else
    roi(1).fixConcQUESPflg=false;
    set(chkbxHandles.ncf,'Enable','off');
    set(chkbxHandles.ncft,'Enable','off');
end
% Check for nomExch-related checkbox
if isfield(roi,'nomExch')
    if sum(isnan([roi.nomExch])+isinf([roi.nomExch]))>0 || ...
            length([roi.nomExch])<nROI
        roi(1).useNomExchflg=false;
        set(chkbxHandles.nee,'Enable','off');
        set(chkbxHandles.neet,'Enable','off');
    else
        set(chkbxHandles.nee,'Enable','on');
        set(chkbxHandles.neet,'Enable','on');
    end
else
    roi(1).useNomExchflg=false;
    set(chkbxHandles.nee,'Enable','off');
    set(chkbxHandles.neet,'Enable','off');
end
end