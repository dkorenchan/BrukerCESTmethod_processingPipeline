% MATCH_MRF_MULTI: MAIN FUNCTION TO RUN - This function runs through all 
% scans within a Bruker study directory, finds which ones are MRF imaging 
% data, and performs dictionary simulation + matching for each one that 
% hasn't had it performed yet
%
% INPUTS:
%   None. User will be requested to specify the study directory via GUI
%
% OUTPUTS:
%   None. Each scan directory will have the generated MRF maps saved as a
%   .mat file with the name specified in the variable MRFfn.
%
% NOTE: If any waitbar figures are still left, perhaps due to function
% error or canceling, please run the CLOSE_WAITBARS() script, found in a
% separate file
%
function MATCH_MRF_MULTI
%% DATA LOADING
% ID Bruker study directory containing all scans, and whether PV360 was
% used to acquire the data
[configs,prefs]=initUserSettings();
[base_dir,data_dirs,PV360flg]=StudyLoad(configs);

% Search through scan directories to ID which are MRF datasets requiring 
% dictionary matching to be performed. 
disp(['Searching for MRF datasets without dictionary-matched output maps stored in ',...
    configs.MRFfn '...'])
matchdirs=FindScansByType(base_dir,data_dirs,configs);

% If the directory contains a .txt list of scans, pull that up in 
% separate fig; otherwise, if a PV360 study, generate it from the
% internal list
slfig=displayScanList(base_dir);

prompt = [  {'Please select which of the discovered MRF data'};...
            {'directories to perform dictionary matching on.'};...
            {'(COMMMAND-click or SHIFT-click to select.)'}];
choices = matchdirs;
answer = listdlg('ListString' , choices , ...
    'SelectionMode' , 'multiple' , ...
    'ListSize' , [250 500] , ...
    'PromptString' , prompt);
matchdirs=matchdirs(answer);

% Confirm with user that the selected dictionaries will be matched.
if ~isempty(matchdirs)
    prompt2 = [{'The following directories were selected:'};...
        {''};matchdirs;{''};{'Would you like to proceed?'};...
        {'(NOTE: dictionary matching may take a while!)'}];
    choices2 = {'Yes' 'No'};
    answer2 = listdlg('ListString' , choices2 , ...
        'SelectionMode' , 'single' , ...
        'ListSize' , [200 30] , ...
        'PromptString' , prompt2);
else
    answer2=0;
end

% Close protocol list box if still open
if exist('slfig','var')
    if isvalid(slfig)
        close(slfig);
    end
end

% Perform dictionary matching on selected files
if answer2 == 1
disp('Starting dictionary matching on selected scans...')
warning(['If user clicks Cancel a few times on the status bar, dictionary '...
    'matching will finish for the current scan, then abort.'])
wb = waitbar(0,'','Name','Dictionary matching progress',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
for ii=1:numel(matchdirs)
    if isvalid(wb)
        % Check for clicked Cancel button on status bar
        if getappdata(wb,'canceling')
            delete(wb);
            disp(['User cancelled dictionary matching. The following '...
                'datasets were successfully matched:'])
            disp(matchdirs(1:ii))
            break
        end
        % Update status bar and message
        waitbar(ii/numel(matchdirs),wb,['Scan directory ' matchdirs{ii} ...
            ' (' num2str(ii) ' of ' num2str(numel(matchdirs)) ')...']);
    end
    % Set up directory structure for data and Python file locations, as
    % well as the # of pools
    configs.loadMRF=fullfile(base_dir,matchdirs{ii},'pdata','1');
    disp(['Scan directory ' matchdirs{ii} ' (' num2str(ii) '/' ...
        num2str(numel(matchdirs)) '): performing dictionary matching...'])
    MRFmatch(configs,prefs,PV360flg);
    disp(['Scan directory ' matchdirs{ii} ' (' num2str(ii) '/' ...
        num2str(numel(matchdirs)) '): matching complete!'])
end
if exist('wb','var')
    delete(wb);  
end
disp(['Dictionary matching complete! All maps saved as ' configs.MRFfn ...
    ' in /pdata/1/ within each scan directory.'])
else
    disp('Dictionary matching will not be performed. Goodbye!')
end

end