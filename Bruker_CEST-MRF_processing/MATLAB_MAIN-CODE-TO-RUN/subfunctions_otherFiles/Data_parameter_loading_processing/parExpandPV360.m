% parExpandPV360: Expands strings extracted from a Bruker ParaVision 360 
% parameter file into strings that can be converted to a numeric vector 
% with the str2num() function
%
%   INPUTS:
%       inPar   -   Cell array of strings, each describing a numeric vector
%                   in the new ParaVision 360 condensed format (i.e. of the 
%                   form '@[number of incidences]*[value]' or 'value', 
%                   separated by spaces). If not matching this format, it
%                   will pass through the function unaffected
%   OUTPUTS:
%       outPar  -   Cell array of strings, where anything initially
%                   described in the condensed ParaVision 360 format is now
%                   expanded into a string of values separated by spaces
%
function outPar = parExpandPV360(inPar)
for iii=1:numel(inPar)
    if ischar(inPar{iii})
        temp=split(inPar{iii},' '); %split by spaces
        outPar{iii}=[];
        for jjj=1:numel(temp)
            if strcmp(temp{jjj}(1),'@') %extract both the # of repeats and the value
                nrep=str2double(extractBetween(temp{jjj},'@','*'));
                valstr=extractBetween(temp{jjj},'(',')');
                valstr=valstr{:};
                for kkk=1:nrep
                    outPar{iii}=[outPar{iii} valstr ' '];
                end
            else
                outPar{iii}=[outPar{iii} temp{jjj} ' '];
            end
        end
    end
end
end