% StudyLoad: Prompts user to select study directory, then pulls in all scan 
% directory numbers from study directory and sorts in descending order.
% Also detects whether ParaVision 360 or an earlier version was used to
% acquire the data in the study.
%
%   INPUTS:
%       cfg         -   Struct containing user computer configuration 
%                       information       
%
%   OUTPUTS:
%       base_dir    -   String containing path to main study directory
%       data_dirs   -   Cell array of strings containing the numbers of the
%                       scan directories found in the study directory
%       PV360flg    -   Logical indicating whether the selected study is
%                       identified as being obtained with ParaVision 360
%                       (true) or an older ParaVision version (false)
%
function [base_dir,data_dirs,PV360flg]=StudyLoad(cfg)
% Prompt user to ID Bruker study directory containing all scans
disp('Please specify study directory containing all scan directories:')
[base_dir,data_dirs]=loadDirectories(cfg.load_dir);

% ID whether ParaVision version is PV360, or older, and set PV360flg
% accordingly
PVverstr=readPars(fullfile(base_dir),'subject',{'##TITLE'});
if contains(PVverstr,'ParaVision 360','IgnoreCase',true)
    PV360flg=true;
    disp('ParaVision version detection for study: PV360')
else
    PV360flg=false;
    disp('ParaVision version detection for study: PV 7 or below')        
end

% ID scan directories in specified study directory
data_dirs=data_dirs(~strcmp(data_dirs,'AdjResult')); %remove AdjResult
data_dirs=cellstr(num2str(sort(str2double(data_dirs)))); %sort descending
data_dirs=erase(data_dirs,' '); %erase extra spaces generated
data_dirs(strcmp(data_dirs,'NaN'))=[]; %remove any 'NaN' entries
end