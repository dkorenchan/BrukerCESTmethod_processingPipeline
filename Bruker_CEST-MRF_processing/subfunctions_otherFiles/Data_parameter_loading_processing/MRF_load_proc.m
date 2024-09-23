% MRF_load_proc: Attempts to read in the specified .mat filename containing
% MRF-matched parameter maps, and if it doesn't find it then the user is 
% prompted whether to perform dictionary matching or not. Python is called
% to perform dictionary matching
%
%   INPUTS:
%       dirstruct   -   Struct containing paths to required directories,
%                       including:
%                           .loadMRF    -   Path to MRF 2dseq file
%                           .py_dir     -   Path to .py file to perform
%                                           dictionary matching
%                           .py_file    -   Name of .py file for dictionary
%                                           matching
%                           .bashfn     -   Path to .bash file (or equivalent)
%                                           to source to run python/conda 
%                                           commands
%                           .conda_env  -   Name of conda environment to
%                                           activate
%                           .py_env     -   Name of Python environment to
%                                           also activate (currently
%                                           necessary for M1 Mac)
%                           .MRFfn      -   Name of .mat file to search for
%                                           containing dictionary-matched
%                                           parameter maps 
%       i_flds      -   Cell array containing strings of names of parameter
%                       maps       
%       prefs       -   Struct containing user specific processing options
%       PV360flg    -   Logical; if true, will process according to
%                       ParaVision 360 format (default false)
%
%   OUTPUTS:
%       img     -   Struct containing matrix (double) images of the 
%                   parameter maps. Each subfield name is one of the
%                   strings contained in input cell array i_flds
%       info    -   Struct containing information loaded from MRF dataset
%
function [img,info]=MRF_load_proc(dirstruct,i_flds,prefs,PV360flg)
if nargin < 4
    PV360flg=false;
end
disp(['MRF data: looking for ' dirstruct.MRFfn ' in scan directory...'])
if ~exist(fullfile(dirstruct.loadMRF,dirstruct.MRFfn),'file')
    prompt = {['MRF maps file ' dirstruct.MRFfn],' not found!',...
        'Would you like to run dictionary','simulation and matching now?'};
    choices={'Yes' 'No'};
    answer = listdlg('ListString',choices,...
        'SelectionMode','single' , ...
        'ListSize',[200 30], ...
        'PromptString',prompt);
    if answer == 1 %perform dictionary matching
        MRFmatch(dirstruct,prefs,PV360flg);
    else
        disp('No MRF dictionary matching will be performed....')
        disp('Replacing MRF parameter maps with dummy images...')
        [~,~,info]=read2dseq(dirstruct.loadMRF,'image',prefs,PV360flg);
        for ii=1:numel(i_flds)
            img.(i_flds{ii})=zeros(info.size(1:2));
        end
        return
    end      
else
    disp(['MRF data: ' dirstruct.MRFfn ' found! Loading...'])
end
img=load(fullfile(dirstruct.loadMRF,dirstruct.MRFfn),i_flds{:});
info=struct;

% % Orient all images to match Bruker display
% for ii=1:length(i_flds)
%     img.MRF.(i_flds{ii})=flip(flip(img.MRF.(i_flds{ii})',2),1);
% end
    
% Update fs map to be in concentration (assuming 3 protons, 55 M H2O) 
img.fs=img.fs*110000/3; % in mM
end