% genProtocolList: Searches through the file ScanProgram.scanProgram for
% all names given to scans, and generate a .txt file to display with all
% scan names and directory numbers (NOTE: only works for PV360 studies!).
% Also return the scan names as a cell array.
%   
%   INPUTS: 
%       studyDir    -   Full path to desired directory of study
%
%   OUTPUTS:
%       scanNames   -   Cell array of strings describing each scan within
%                       study
%
function scanNames=genProtocolList(studyDir)
% Read in all scan names from ScanProgram.scanProgram
fin=fopen(fullfile(studyDir,'ScanProgram.scanProgram'),'r');
scanNames={};
ctr=1;
SIEflg=false;
while (~feof(fin))
    line = fgetl(fin);  
    if contains(line,'<displayName>') && SIEflg
        scanNames(ctr)=extractBetween(line,'<displayName>','</displayName>');
        ctr=ctr+1;
        SIEflg=false;
    elseif contains(line,'<ScanInstructionEntity>')
        SIEflg=true;
    end
end
fclose(fin);
% Write to file Protocol_list.txt, save in study directory
scanNames=scanNames'; %flip to be in column format
scanTable=table(scanNames);
writetable(scanTable,fullfile(studyDir,'Protocol_list.txt'),...
    "WriteVariableNames",false,"QuoteStrings","none");
end