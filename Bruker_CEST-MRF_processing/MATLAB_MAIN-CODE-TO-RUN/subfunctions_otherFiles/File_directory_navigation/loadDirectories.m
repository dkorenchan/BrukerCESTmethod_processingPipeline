% loadDirectories: Allows user to specify Bruker study directory, then 
% outputs this directory plus a cell array of the other data directory 
% names.
%
%   INPUTS:
%       load_path   -   String containing full path to starting directory  
%                       to begin searching for study directory from 
%
%   OUTPUTS:
%       parentdir   -   String containing full path to study directory
%       childdir    -   Cell array of strings containing names of scan
%                       directories within study
%
function [parentdir,childdir] = loadDirectories(load_path)
% Prompt user to specify folder containing data directories
%
while 1
    parentdir = uigetdir(load_path, ...
        'Specify folder containing all data directories'); 
        %path names of raw data
    if isequal(parentdir , 0) 
        error('Folder not specified. Aborting function.')
    end
    break
end

% Identify all data directories in folder
%
contents = dir(parentdir);
childdir = cell(size(contents));
ctr = 1;
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name,'.') && ...
            ~strcmp(contents(i).name,'..')
        childdir(ctr) = {contents(i).name};
        ctr = ctr + 1;
    end
end
childdir = childdir(1:ctr-1); %get rid of empty cells
end