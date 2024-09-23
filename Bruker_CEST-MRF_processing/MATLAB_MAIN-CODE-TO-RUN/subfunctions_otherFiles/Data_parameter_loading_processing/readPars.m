% readPars: Reads in various parameter values from specified file and path,
% based upon the starting text strings for each line desired (specified in
% parline as a cell array of strings), and returns the parameter values 
% as pars (cell array of strings)
%
%   INPUTS:
%       path        -   String containing full path to Bruker parameter 
%                       file (not including the file name) 
%       parfile     -   String containing name of file to be read
%       parline     -   Cell array of strings specifying beginning of each
%                       line in parameter file that is desired to be read
%                       in (e.g. '##$Desired_Par_Name')
%
%   OUTPUTS:
%       pars        -   Cell array of strings containing extracted text
%                       from file pertaining to each input string in
%                       parline
%
function pars = readPars(path,parfile,parline)
fname=fullfile(path,parfile); 
pars=cell(numel(parline),1);
for ii = 1:numel(parline)
    fin=fopen(fname,'r');
    while (~feof(fin))
        line = fgetl (fin);  
        [token, rem] = strtok (line, '=');
        if strcmp(token, parline{ii})
            if strcmp(rem(2),'(') % detect if parameter is more than single value
                line = fgetl(fin); % get next line
                while ~strcmp(line(1),'#') && ~strcmp(line(1),'$')
                    pars{ii} = [pars{ii} line];
                    line = fgetl(fin);
                end
            else
                pars{ii} = rem(2:end); % cut out "=" sign
            end
            break;
        end
    end
    fclose(fin);
end
end