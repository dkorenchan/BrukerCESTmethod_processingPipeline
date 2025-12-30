% QUESPload_proc: Loads in QUESP data, T1 map, and (optionally) ROI data, 
% then performs voxelwise or ROI fitting for fs and ksw maps 
%
%   INPUTS:     
%       load_dir    -   String containing path to QUESP 2dseq file
%       T1map       -   Matrix (double or single) containing map of T1 
%                       values
%       prefs       -   Struct containing user specific processing options.
%                       The main subfields of interest are:
%                           .QUESPfcn   -   String indicating which type 
%                                           of QUESP fitting to do:
%                               'Regular'   -   Standard fitting of MTR_asym 
%                               'Inverse'   -   (default) Fitting of 1/MTR_asym
%                               'OmegaPlot' -   Omega plot fitting
%                           .RsqThreshold - Minimum value (double) of R^2 
%                                           fitting parameter for keeping
%                                           valid QUESP fits; below this 
%                                           value a voxel is masked out                      
%       PV360flg    -   Logical; if true, will process according to
%                       ParaVision 360 format (default false)
%       roi         -   (optional) struct containing ROI information. If 
%                       provided, function will average the signal over
%                       each ROI, then perform a QUESP fit for each ROI
%                       
%   OUTPUTS:
%       fs      -   Matrix (double) of QUESP-fitted proton volume fraction 
%       ksw     -   Matrix (double) of QUESP-fitted exchange rate (in s^-1)
%       Rsq     -   Matrix (double) of R^2 values pertaining to QUESP fits
%       info    -   Struct containing information loaded from QUESP dataset
%       newroi  -   Struct containing updated ROI values
%
function [fs,ksw,Rsq,info,newroi]=QUESP_load_proc(load_dir,T1map,prefs,...
    PV360flg,roi)
% If roi included as input, fitting will use ROIs rather than by voxel
if exist('roi','var')
    fitmode='ROI';
else
    fitmode='voxel';
end
if nargin<3
    prefs.QUESPfcn='Inverse';
    prefs.RsqThreshold=0.95;
    PV360flg=false;
elseif nargin<4
    PV360flg=false;   
end

if isempty(prefs.RsqThreshold)
    prefs.RsqThreshold=0.95;
end

QUESPfcn=prefs.QUESPfcn; %need to do for parfor() loop!

[QUESPimg,QUESPimgM0,info]=read2dseq(load_dir,'quesp',prefs,PV360flg);
T1map=double(T1map); %required for fitting to work!

% ID the saturation amplitudes and offsets used for each image
satamps=info.sat_amplitudes;
satoffs=info.sat_offsets;

% ID pairs of values where the offsets are opposite and equal
% (within 1 Hz) AND where the saturation powers are equal (within 
% 1e-3 uT)
[temp_row,temp_col]=find((abs(satoffs+satoffs')<1) & ...
    (abs(satamps-satamps')<1e-3));

% Go through both temp_row and temp_col and store each pair only when they 
% first appear (this will fix issues where the sat powers were equal)
pair_row=[];
pair_col=[];
for iii=1:length(temp_row)
    if sum(temp_row(iii)==pair_row)==0 && sum(temp_col(iii)==pair_col)==0
        pair_row=[pair_row temp_row(iii)];
        pair_col=[pair_col temp_col(iii)];
    end
end

% Split function based upon whether fitting will take place by voxel or by
% ROI
switch fitmode
    case 'voxel'
%         % Generate MTR_asym maps from QUESP data
%         MTRasym=zeros([size(QUESPimg,[1,2]) length(pair_row)/2]);
%         for iii=1:length(pair_row)/2 %just the left half of the matrix
%             MTRasym(:,:,iii)=squeeze(QUESPimg(:,:,pair_row(iii))...
%                 -QUESPimg(:,:,pair_col(iii)))./QUESPimgM0;
%         end
    
        % Divide QUESP data into positive and negative frequency offsets, and 
        % normalize by the reference image to get Z-values. For the first half of
        % the pairs, pair_col contains positive offsets and pair_row contains 
        % negative offsets (left half of correlation matrix)
        QUESPpos=QUESPimg(:,:,pair_col(1:end/2))...
            ./repmat(QUESPimgM0(:,:,1),[1,1,size(QUESPimg,3)/2]);
        QUESPneg=QUESPimg(:,:,pair_row(1:end/2))...
            ./repmat(QUESPimgM0(:,:,2),[1,1,size(QUESPimg,3)/2]);
        
        % Generate a threshold map selecting only values with significant 
        % saturation (i.e. significant signal decrease w/ positive offset 
        % vs negative offset), where the signal isn't significantly higher 
        % than the M0 image, and where the T1 fitting returned a 
        % significant value
        threshmap=prod((QUESPpos<1.05.*QUESPneg) & (QUESPpos<1.1) & (QUESPneg<1.1),...
            3,'native').*(T1map>0);

        % MTRasymvec=reshape(MTRasym,[],size(MTRasym,3));
        QUESPposvec=reshape(QUESPpos,[],size(QUESPpos,3));
        QUESPnegvec=reshape(QUESPneg,[],size(QUESPneg,3));
        T1mapvec=reshape(T1map,[],1);

        elementvec=find(reshape(threshmap,[],1));
        fixconc=inf(size(elementvec));

    case 'ROI'
        % Take the average ROI value over the positive, negative, and
        % reference QUESP images, then calculate the Z-values
        QUESPposvec=zeros(length(roi),length(pair_col)/2);
        QUESPnegvec=zeros(length(roi),length(pair_row)/2);
        T1mapvec=zeros(length(roi),1);

        elementvec=1:length(roi);
        fixconc=inf(size(elementvec));
        for iii=elementvec
            ref_p=mean(QUESPimgM0(:,:,1).*roi(iii).mask,'all');
            QUESPposvec(iii,:)=mean(QUESPimg(:,:,pair_col(1:end/2))...
                .*repmat(roi(iii).mask,[1,1,length(pair_col)/2]),[1,2])...
                ./ref_p;
            ref_n=mean(QUESPimgM0(:,:,2).*roi(iii).mask,'all');
            QUESPnegvec(iii,:)=mean(QUESPimg(:,:,pair_row(1:end/2))...
                .*repmat(roi(iii).mask,[1,1,length(pair_row)/2]),[1,2])...
                ./ref_n;
            T1mapvec(iii)=mean(T1map(roi(iii).mask));

            % ID whether to fix concentrations to nominal values (previous
            % code should ensure that all ROI fields have valid values!)
            if roi(1).fixConcQUESPflg
                fixconc(iii)=roi(iii).nomConc;
            end
        end
end

% Prepare for QUESP fitting
z_lab_element=QUESPposvec(elementvec,:);
z_ref_element=QUESPnegvec(elementvec,:);
T1mapvec=T1mapvec(elementvec); %need to select the relevant T1 values!

fsfit=zeros(size(elementvec));
kswfit=zeros(size(elementvec));
Rsqfit=zeros(size(elementvec));

less1pwrnum=0; %counts voxels/ROIs for which the QUESP fitting worked after 
    %cutting out highest power value
less2pwrnum=0; %counts voxels/ROIs for which the QUESP fitting worked after 
    %cutting out highest 2 power values
failnum=0; %counts voxels/ROIs for which the QUESP fitting failed

timepars.tp=unique(info.sat_duration)/1000; %currently, only supporting same 
    %saturation duration for all measurements
timepars.rd=unique(info.Trec); %currently, only supporting same recovery 
    %delay for all measurements
satamps=satamps(1:end/2);

% If final values of satamps are equal, keep only the very last one, and
% truncate other variables accordingly (this may occur if the max power
% limit was reached for >1 sat power!)
for iii=1:length(satamps)
    if satamps(end)==satamps(end-1)
        satamps(end)=[];
        z_lab_element(:,end)=[];
        z_ref_element(:,end)=[];
    else
        break
    end
end

conc_to_fs=3/110000; %conversion factor from mM to volume fraction

% Default QUESP fitting bounds and starting points
fitopts_def.Lower      = [2*conc_to_fs      20      ];
fitopts_def.StartPoint = [40*conc_to_fs     2000    ];
fitopts_def.Upper      = [120*conc_to_fs    10000    ];

% Fit QUESP data across powers, removing highest 1 or 2 powers if fitting
% throws an error
disp(['QUESP data: ' QUESPfcn ' QUESP fitting of MTR asymmetry to '...
    'calculate ksw and fs by ' fitmode '...'])
tic
switch fitmode
    case 'voxel'
        parfor iii=1:numel(elementvec)
            z_lab=z_lab_element(iii,:);
            z_ref=z_ref_element(iii,:);
            fitopts=fitopts_def;
        
            % If a fixed concentration is specified for the ROI, use to fix fitopts
            if ~isinf(fixconc(iii))
                fitopts.Lower(1)=fixconc(iii)*conc_to_fs;
                fitopts.StartPoint(1)=fixconc(iii)*conc_to_fs;
                fitopts.Upper(1)=fixconc(iii)*conc_to_fs;
            end
        
        % Try with all B1 values, but remove the last 2 points successively if 
        % unsuccessful    
            try %all power values fitted
                [~,kswfit(iii),fsfit(iii),Rsqfit(iii)]=QUESPfitting(...
                    z_lab,z_ref,satamps,...
                    {QUESPfcn},T1mapvec(iii),timepars,false,[],fitopts);    
            catch
                try %all but last power value fitted
                    [~,kswfit(iii),fsfit(iii),Rsqfit(iii)]=QUESPsingleROI(...
                        z_lab(1:(end-1)),z_ref(1:(end-1)),satamps(1:(end-1)),...
                        {QUESPfcn},timepars,T1mapvec(iii),false,[],fitopts);
                    less1pwrnum=less1pwrnum+1;
                catch
                    try %all but last 2 power values fitted
                        [~,kswfit(iii),fsfit(iii),Rsqfit(iii)]=QUESPsingleROI(...
                            z_lab(1:(end-2)),z_ref(1:(end-2)),satamps(1:(end-2)),...
                            {QUESPfcn},timepars,T1mapvec(iii),false,[],fitopts);
                        less2pwrnum=less2pwrnum+1;                
                    catch
                        failnum=failnum+1;
                    end
                end        
            end
        end
    case 'ROI'
        for iii=1:numel(elementvec)
            z_lab=z_lab_element(iii,:);
            z_ref=z_ref_element(iii,:);
            fitopts=fitopts_def;
        
            % If a fixed concentration is specified for the ROI, use to fix fitopts
            if ~isinf(fixconc(iii))
                fitopts.Lower(1)=fixconc(iii)*conc_to_fs;
                fitopts.StartPoint(1)=fixconc(iii)*conc_to_fs;
                fitopts.Upper(1)=fixconc(iii)*conc_to_fs;
            end
        
        % Try with all B1 values, but remove the last 2 points successively if 
        % unsuccessful    
            try %all power values fitted
                [~,kswfit(iii),fsfit(iii),Rsqfit(iii)]=QUESPfitting(...
                    z_lab,z_ref,satamps,...
                    {QUESPfcn},T1mapvec(iii),timepars,false,[],fitopts);    
            catch
                try %all but last power value fitted
                    [~,kswfit(iii),fsfit(iii),Rsqfit(iii)]=QUESPsingleROI(...
                        z_lab(1:(end-1)),z_ref(1:(end-1)),satamps(1:(end-1)),...
                        {QUESPfcn},timepars,T1mapvec(iii),false,[],fitopts);
                    less1pwrnum=less1pwrnum+1;
                catch
                    try %all but last 2 power values fitted
                        [~,kswfit(iii),fsfit(iii),Rsqfit(iii)]=QUESPsingleROI(...
                            z_lab(1:(end-2)),z_ref(1:(end-2)),satamps(1:(end-2)),...
                            {QUESPfcn},timepars,T1mapvec(iii),false,[],fitopts);
                        less2pwrnum=less2pwrnum+1;                
                    catch
                        failnum=failnum+1;
                    end
                end        
            end
        end
end
toc
disp(['QUESP data: Fitting was successful for ' ...
    num2str(numel(elementvec)-failnum) '/' num2str(numel(elementvec)) ...
    ' ' fitmode 's']);
if less1pwrnum>0
    disp(['QUESP data: ' num2str(less1pwrnum) ' ' fitmode ...
        's were fit successfully with the highest power omitted'])
end
if less2pwrnum>0
    disp(['QUESP data: ' num2str(less2pwrnum) ' ' fitmode ...
        's were fit successfully with the highest 2 powers omitted'])
end

% Fill in output maps in vector format
fs=zeros(size(QUESPposvec,1),1);
ksw=zeros(size(QUESPposvec,1),1);
Rsq=zeros(size(QUESPposvec,1),1);

fs(elementvec)=fsfit;
ksw(elementvec)=kswfit;
Rsq(elementvec)=Rsqfit;

% Update fs values to be in concentration (assuming 3 protons, 55 M H2O) 
fs=fs*110000/3; % in mM

switch fitmode
    case 'voxel'
        % Reshape output vectors back into image maps
        fs=reshape(fs,info.size(1:2));
        ksw=reshape(ksw,info.size(1:2));
        Rsq=reshape(Rsq,info.size(1:2));

        % Threshold based upon R-squared value
        disp(['QUESP data: thresholding maps to keep for R^2 > ' ...
            num2str(prefs.RsqThreshold) '...'])
        fs=fs.*(Rsq>prefs.RsqThreshold);
        ksw=ksw.*(Rsq>prefs.RsqThreshold);

    case 'ROI'
        % Update ROI values
        newroi=roi;
        for iii=1:length(roi)
            newroi(iii).fsQUESP.ROIfit=fs(iii);
            newroi(iii).kswQUESP.ROIfit=ksw(iii);
        end
end
end