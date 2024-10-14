% genProtocolList: Searches through the file ScanProgram.scanProgram for
% all names given to scans, and generate a .txt file to display with all
% scan names and directory numbers (NOTE: only works for PV360 studies!).
% Also return the scan names as a cell array.
%   
%   INPUTS: 
%       studyDir    -   Full path to desired directory of study
%
%   OUTPUTS:
%       scanEntries -   Cell array of strings describing each scan within
%                       study
%
function scanEntries=genProtocolList(studyDir)
% Read in all scan names from ScanProgram.scanProgram
fin=fopen(fullfile(studyDir,'ScanProgram.scanProgram'),'r');
scanNames={};
scanNo={};
ctr=1;
SIEflg=false;
while (~feof(fin))
    line = fgetl(fin);  
    if contains(line,'<expno>') && SIEflg
        scanNo(ctr)=extractBetween(line,'<expno>','</expno>');
        ctr=ctr+1;
        SIEflg=false;
    elseif contains(line,'<displayName>') && SIEflg
        scanNames(ctr)=extractBetween(line,'<displayName>','</displayName>');
    elseif contains(line,'ScanInstructionEntity>') %should work for PV360 and below
        SIEflg=true;
    end
end
fclose(fin);
% Write to file Protocol_list.txt, save in study directory
scanNo=scanNo'; %flip to be in column format
scanNames=scanNames'; %flip to be in column format
scanEntries=strcat(scanNo,' ----',scanNames);
scanTable=table(scanEntries);
writetable(scanTable,fullfile(studyDir,'Protocol_list.txt'),...
    "WriteVariableNames",false,"QuoteStrings","none");
end