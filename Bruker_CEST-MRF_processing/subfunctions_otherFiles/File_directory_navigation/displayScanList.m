% displayScanList: Searches for and displays the protocol list in a study
% directory, if it exists; otherwise, it will generate a list automatically
% (if a ParaVision 360 study)
%
%   INPUTS:
%       base_dir        -   String containing path to main study directory
%       PV360flg        -   Logical indicating whether the selected study is
%                           identified as being obtained with ParaVision 360
%                           (true) or an older ParaVision version (false)       
%
%   OUTPUTS:
%       listFigHandle   -   Figure handle for displayed list of scans from
%                           study
%
function listFigHandle=displayScanList(base_dir,PV360flg)
dirtxts = dir(fullfile(base_dir,'*.txt'));
if ~isempty(dirtxts)
    protlist = dirtxts(contains({dirtxts.name},'list','IgnoreCase',true) | ...
        contains({dirtxts.name},'protocol','IgnoreCase',true) | ...
        contains({dirtxts.name},'scan','IgnoreCase',true)).name;
    if ~isempty(protlist)
        disp('Scan protocol list found in study directory! Displaying...')
        fileID=fopen(fullfile(base_dir,protlist),'r');
        pl=cell(20,1);
        ctr=1;
        while (~feof(fileID))
            pl{ctr}=fgetl(fileID);
            ctr=ctr+1;
        end
        listFigHandle=msgbox([{'Information on scan list:'};pl]);    
    end
end

if ~exist('listFigHandle','var') && PV360flg %generate protocol list if PV360 and a protocol list wasn't found
    disp('Scan protocol list not found. Generating from ScanProgram.scanProgram...')
    pl=genProtocolList(base_dir);
    listFigHandle=msgbox([{'Information on scan list:'};pl]);
end
end