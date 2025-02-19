% imageDispGUI: Creates an interactive figure which can be used to display
% imaging data, draw ROIs, and perform additional data analysis,
% particularly on ROI voxels. 
%
%   INPUTS:
%       img             -   Struct containing images
%       roi             -   Struct containing ROI data
%       specifiedflg    -   Struct containing logical indicators whether
%                           each type of dataset type has a specified scan
%                           number to process
%       scan_dirs       -   Struct containing scan directories
%                           corresponding with each type of dataset
%       parprefs        -   Struct containing user specific processing 
%                           options
%       PV360flg        -   Logical indicating whether the selected study is
%                           identified as being obtained with ParaVision 360
%                           (true) or an older ParaVision version (false)
%
%   OUTPUTS:    
%       img             -   Struct containing updated images
%       roi             -   Struct containing updated ROI data 
%
% This file contains several subfunctions within imageDispGUI() - see  
% final section for brief descriptions:
%   selDispGrp()
%   selDispPool()
%   nameROI()
%   newROI()
%   selROI()
%   ROIconc()
%   ROIexch()
%   fixROIconcQUESP()
%   useNomExchError()
%   toggleSettingFlags()
%   editSettingVals()
%   finishFig()
%   
function [img,roi]=imageDispGUI(img,roi,specifiedflg,scan_dirs,parprefs,...
    PV360flg)
%% MAIN FUNCTION -- INITIALIZE VARIABLES

% Parameters for plotting: image names, labels, colorbars
i_flds=initPlotParams;
grps=fieldnames(img);

settings.roiidx=1;
if isfield(roi,'name')
    nROI=numel(roi);
    roinames={roi.name};
else
    nROI=0;
    roinames=cell(1);    
end
newname=['ROI' num2str(nROI+1)];

% Set checkbox-related flags to false (to reflect initial values)
roi(1).fixConcQUESPflg=false;
roi(1).useNomExchflg=false;

% Set display options
settings.maskImgs=true;
settings.dpMaskVal=0.999;

% Set initial plotting group, based upon what was loaded
if isfield(img,'MRF')
    settings.plotgrp='MRF';
elseif isfield(img,'other')
    settings.plotgrp='other';
else
    settings.plotgrp='zSpec';
end

% Set initial z-spectroscopy display values
settings.selPool='amide'; %default fitted pool image to show
settings.MTRppm=3.5; %default MTR asymmetry ppm value to calculate

% Screen size/resolution (for plotting)
scrsz = get(groot,'ScreenSize');
sppi = get(groot,'ScreenPixelsPerInch');


%% MAIN FUNCTION -- FIGURE GENERATION

% Make separate uifigure for table displaying ROI stats
tfig=uifigure('Position',[0 0 1250 500]);

% Display input 1H images in interactive GUI figure
drawfig =figure('Position',[0,round(scrsz(4)*1/6),round(scrsz(3)*2/3),...
    round(scrsz(4)*3/4)]*sppi,'Units','inches');

bg1 = uipanel('Position',[0 0 .1 1]);

% Controls for ROI editing + display

% Selection for which group of images to display
uicontrol(bg1,'Style','text','Position',[5 835 160 15],...
    'String','Active display group:');
uicontrol(bg1,'Style','popupmenu','Position',[0 820 160 10],...
    'String',grps,'Callback',@selDispGrp);
uicontrol(bg1,'Style','text','Position',[0 795 160 15],...
    'String','Active fitted pool map:');
uicontrol(bg1,'Style','popupmenu','Position',[0 780 160 10],...
    'String',i_flds.poolnames,'Callback',@selDispPool);

% Other display items
% MRF
uicontrol(bg1,'Style','checkbox','Position',[10 735 120 22],...
    'Callback',@toggleSettingFlags,'Tag','maskImgs',...
    'Value',settings.maskImgs,'String','Mask images using');
uicontrol(bg1,'Style','text','Position',[30 710 90 30],...
    'String','dot-product loss');
uicontrol(bg1,'Style','text','Position',[30 695 80 15],...
    'String','Mask threshold:');
nr=uicontrol(bg1,'Style','edit','Position',[30 675 80 20],...
    'String',num2str(settings.dpMaskVal),'Tag','dpMaskVal',...
    'Callback',@editSettingVals);

% Z-spectroscopic imaging
uicontrol(bg1,'Style','text','Position',[5 635 160 15],...
    'String','MTRasym ppm value:');
map=uicontrol(bg1,'Style','edit','Position',[30 610 80 20],...
    'String',num2str(settings.MTRppm),'Callback',@setMTRasymPpm);

% ROI creation
uicontrol(bg1,'Style','text','Position',[30 535 80 15],...
    'String','New ROI name:');
nr=uicontrol(bg1,'Style','edit','Position',[30 510 80 20],...
    'String',newname,'Callback',@nameROI);
uicontrol(bg1,'Style','pushbutton','Position',[0 480 140 30],...
    'String','Draw new ROI on slice','Callback',@newROI);

% ROI selection and editing
rbg=uibuttongroup('Position',[.005 .14 .09 .36],...
    'Visible',nROI>0);
uicontrol(rbg,'Style','text','Position',[20 295 80 15],...
    'String','Active ROI:');
rs=uicontrol(rbg,'Style','popupmenu','Position',[10 285 120 10],...
    'String',roinames,'Callback',@selROI);
uicontrol(rbg,'Style','text','Position',[20 210 90 45],...
    'String','Nominal concentration for active ROI:');
nc=uicontrol(rbg,'Style','edit','Position',[10 195 120 20],...
    'String','','Callback',@ROIconc);
uicontrol(rbg,'Style','text','Position',[20 150 90 45],...
    'String','Nominal exchange rate for active ROI:');
ne=uicontrol(rbg,'Style','edit','Position',[10 145 120 20],...
    'String','','Callback',@ROIexch);
uicontrol(rbg,'Style','text','Position',[10 100 110 45],...
    'String','(NOTE: put in units of mM/s^-1. Set to Inf or Nan if not using.)');
chkbxHandles.ncf=uicontrol(rbg,'Style','checkbox','Position',[10 80 120 22],...
    'Callback',@fixROIconcQUESP,'Enable','off','String','Fix concentration');
chkbxHandles.ncft=uicontrol(rbg,'Style','text','Position',[10 53 110 30],...
    'String','to nominal value for QUESP fitting','Enable','off');
chkbxHandles.nee=uicontrol(rbg,'Style','checkbox','Position',[10 30 120 22],...
    'Callback',@useNomExchError,'Enable','off','String','Use nominal');
chkbxHandles.neet=uicontrol(rbg,'Style','text','Position',[10 3 110 30],...
    'String','exchange rates for error maps','Enable','off');

% Status indicator
si=uicontrol(bg1,'Style','text','Position',[0 70 150 40],'String','',...
    'FontSize',18,'FontWeight','bold');

% Finish button
uicontrol(bg1,'Style','pushbutton','Position',[20 10 100 60],...
    'String','FINISH AND SAVE','Callback',@finishFig);

% Detect how to initially set QUESP conc fix and nominal exch use 
% checkboxes status
roi=checkBoxesEnable(roi,chkbxHandles);

% Calculate MTR asymmetry map for default value, if zSpec dataset specified
if isfield(img,'zSpec')
    [img.zSpec.MTRimg,img.zSpec.MTRppm,settings.MTRppm]...
        =calcMTRmap(img.zSpec.img,img.zSpec.ppm,settings.MTRppm);
    % Update uicontrol value based upon the actual ppm value used for MTRasym
    set(map,'String',num2str(settings.MTRppm));
end

% plotAxImg(img,roi,settings,si); 
if isfield(roi,'mask')
    [img,roi]=calcROIs(img,roi,settings,specifiedflg,scan_dirs,parprefs,...
        PV360flg,tfig);
end
plotAxImg(img,roi,settings,si); 
waitfor(drawfig);


%% INTERNAL CALLBACK FUNCTIONS FOR UI ELEMENTS

% selDispGrp: Set active group of images to plot + display ROI values
function selDispGrp(source,~)
settings.plotgrp=grps{source.Value};
if isfield(roi,'mask')
    [img,roi]=calcROIs(img,roi,settings,specifiedflg,scan_dirs,parprefs,...
        PV360flg,tfig);
end
plotAxImg(img,roi,settings,si);
end


% selDispPool: Set active fitted pool map to plot (for group zSpec)
function selDispPool(source,~)
settings.selPool=i_flds.poolnames{source.Value};
plotAxImg(img,roi,settings,si);
end


% nameROI: sets name for new ROI once created
function nameROI(source,~)
newname = source.String;
end


% newROI: Allows user to draw ROI on a slice without a previous one, or to
% delete the current ROI for redrawing
function newROI(~,~)
current_roi=drawpolygon;
roi(nROI+1).coords=current_roi.Position;
roi(nROI+1).mask=createMask(current_roi,img.(settings.plotgrp).size(2),...
    img.(settings.plotgrp).size(1));
roi(nROI+1).name=newname;
roi(nROI+1).nomConc=NaN; %need to initialize!
roi(nROI+1).nomExch=NaN; %need to initialize!
if isempty(roinames{1})
    roinames={roi(nROI+1).name};
else
    roinames=[roinames {roi(nROI+1).name}];
end
nROI=nROI+1;
% Make items in GUI pertaining to ROIs visible
if nROI > 0
    set(rbg,'Visible','on');
end
newname=['ROI' num2str(nROI+1)];
set(nr,'String',newname);
set(rs,'String',roinames);
[img,roi]=calcROIs(img,roi,settings,specifiedflg,scan_dirs,parprefs,...
    PV360flg,tfig);
roi=checkBoxesEnable(roi,chkbxHandles);
plotAxImg(img,roi,settings,si)
end


% selROI: Sets which ROI is the active one in the plotting GUI
function selROI(source,~)
settings.roiidx=source.Value;
if isfield(roi(settings.roiidx),'nomConc')
    set(nc,'String',num2str(roi(settings.roiidx).nomConc));
else
    set(nc,'String','Inf');
end
if isfield(roi(settings.roiidx),'nomExch')
    set(ne,'String',num2str(roi(settings.roiidx).nomExch));
else
    set(ne,'String','Inf');
end
plotAxImg(img,roi,settings,si)
end


% ROIconc: Adds a field to variable roi indicating what
% nominal concentration is (in mM)
function ROIconc(source,~)
roi(settings.roiidx).nomConc=str2double(source.String);
[img,roi]=calcROIs(img,roi,settings,specifiedflg,scan_dirs,parprefs,...
    PV360flg,tfig);
plotAxImg(img,roi,settings,si)
%Make checkbox for concentration fixing active if all ROIs have a valid
%concentration specified (and enforce roi(1).fixConcQUESPflg=false if not!)
roi=checkBoxesEnable(roi,chkbxHandles);
end


% ROIexch: Adds a field to variable roi indicating what
% nominal exchange is (in s^-1)
function ROIexch(source,~)
roi(settings.roiidx).nomExch=str2double(source.String);
if roi(1).useNomExchflg
    [img,roi]=calcROIs(img,roi,settings,specifiedflg,scan_dirs,parprefs,...
        PV360flg,tfig);
end
%Make checkbox for nominal exchange rate use active if all ROIs have a 
%valid exchange rate specified (and enforce roi(1).useNomExchflg=false if 
%not!)
roi=checkBoxesEnable(roi,chkbxHandles);
end


% fixROIconcQUESP: Toggles flag roi.fixConcQUESPflg to fix QUESP ROI 
% concentrations to specified nominal values 
function fixROIconcQUESP(~,~)
roi(1).fixConcQUESPflg=~roi(1).fixConcQUESPflg;    
[img,roi]=calcROIs(img,roi,settings,specifiedflg,scan_dirs,parprefs,...
    PV360flg,tfig);
end


% useNomExchError: Toggles flag roi.useNomExchflg to use specified nominal 
% values for exchange rates when showing error maps
function useNomExchError(~,~)
roi(1).useNomExchflg=~roi(1).useNomExchflg;
[img,roi]=calcROIs(img,roi,settings,specifiedflg,scan_dirs,parprefs,...
    PV360flg,tfig);
plotAxImg(img,roi,settings,si)
end


% setMTRasymPpm: Changes the ppm value for the displayed MTR asymmetry map
% (img.zSpec.MTRimg), then recalculate and display
function setMTRasymPpm(src,~)
settings.MTRppm=str2double(src.String);
if isfield(img,'zSpec')
    [img.zSpec.MTRimg,img.zSpec.MTRppm,settings.MTRppm]...
        =calcMTRmap(img.zSpec.img,img.zSpec.ppm,settings.MTRppm);
end
% Update uicontrol value based upon the actual ppm value used for MTRasym
set(map,'String',num2str(settings.MTRppm));
plotAxImg(img,roi,settings,si); 
end

% toggleSettingFlags: Toggles flags in variable settings
function toggleSettingFlags(src,~)
settings.(src.Tag)=~settings.(src.Tag);
plotAxImg(img,roi,settings,si)
end


% editSettingVals: Changes stored numerical values in variable settings
function editSettingVals(src,~)
settings.(src.Tag)=str2double(src.String);
plotAxImg(img,roi,settings,si)
end


% finishFig: Finish all figure stuff, continue function
function finishFig(~,~)
close(tfig)
close(drawfig)
end
end