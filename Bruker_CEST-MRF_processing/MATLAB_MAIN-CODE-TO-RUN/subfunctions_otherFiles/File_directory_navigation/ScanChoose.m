% ScanChoose: Prompts user to select the scan numbers pertaining to desired 
% image datasets to analyze.
%
%   INPUTS:
%       cfg         -   Struct containing user computer configuration 
%                       information 
%       base_dir    -   String containing path to main study directory
%       scan_dirs   -   Cell array of strings containing the numbers of the
%                       scan directories found in the study directory
%       datatypes   -   Cell array of strings pertaining to types of
%                       imaging datasets
%       PV360flg    -   Logical indicating whether the selected study is
%                       identified as being obtained with ParaVision 360
%                       (true) or an older ParaVision version (false)
%
%   OUTPUTS:
%       datadirs    -   Struct containing the selected directory (as a 
%                       string) pertaining to each dataset type in input 
%                       variable datatypes
%
function datadirs=ScanChoose(cfg,base_dir,scan_dirs,datatypes)
%% MAIN FUNCTION
scan_dirs=[{'Select:'};scan_dirs]; %add default option at beginning 

% Pull in directories specified last time, and set to default values in 
% scan directory selection figure
if exist(fullfile(cfg.save_dir,'savepars.mat'),'file')
    load(fullfile(cfg.save_dir,'savepars.mat'),'datadirs');
    % Check that all saved directory numbers are contained in study
    % directory
    if sum(matches(struct2cell(datadirs),scan_dirs))<numel(datatypes)
        for ii=1:numel(datatypes)
            datadirs.(datatypes{ii})='Select:';
        end   
    else
        disp('Previous scan directory selections successfully loaded...')
    end
else
    for ii=1:numel(datatypes)
        datadirs.(datatypes{ii})='Select:';
    end
end

% Initialize scan selection figure
dfig=uifigure;
uilabel(dfig,'Position',[10 220 400 40],'WordWrap','on',...
    'Text',['Please specify the directory for each image dataset below. '...
    'If not loading a dataset, leave at the default value ("Select:").']);
% Create a separate dropdown item for each element in datatypes
for ii=1:numel(datatypes)
    uilabel(dfig,'Position',[100*(ii-1)+10 150 80 20],'Text',datatypes{ii});
    uidropdown(dfig,'Position',[100*(ii-1)+10 120 80 20],'Tag',datatypes{ii},...
        'Items',scan_dirs,'ValueChangedFcn',@setDataDir,...
        'Value',datadirs.(datatypes{ii}));
end
uibutton(dfig,'Position',[20 60 300 20],'Text','Continue',...
    'ButtonPushedFcn',@endDirSet);
wl=uilabel(dfig,'Position',[20 20 400 40],'Text','','FontColor','r',...
    'WordWrap','on');

% If the directory contains a .txt list of scans, pull that up in 
% separate fig; otherwise, if a PV360 study, generate it from the
% internal list
slfig=displayScanList(base_dir);

waitfor(dfig);

% Save directory selections to savepars.mat for future loading
save(fullfile(cfg.save_dir,'savepars.mat'),'datadirs');

% Then, add base_dir to datadirs (we don't want it appearing next time in
% datadirs!)
datadirs.base_dir=base_dir;


%% INTERNAL CALLBACK FUNCTIONS FOR UI ELEMENTS


% setDataDir: assigns data directory to a particular image type
function setDataDir(src,~)
datadirs.(src.Tag) = src.Value;
end


% endDirSet: checks that no directory was chosen twice, then closes 
% directory specification panel and continues with function
function endDirSet(~,~)

% Verify that QUESP was not specified without a T1map also, since the T1map
% is required for QUESP fitting
if ~strcmp(datadirs.QUESP,'Select:') && strcmp(datadirs.T1map,'Select:')
    set(wl,'Text',['QUESP alone cannot be specified; a T1 map must be '...
        'specified with it!']);
else
    seldirs=struct2cell(datadirs);
    seldirs=seldirs(~strcmp(seldirs,'Select:'));

    if isempty(seldirs) % make sure at least one type of dataset is specified
        set(wl,'Text','At least one directory must be specified!');    
    elseif numel(unique(seldirs))==numel(seldirs)
        close(dfig)
        if exist('slfig','var') %also close scan directory list if open
            try
                close(slfig);
            catch
            end
        end
    else %make sure no directories were specified as multiple data types
        set(wl,'Text',['A directory was specified as more than one image type! '...
            'Please ensure that each directory is specified only once.']);
    end
end
end
end