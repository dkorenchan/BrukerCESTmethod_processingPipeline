% calcROIs: Calculates mean +/- std for each ROI, display in ROI stats 
% window. Also calculates any ROI-specific display items, including MRF % 
% error maps (using nominal concentration and QUESP exchange rate), QUESP 
% analysis using all signal values averaged together over ROI, and average
% z-spectrum obtained by averaging voxels within ROI, along with the fitted
% peaks and MTR asymmetry.
%
%   INPUTS:
%       img             -   Struct containing images
%       roi             -   Struct containing ROI data       
%       settings        -   Struct containing dynamic GUI display settings
%                           determined by user interfacing with GUI
%       specifiedflg    -   Struct containing logical indicators whether
%                           each type of dataset type has a specified scan
%                           number to process
%       scan_dirs       -   Struct containing scan directories
%                           corresponding with each type of dataset
%       parprefs        -   Struct containing user specific processing 
%                           options
%       PV360flg        -   Logical indicating whether the selected study 
%                           is identified as being obtained with ParaVision 
%                           360 (true) or an older ParaVision version 
%                           (false)
%       tfig            -   Handle for UI figure used to display the ROI
%                           statistics
%
%   OUTPUTS:    
%       img             -   Struct containing images, now updated to
%                           include error maps (in subfield .ErrorMaps)
%                           and/or ROI-averaged z-spectra, MTR asymmetry
%                           profiles, and fitted peak parameters
%       roi             -   Struct containing ROI data, now updated to 
%                           include fitted QUESP parameters after averaging 
%                           signal over all ROI voxels, and/or ROI
%                           statistics for all different images/spectra
%
function [img,roi]=calcROIs(img,roi,settings,specifiedflg,scan_dirs,parprefs,...
    PV360flg,tfig)

grps=fieldnames(img);
nROI=numel(roi);
i_flds=initPlotParams;


%% ERROR MAP CALCULATION BETWEEN MRF AND (ROI-AVERAGED) QUESP

% Calculate QUESP values using ROI-masked images (if QUESP loaded in)
img.ErrorMaps.kswAbs=zeros(size(roi(1).mask));
img.ErrorMaps.kswPct=zeros(size(roi(1).mask));
img.ErrorMaps.kswQUESPAbs=zeros(size(roi(1).mask));
img.ErrorMaps.kswQUESPPct=zeros(size(roi(1).mask));
if specifiedflg.QUESP
    [~,~,~,~,roi]=QUESP_load_proc(fullfile(scan_dirs.base_dir,scan_dirs.QUESP,...
        'pdata','1'),img.other.t1wIR,parprefs,PV360flg,roi);
    %Generate ksw error maps for MRF and QUESP
    for iii=1:nROI
        % First, set the true ROI-specific exchange rate based on user
        % specifications. If QUESP means are requested (or if not all ROIs
        % have a specified exchange rate), use QUESP values.
        if isfield(roi,'nomExch')
            if sum(~isinf([roi.nomExch])&~isnan([roi.nomExch]))==nROI && ...
                    roi(1).useNomExchflg
                true_ksp=roi(iii).nomExch;
            else
                true_ksp=roi(iii).kswQUESP.ROIfit;
            end
        else
            true_ksp=roi(iii).kswQUESP.ROIfit;
        end
        % MRF
        subimg=(img.MRF.ksw-true_ksp).*roi(iii).mask;
        img.ErrorMaps.kswAbs=img.ErrorMaps.kswAbs+subimg;
        img.ErrorMaps.kswPct=img.ErrorMaps.kswPct+...
            subimg./true_ksp*100;
        % QUESP
        subimg2=(img.other.kswQUESP-true_ksp).*roi(iii).mask.*img.other.RsqMask;
        img.ErrorMaps.kswQUESPAbs=img.ErrorMaps.kswQUESPAbs+subimg2;
        img.ErrorMaps.kswQUESPPct=img.ErrorMaps.kswQUESPPct+...
            subimg2./true_ksp*100;        
    end
else
    for iii=1:nROI
        % See if nominal exchange rates were specified for all ROIs, and
        % that user specified to use them for error maps. If so, then
        % calculate the MRF error maps
        if isfield(roi,'nomExch')
            if sum(~isinf([roi.nomExch])&~isnan([roi.nomExch]))==nROI && ...
                    roi(1).useNomExchflg
                true_ksp=roi(iii).nomExch;
                subimg=(img.MRF.ksw-true_ksp).*roi(iii).mask;
                img.ErrorMaps.kswAbs=img.ErrorMaps.kswAbs+subimg;
                img.ErrorMaps.kswPct=img.ErrorMaps.kswPct+...
                    subimg./true_ksp*100;
            end
        end
        roi(iii).fsQUESP.ROIfit=0;
        roi(iii).kswQUESP.ROIfit=0;
    end
end

% Calculate % error maps on MRF concentration (for all ROIs with a
% specified nominal concentration), and QUESP if specified
img.ErrorMaps.fsAbs=zeros(size(roi(1).mask));
img.ErrorMaps.fsPct=zeros(size(roi(1).mask));
img.ErrorMaps.fsQUESPAbs=zeros(size(roi(1).mask));
img.ErrorMaps.fsQUESPPct=zeros(size(roi(1).mask));
for iii=1:nROI
    if isfield(roi,'nomConc')
        if ~isempty(roi(iii).nomConc)
            if ~isinf(roi(iii).nomConc) && ~isnan(roi(iii).nomConc)
                subimg=(img.MRF.fs-roi(iii).nomConc).*roi(iii).mask;
                img.ErrorMaps.fsAbs=img.ErrorMaps.fsAbs+subimg;
                img.ErrorMaps.fsPct=img.ErrorMaps.fsPct+...
                    subimg./roi(iii).nomConc*100;
                if specifiedflg.QUESP
                    subimg2=(img.other.fsQUESP-roi(iii).nomConc).*roi(iii).mask...
                        .*img.other.RsqMask;
                    img.ErrorMaps.fsQUESPAbs=img.ErrorMaps.fsQUESPAbs+subimg2;
                    img.ErrorMaps.fsQUESPPct=img.ErrorMaps.fsQUESPPct+...
                        subimg2./roi(iii).nomConc*100;                   
                end
            end
        end
    end
end   


%% AVERAGE Z-SPECTRUM + MTR ASYMMETRY CALCULATION AND FITTING

% If z-spectroscopic data specified, calculate the average z-spectrum
% across all ROI voxels for each ROI, then fit the peaks to it
if specifiedflg.zSpec
    %DK TO DO: MAKE zppars AN INPUT TO THIS FUNCTION!
    zppars.pools={'water','NOE','MT','amide'};
    zppars.peaktype='Pseudo-Voigt';
    zppars.water1st=false;
    % Calculate the average z-spectrum for each roi, save in 
    % img.zSpec.avgZspec.all.spec
    for iii=1:nROI
        zimgReshape=reshape(img.zSpec.img,prod(size(img.zSpec.img,[1,2])),[]);
        maskReshape=reshape(roi(iii).mask,prod(size(roi(iii).mask,[1,2])),[]);
        img.zSpec.avgZspec.all.spec(iii,:)=mean(zimgReshape(maskReshape,:),1);
    end

    % Calculate the MTR asymmetry, save in img.zSpec.avgZspec.all.MTRasym
    img.zSpec.avgZspec.all.MTRasym=calcMTRmap(img.zSpec.avgZspec.all.spec,...
        img.zSpec.ppm);

    % Fit all average z-spectra, save in img.zSpec.avgZspec
    [ampls,peaksIndiv,peaksAll]=fitAllZspec(img.zSpec.ppm,...
        img.zSpec.avgZspec.all.spec,zppars);
    for iii=1:nROI
        for jjj=1:numel(zppars.pools)
            pool=zppars.pools{jjj};
            roi(iii).avgZspec.(pool)=ampls(jjj,iii);
            img.zSpec.avgZspec.(pool).fitSpec(iii,:)=1-peaksIndiv(jjj,iii,:);
        end
        % We also need to fill in zeros for pools not specified in
        % zppars.pools
        notPoolIdx=find(~contains(i_flds.poolnames,zppars.pools));
        for jjj=1:length(notPoolIdx)
            pool=i_flds.poolnames{notPoolIdx(jjj)};
            roi(iii).avgZspec.(pool)=0;
        end
        img.zSpec.avgZspec.all.fitSpec(iii,:)=1-peaksAll(iii,:);
    end
end


%% ROI STATISTICS DISPLAY IN UIFIGURE

% Construct table of ROI values
if strcmp(settings.plotgrp,'MRF')
    ProtonDensity=cell(nROI,1);
    T1=cell(nROI,1);
    T2=cell(nROI,1);
    Concentration=cell(nROI,1);
    ExchangeRate=cell(nROI,1);
    QUESP_ROIConcentration=cell(nROI,1);
    QUESP_ROIExchangeRate=cell(nROI,1);
elseif strcmp(settings.plotgrp,'other')
    B0=cell(nROI,1);
    T1=cell(nROI,1);
    T2=cell(nROI,1);
    QUESPConcentration=cell(nROI,1);
    QUESPExchangeRate=cell(nROI,1);
elseif strcmp(settings.plotgrp,'zSpec')
    %These values pertain to the voxelwise z-spec fitting
    fitOH=cell(nROI,1);
    fitAmine=cell(nROI,1);
    fitAmide=cell(nROI,1);
    fitNOE=cell(nROI,1);
    fitMT=cell(nROI,1);
    %These are values that don't have to do with z-spec fitting
    MTRasym=cell(nROI,1);
    B0=cell(nROI,1);
    %These values pertain to the ROI-averaged z-spec fitting
    ROIfitOH=cell(nROI,1);
    ROIfitAmine=cell(nROI,1);
    ROIfitAmide=cell(nROI,1);
    ROIfitNOE=cell(nROI,1);
    ROIfitMT=cell(nROI,1);
elseif strcmp(settings.plotgrp,'ErrorMaps')
    MRFfsErrorAbs=cell(nROI,1);
    MRFfsErrorPct=cell(nROI,1);
    MRFkswErrorAbs=cell(nROI,1);
    MRFkswErrorPct=cell(nROI,1);
    QUESPfsErrorAbs=cell(nROI,1);
    QUESPfsErrorPct=cell(nROI,1);
    QUESPkswErrorAbs=cell(nROI,1);
    QUESPkswErrorPct=cell(nROI,1);
end
for iii=1:nROI
    nn=numel(grps);
    for jjj=1:nn
        grp=grps{jjj};
        for kkk=1:length(i_flds.(grp))
            if ~strcmp(i_flds.(grp){kkk},'avgZspec')
                if strcmp(i_flds.(grp){kkk},'fitImg')
                    for lll=1:numel(i_flds.poolnames)
                        pName=i_flds.poolnames{lll};
                        vals=img.zSpec.fitImg.(pName)(roi(iii).mask);
                        vals=vals(vals~=0); %remove 0's
                        roi(iii).fitImg.(pName).mean=mean(vals);
                        roi(iii).fitImg.(pName).std=std(vals);
                    end
                else
                    vals=img.(grp).(i_flds.(grp){kkk})(roi(iii).mask);
                    vals=vals(vals~=0); %remove 0's
                    roi(iii).(i_flds.(grp){kkk}).mean=mean(vals);
                    roi(iii).(i_flds.(grp){kkk}).std=std(vals);
                end               
            end
        end
    end
    if strcmp(settings.plotgrp,'MRF')
        ProtonDensity{iii}=[num2str(roi(iii).dp.mean,'%0.4f') ' ' char(177) ' ' ...
            num2str(roi(iii).dp.std,'%0.4f')];
        T1{iii}=[num2str(roi(iii).t1w.mean,'%2.2f') ' ' char(177) ' ' ...
            num2str(roi(iii).t1w.std,'%2.2f') ' s'];
        T2{iii}=[num2str(roi(iii).t2w.mean,'%1.4f') ' ' char(177) ' ' ...
            num2str(roi(iii).t2w.std,'%1.4f') ' s'];
        Concentration{iii}=[num2str(roi(iii).fs.mean,'%3.1f') ' ' char(177) ' ' ...
            num2str(roi(iii).fs.std,'%3.1f') ' mM'];
        ExchangeRate{iii}=[num2str(roi(iii).ksw.mean,'%5.0f') ' ' char(177) ' ' ...
            num2str(roi(iii).ksw.std,'%5.0f') ' s^-1'];
        QUESP_ROIConcentration{iii}=[num2str(roi(iii).fsQUESP.ROIfit,'%3.1f') ' mM'];
        QUESP_ROIExchangeRate{iii}=[num2str(roi(iii).kswQUESP.ROIfit,'%5.0f') ' s^-1'];       
    elseif strcmp(settings.plotgrp,'other')
        B0{iii}=[num2str(roi(iii).B0WASSR_Hz.mean,'%3.2f') ' ' char(177) ' ' ...
            num2str(roi(iii).B0WASSR_Hz.std,'%3.2f') ' Hz'];
        T1{iii}=[num2str(roi(iii).t1wIR.mean,'%2.2f') ' ' char(177) ' ' ...
            num2str(roi(iii).t1wIR.std,'%2.2f') ' s'];
        T2{iii}=[num2str(roi(iii).t2wMSME.mean,'%1.4f') ' ' char(177) ' ' ...
            num2str(roi(iii).t2wMSME.std,'%1.4f') ' s']; 
        QUESPConcentration{iii}=[num2str(roi(iii).fsQUESP.mean,'%3.1f') ' ' char(177) ' ' ...
            num2str(roi(iii).fsQUESP.std,'%3.1f') ' mM'];
        QUESPExchangeRate{iii}=[num2str(roi(iii).kswQUESP.mean,'%5.0f') ' ' char(177) ' ' ...
            num2str(roi(iii).kswQUESP.std,'%5.0f') ' s^-1'];
    elseif strcmp(settings.plotgrp,'zSpec')
        fitOH{iii}=[num2str(roi(iii).fitImg.OH.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).fitImg.OH.std,'%1.3f')];
        fitAmine{iii}=[num2str(roi(iii).fitImg.amine.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).fitImg.amine.std,'%1.3f')];
        fitAmide{iii}=[num2str(roi(iii).fitImg.amide.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).fitImg.amide.std,'%1.3f')];
        fitNOE{iii}=[num2str(roi(iii).fitImg.NOE.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).fitImg.NOE.std,'%1.3f')];
        fitMT{iii}=[num2str(roi(iii).fitImg.MT.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).fitImg.MT.std,'%1.3f')];
        MTRasym{iii}=[num2str(roi(iii).MTRimg.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).MTRimg.std,'%1.3f')];
        B0{iii}=[num2str(roi(iii).B0WASSRppm.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).B0WASSRppm.std,'%1.3f') ' ppm'];        
        ROIfitOH{iii}=num2str(roi(iii).avgZspec.OH,'%1.3f');
        ROIfitAmine{iii}=num2str(roi(iii).avgZspec.amine,'%1.3f');
        ROIfitAmide{iii}=num2str(roi(iii).avgZspec.amide,'%1.3f');
        ROIfitNOE{iii}=num2str(roi(iii).avgZspec.NOE,'%1.3f');
        ROIfitMT{iii}=num2str(roi(iii).avgZspec.MT,'%1.3f');
    elseif strcmp(settings.plotgrp,'ErrorMaps')
        MRFfsErrorAbs{iii}=[num2str(roi(iii).fsAbs.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).fsAbs.std,'%1.3f') ' mM'];
        MRFfsErrorPct{iii}=[num2str(roi(iii).fsPct.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).fsPct.std,'%1.3f') '%'];
        MRFkswErrorAbs{iii}=[num2str(roi(iii).kswAbs.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).kswAbs.std,'%1.3f') ' s^{-1}'];
        MRFkswErrorPct{iii}=[num2str(roi(iii).kswPct.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).kswPct.std,'%1.3f') '%'];
        QUESPfsErrorAbs{iii}=[num2str(roi(iii).fsQUESPAbs.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).fsQUESPAbs.std,'%1.3f') ' mM'];
        QUESPfsErrorPct{iii}=[num2str(roi(iii).fsQUESPPct.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).fsQUESPPct.std,'%1.3f') '%'];
        QUESPkswErrorAbs{iii}=[num2str(roi(iii).kswQUESPAbs.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).kswQUESPAbs.std,'%1.3f') ' s^{-1}'];
        QUESPkswErrorPct{iii}=[num2str(roi(iii).kswQUESPPct.mean,'%1.3f') ' ' char(177) ' ' ...
            num2str(roi(iii).kswQUESPPct.std,'%1.3f') '%'];
    end    
end
ROIName = {roi.name}';
if strcmp(settings.plotgrp,'MRF')
    rt=table(ROIName,ProtonDensity,T1,T2,Concentration,ExchangeRate,...
        QUESP_ROIConcentration,QUESP_ROIExchangeRate);
elseif strcmp(settings.plotgrp,'other')
    rt=table(ROIName,B0,T1,T2,QUESPConcentration,QUESPExchangeRate);
elseif strcmp(settings.plotgrp,'zSpec')
    rt=table(ROIName,fitOH,fitAmine,fitAmide,fitNOE,fitMT,MTRasym,B0);
    rt2=table(ROIName,ROIfitOH,ROIfitAmine,ROIfitAmide,ROIfitNOE,ROIfitMT);
elseif strcmp(settings.plotgrp,'ErrorMaps')
    rt=table(ROIName,MRFfsErrorAbs,MRFfsErrorPct,MRFkswErrorAbs,MRFkswErrorPct,...
        QUESPfsErrorAbs,QUESPfsErrorPct,QUESPkswErrorAbs,QUESPkswErrorPct);
end
clf(tfig);
uitable(tfig,'Data',rt,'Position',[20 230 1200 200],'ColumnEditable',false);
if strcmp(settings.plotgrp,'zSpec') %plot average z-spectrum fits underneath 
    uitable(tfig,'Data',rt2,'Position',[20 20 1200 200],'ColumnEditable',false);
end
end