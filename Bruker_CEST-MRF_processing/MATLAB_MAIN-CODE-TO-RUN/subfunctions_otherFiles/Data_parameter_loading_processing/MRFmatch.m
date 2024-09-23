% MRFmatch: Generates acquired_data.mat with raw data from 2dseq file, then
% calls Python to perform dictionary simulation and matching, and finally
% places the resulting file in the same data directory as the 2dseq file.
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
%       prefs       -   Struct containing user specific processing options
%       PV360flg    -   Logical; if true, will process according to
%                       ParaVision 360 format (default false)       
%
%   OUTPUTS:    None (results are saved in a .mat file)
%
function MRFmatch(dirstruct,prefs,PV360flg)
disp(['MRF data: Generating acquired_data.mat for dictionary '...
     'simulation and matching...'])
read2dseq(dirstruct.loadMRF,'dictmatch',prefs,PV360flg)
copyfile(fullfile(dirstruct.loadMRF,'acquired_data.mat'),...
    fullfile(dirstruct.py_dir,'INPUT_FILES'));
disp(['MRF data: Calling Python to perform dictionary simulation '...
    'and matching...'])
home=pwd;
cd(dirstruct.py_dir)
system(['source ~/' dirstruct.bashfn ';'...
    'conda activate ' dirstruct.conda_env ';'...
    'source ' dirstruct.py_env '/bin/activate;'...
    'python ' dirstruct.py_file ';']);
movefile(fullfile(dirstruct.py_dir,'OUTPUT_FILES','quant_maps.mat'),...
    fullfile(dirstruct.loadMRF,dirstruct.MRFfn));

% Prepare filename for dot_product_results
if ~strcmp(dirstruct.MRFfn,'quant_maps.mat') %rename quant_maps.mat to correct filename
    if contains(dirstruct.MRFfn,'quant_maps')
        namepart=extractBetween(dirstruct.MRFfn,'quant_maps','.mat');
    else
        namepart=extractBefore(dirstruct.MRFfn,'.mat');
    end
    if iscell(namepart)
        namepart=namepart{:};
    end
    if ~isempty(namepart)
        if ~startsWith(namepart,'_')
            namepart=['_' namepart];
        end
    end
    % Detect file extension for dot_product_results, use for renaming
    dpr_fn=ls(fullfile('OUTPUT_FILES','dot_product_results.*'));
    dpr_fn=dpr_fn(1:end-1); %remove last character
    dprFileExt=extractAfter(dpr_fn,'dot_product_results');
    fndpr=['dot_product_results' namepart dprFileExt];
    movefile(fullfile(dirstruct.py_dir,'OUTPUT_FILES',['dot_product_results' dprFileExt]),...
        fullfile(dirstruct.loadMRF,fndpr)); 
else
    movefile(fullfile(dirstruct.py_dir,'OUTPUT_FILES','dot_product_results.*'),...
        dirstruct.loadMRF);     
end
cd(home);
end