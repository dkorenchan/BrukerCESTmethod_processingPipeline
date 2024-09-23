% PROC_MRF_STUDY: MAIN FUNCTION TO RUN - this function coordinates user
% selection of study direction to process, selection of scan directories to
% process pertaining to different imaging datasets (CEST MR fingerprinting,
% T1/T2 maps, QUESP, WASSR B0 mapping), region-of-interest drawing and
% statistical analysis via interactive GUI, and data saving.
%
% INPUTS:
%   previmg:    (optional) Structure containing previously loaded images
%               - If only prevroi specified, use [] for previmg
%   prevroi:    (optional) Structure containing previously drawn ROIs
%
% OUTPUTS:
%   img:        Structure containing all loaded images
%   roi:        Structure containing drawn ROIs
%  
function [img,roi] = PROC_MRF_STUDY(previmg,prevroi) 
%% FUNCTION INITIALIZATION

home=pwd;

[configs,prefs]=initUserSettings();

i_flds=initPlotParams;

% Detect if previous images/ROIs inputted
if nargin==2 
    if isempty(previmg)
        roi=prevroi;
        loadflg=true;
    else
        img=previmg;
        roi=prevroi;
        loadflg=false;
    end
elseif nargin==1
    img=previmg;
    loadflg=false;
    roi=struct;
else
    loadflg=true; 
    roi=struct;
end


%% DATA LOADING
if loadflg
    % Prompt user to choose the study directory, then each scan directory
    % pertaining to the desired datasets to process and analyze
    [base_dir,scan_dirs,PV360flg]=StudyLoad(configs);
    datatypes={'MRF','QUESP','T1map','T2map','WASSR'};
    datadirs=ScanChoose(configs,base_dir,scan_dirs,datatypes,PV360flg);

    % Identify any datasets which were not specified
    for ii=1:numel(datatypes)
        specifiedflg.(datatypes{ii})=~strcmp(datadirs.(datatypes{ii}),'Select:');
    end
    if ~prod(cell2mat(struct2cell(specifiedflg))) 
        disp('The following data types were not specified and therefore will not be loaded:')
        for ii=1:numel(datatypes)
            if ~specifiedflg.(datatypes{ii})
                disp(['  ' datatypes{ii}]);
            end
        end
        % Do not load QUESP if T1 not specified (since it's a required
        % input)
        if specifiedflg.QUESP && ~specifiedflg.T1map
            specifiedflg.QUESP=false;
            disp('  QUESP (since it requires a T1 map)');
        end
    end

    % Load and process all datasets, storing the resultant images in struct
    % img
    img=LoadAllSelectedDatasets(specifiedflg,datadirs,i_flds,configs,prefs,...
        PV360flg);
end


%% ROI DRAWING ON INTERACTIVE FIGURE
% Create GUI for user to view resulting images, draw ROIs, and perform
% additional processing steps. Return modified img and roi structs at end
[img,roi]=imageDispGUI(img,roi,specifiedflg,datadirs,prefs,PV360flg);


%%  DATA SAVING
% Write table to .csv file
if isfield(roi,'mask')
    cd(configs.save_dir)
    rtcsv = calcROIsCSV(roi,'MRF');
    writetable(rtcsv,'MRFproc.csv','Delimiter',',');
    disp('ROI data for MRF imaging written to MRFproc.csv')
    rtcsv = calcROIsCSV(roi,'other');
    writetable(rtcsv,'MRFproc_other.csv','Delimiter',',');  
    disp('ROI data for other imaging data written to MRFproc_other.csv')
    cd(home)
end

% Prompt user to save img and roi as .mat file
saveImgROImatFile(configs,img,roi);

end