% saveImgROImatFile: Open browser window to save data as .mat. Variables 
% saved are img and roi.
%
%   INPUTS:
%       cfg         -   Struct containing subfields describing user
%                       configuration settings: paths to load/save 
%                       folders, scripts, etc.
%       img         -   Struct containing images
%       roi         -   Struct containing ROI data
%
%   OUTPUTS:    None
%
function saveImgROImatFile(cfg,img,roi)
home=pwd;
cd(cfg.save_dir)
[sfile , spath] = uiputfile('*.mat' , 'Save Workspace Variables As');
if isequal(sfile , 0) || isequal(spath , 0)
    prompt = {'Are you sure you do not want to save your data?'};
    choices = {'Yes' 'No'};
    answer = listdlg('ListString' , choices , ...
        'SelectionMode' , 'single' , ...
        'ListSize' , [200 30] , ...
        'PromptString' , prompt);
    if answer == 1
        cd(home);
        disp('Data were not saved....');
    end
else
    save(fullfile(spath,sfile),'img','roi');
    cd(home);
    disp(['All images and ROI data saved in ',fullfile(spath,sfile),'!']);
end