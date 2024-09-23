% FindScansByType: Searches through scan directories of a ParaVision study
% to ID which are MRF datasets requiring dictionary matching to be 
% performed.These criteria will be used:
%   -   ##$Method=<User:fp_EPI> (or ...:fpSL_EPI>) in "method" file
%   -   ##$Fp_FileName in "method" file does NOT contain a substring listed
%       in variable configs.notMRFstr (e.g. "quesp" or "wassr")
%   -   No file found in pdata/1/ with filename matching variable configs.MRFfn
% NOTE: This function could be generalized in the future to use for
% identifying other types of scans!
%
%   INPUTS:
%       base_dir    -   String containing path to main study directory
%       data_dirs   -   Cell array of strings containing the numbers of the
%                       scan directories found in the study directory
%       cfg         -   Struct containing user computer configuration 
%                       information  
%
%   OUTPUTS:
%       matchdirs   -   Cell array of strings containing only the numbers 
%                       of scan directories in data_dirs which match the
%                       given criteria
%
function matchdirs=FindScansByType(base_dir,data_dirs,cfg)
MRFidx=[];
for ii=1:numel(data_dirs)
    dd=data_dirs{ii};
    MRFsearchpar=readPars(fullfile(base_dir,dd),'method',...
        {'##$Method','##$Fp_FileName'});
    % First, check the $Fp_FileName to verify it doesn't include any
    % substring in variable configs.notMRFstr
    MRFschedchk=false(numel(cfg.notMRFstr),1);
    for jj=1:numel(cfg.notMRFstr)
        MRFschedchk(jj)=isempty(strfind(MRFsearchpar{2},cfg.notMRFstr{jj}));
    end
    MRFschedchk=prod(MRFschedchk); %if an MRF dataset, MRFschedchk = true
    % Then, check that the $Method is fp_EPI
%     MRFppchk=strcmp(MRFsearchpar{1},'<User:fp_EPI>');
    MRFppchk=(~isempty(strfind(MRFsearchpar{1},'fp_EPI')) | ...
        ~isempty(strfind(MRFsearchpar{1},'fpSL_EPI')));
    % Finally, verify that there isn't a file matching configs.MRFfn
    MRFfndetect=(exist(fullfile(base_dir,dd,'pdata','1',cfg.MRFfn),...
        "file")~=2);
    if MRFschedchk && MRFppchk && MRFfndetect %list dir idx if MRF
        MRFidx=[MRFidx ii];
    end
end

matchdirs=data_dirs(MRFidx); %names of directories that need dictionary matching
if isempty(matchdirs)
    error('No scan directories found compatible with/requiring dictionary matching. Function aborted.')
end
end