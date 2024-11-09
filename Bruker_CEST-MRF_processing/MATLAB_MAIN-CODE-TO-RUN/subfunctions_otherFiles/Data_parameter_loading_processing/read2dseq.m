% read2dseq: Pulls in data from specified 2dseq file, then outputs image 
% data and information based upon what specified kind of dataset it is. For
% MRF datasets, the dictionary simulation parameters are also pulled in and
% all is saved in file acquired_data.mat within same directory as 2dseq
% file.
%
%   INPUTS:
%       pname       -   String containing path to desired 2dseq file (not 
%                       including '2dseq' at the end!)
%       typestr     -   String specifying which type of imaging dataset is
%                       being loaded:
%                           'image'     -   (default) Anatomical imaging data
%                           'wassr'     -   WASSR B0 mapping data, ran
%                                           using EPI.ppg (PV360) or 
%                                           cest_EPI.ppg (older PV versions)
%                           'cest'      -   CEST z-spectroscopic imaging
%                                           data, ran using EPI.ppg (PV360) 
%                                           or cest_EPI.ppg (older PV versions)
%                           'quesp'     -   QUESP imaging data, ran using
%                                           fpSL_EPI.ppg or fp_EPI.ppg
%                           'dictmatch' -   MRF imaging data, ran using
%                                           fpSL_EPI.ppg or fp_EPI.ppg
%       prefs       -   Struct containing user specific processing options
%                       (only required if typestr='dictmatch', since it
%                       will need the subfield .nPools)
%       PV360flg    -   Logical; if true, will process according to
%                       ParaVision 360 format (default false)
%
%   OUTPUTS:
%       image       -   Matrix (double) containing image(s) loaded from 
%                       2dseq file
%       M0image     -   Matrix (double) containing image(s) without 
%                       saturation (only for typestr={'wassr','cest','quesp'}
%       info        -   Struct containing extracted imaging parameters
%
function [image,M0image,info]=read2dseq(pname,typestr,prefs,PV360flg)
if nargin<2
    typestr = 'image';
    prefs=struct;
    PV360flg=false;
elseif nargin<3
    if strcmp(typestr,'dictmatch')
        error('read2dseq requires prefs.nPools to work for typestr "dictmatch"!')
    else
        prefs=struct;
        PV360flg=false;
    end
elseif nargin<4
    PV360flg=false;
end

if ~strcmp(typestr,'image') && ~strcmp(typestr,'wassr')...
        && ~strcmp(typestr,'cest') && ~strcmp(typestr,'quesp') ...
        && ~strcmp(typestr,'dictmatch')
    error(['Incorrect input for data type! Acceptable values for second variable: '...
        '"image", "wassr", "cest", "quesp", "dictmatch"'])
end

fname='2dseq';                      % file name
format = 'int16';                   % image format

% No matter what the dataset is, we can still pull in the parameters giving
% us the image size from the method file
sizedata=readPars(fullfile(pname,'..','..'),'method',{'##$PVM_Matrix',...
    '##$PVM_SPackArrNSlices','##$PVM_NRepetitions','##$Number_fp_Experiments',...
    '##$PVM_SatTransRepetitions'});
info.size(1:2)=str2num(sizedata{1}); %only str2num will convert to array!
info.size(3)=str2double(sizedata{2});
info.size(4)=max([str2double(sizedata{3}),str2double(sizedata{4}),...
    str2double(sizedata{5})]);

Matrix_X = info.size(1);              % image matrix size (dim 1)
Matrix_Y = info.size(2);              % image matrix size (dim 2)
nslices = info.size(3);               % number of image slices
niter = info.size(4);

fid_in = fopen(fullfile(pname,fname),'r','ieee-le');
rawdata = reshape(fread(fid_in,Matrix_X*Matrix_Y*nslices*niter,format),...
               Matrix_X,Matrix_Y,nslices,niter);
fclose(fid_in);

switch typestr
    case 'image'
        image = rawdata;
        M0image = [];    
    case {'cest','wassr'}
% Generate cest/wassr data matrix containing offset frequencies (stored in 
% variable info), images, and unsaturated image. Ouput matrix sorts 
% frequency offsets and images from lowest (-400 Hz) to highest (+400 Hz).
%   Note: the Bruker 2dseq file for the CEST RARE sequence stores the 
%   images with the unsaturated image first, followed by alternating 
%   negative and positive offsets, from high to low (i.e. -400, +400, -360, 
%   +360, etc), with the last image being the 0 Hz offset
        if PV360flg 
%             if strcmp(typestr,'wassr') %WASSR in PV360 currently uses the 
%                 %fp_EPI .ppg
%                 satpars=readPars(fullfile(pname,'..','..'),'method',...
%                     {'##$Fp_SatOffset','##$Fp_SatPows','##$PVM_FrqWork'});  
%             elseif strcmp(typestr,'cest')
                satpars=readPars(fullfile(pname,'..','..'),'method',...
                    {'##$PVM_SatTransFreqValues','##$PVM_SatTransPulseAmpl_uT',...
                    '##$PVM_FrqWork'});
%             end
            % Expand out new PV360 shorter array format, if found
            satpars=parExpandPV360(satpars);          
        else
            satpars=readPars(fullfile(pname,'..','..'),'method',...
                {'##$SatFreqList','##$PVM_MagTransPower','##$PVM_FrqWork'});
        end

        % Prepare vector of saturation offsets: (1) ID the largest
        % absolute value offset as the M0 image; then (2) remove M0 from 
        % the raw data and offset list; then (3) sort the remaining 
        % offsets from lowest to highest, noting the order
        info.w_offset1=str2num(satpars{1}); %convert to array of type double
        M0idx=find(abs(info.w_offset1)==max(abs(info.w_offset1)));
        M0image=rawdata(:,:,:,M0idx)';

        rawdata(:,:,:,M0idx)=[]; %remove M0 image
        info.w_offset1(M0idx)=[]; %remove M0 value 
        
        [info.w_offset1,info.offsetAcqOrder]=sort(info.w_offset1); 
            %sort lowest to highest

        omega_0=str2num(satpars{3});
        omega_0=omega_0(1); %since an array is pulled in 
        if PV360flg %NOTE: convert from ppm to Hz for PV360 
            info.w_offsetPPM=info.w_offset1;
            info.w_offset1=info.w_offset1*omega_0;
        else
            info.w_offsetPPM=info.w_offset1./omega_0;
        end

        % Read in saturation power (in uT)
        if PV360flg
            info.satpwr_uT=str2num(satpars{2});
            info.satpwr_uT=info.satpwr_uT(1); %just 1 value
        else
            info.satpwr_uT=str2double(satpars{2});
        end

        % Sort imaging data based upon offsets
        image=rawdata(:,:,:,info.offsetAcqOrder);
        image=permute(image,[2,1,3,4]);
%         % Read in and sort imaging data
%         image=zeros(Matrix_X,Matrix_Y,niter-1);
%         n1=niter-1;
%         for i=1:nslices    
%             for k=1:(round(n1/2)-1)
%                 image(:,:,k)=rawdata(:,:,i,2*k)';
%             end        
%             image(:,:,round(n1/2))=rawdata(:,:,i,n1)';        
%             for k=1:(round(n1/2)-1)
%                 image(:,:,n1-k+1)=rawdata(:,:,i,2*k+1)';
%             end       
%             M0image=rawdata(:,:,i,1)'; 
%         end
    case 'quesp'
        % Read in saturation powers (in uT) and offsets (in Hz)        
        satpars=readPars(fullfile(pname,'..','..'),'method',...
            {'##$Fp_SatPows','##$Fp_SatOffset','##$Fp_SatDur',...
            '##$PVM_FrqWork','##$PVM_RefPowCh1'});
        trread=readPars(fullfile(pname,'..','..'),'acqp',...
            {'##$ACQ_vd_list'});
        if PV360flg %difference in parameter names with PV360
            pwrread=readPars(fullfile(pname,'..','..'),'method',...
                {'##$PpgPowerList1'});
        else
            pwrread=readPars(fullfile(pname,'..','..'),'method',...
                {'##$PVM_ppgPowerList1'});
        end
        % Expand out new PV360 shorter array format, if found
        satpars=parExpandPV360(satpars);
        trread=parExpandPV360(trread);
        pwrread=parExpandPV360(pwrread);

        nu_0=str2num(satpars{4});
        nu_0=nu_0(1); %since an array is pulled in 

        info.sat_amplitudes=str2num(satpars{1});
        info.sat_powers=str2num(pwrread{1});
        info.ref_power=str2double(satpars{5});
        info.sat_offsets=str2num(satpars{2});        
        if PV360flg %NOTE: convert to Hz for PV360           
            info.sat_offsets=info.sat_offsets*nu_0;
        end
        info.LarmorFreq=nu_0; %in MHz
        info.sat_duration=str2num(satpars{3});
        info.Trec=str2num(trread{1}); %currently this is what 
            % fp_epi uses for TR delay 

        % Check whether any saturation amplitudes were not achieved due to
        % max RF power constraints, using the length of the stored
        % saturation power value, and recalculate the correct values
        powstr=strsplit(satpars{5},' ');
        overpowidx=find(strlength(powstr)==1 & ~strcmp(powstr,'0'));
        if ~isempty(overpowidx)
            warning(['Saturation amplitudes exceeding the max allowable RF power were detected! '...
                'Readjusting amplitude values to their true values...'])
            info.sat_amplitudes(overpowidx)=0.25/.001/42.577*...
                sqrt(info.sat_powers(overpowidx)./info.ref_power);
        end

        % ID reference scans (i.e. where saturation amplitude was set to 0
        % uT), and save separately in M0image. Then remove from all arrays
        % (info.sat_amplitudes last of all)
        M0image=squeeze(permute(rawdata(:,:,:,info.sat_amplitudes<1e-3),...
            [2,1,3,4]));
        rawdata(:,:,:,info.sat_amplitudes<1e-3)=[];
        info.sat_offsets(info.sat_amplitudes<1e-3)=[];        
        info.sat_amplitudes(info.sat_amplitudes<1e-3)=[];

        % Save imaging data (no reordering)
        image = squeeze(permute(rawdata,[2 1 3 4]));
    case 'dictmatch'
        % Save in format for MRF matching with OP Python script (need to
        % permute x and y to match Bruker orientation)
        acquired_data=permute(single(rawdata),[2 1 3 4]);

        % Pull in sequence information 
        parread=readPars(fullfile(pname,'..','..'),'method',...
            {'##$Method','##$Number_fp_Experiments','##$Fp_SatDur','##$Fp_TRDels',...
            '##$Fp_SatPows','##$PVM_FrqWork','##$Fp_SatOffset','##$Fp_SLflag',...
            '##$PVM_RefPowCh1','##$Fp_FlipAngle','##$Fp_SLFlipAngle'});
        if PV360flg %difference in parameter names with PV360
            moreparread=readPars(fullfile(pname,'..','..'),'method',...
                {'##$PVM_SatTransInterPulseDelay','##$PVM_SatTransNPulses',...
                '##$PpgPowerList1'});
        else
            moreparread=readPars(fullfile(pname,'..','..'),'method',...
                {'##$PVM_MagTransInterDelay','##$PVM_MagTransPulsNumb',...
                '##$PVM_ppgPowerList1',});
        end
        trread=readPars(fullfile(pname,'..','..'),'acqp',...
            {'##$ACQ_vd_list'});

        % Expand out new PV360 shorter array format, if found
        parread=parExpandPV360(parread);
        trread=parExpandPV360(trread);  

        % Store MRF schedule parameters in info.seq_defs
        seq_defs.num_meas=str2double(parread{2});
        seq_defs.n_pulses=str2double(moreparread{2});
        seq_defs.tp=str2num(parread{3})./1000; %convert to s
        seq_defs.td=str2num(moreparread{1})./1000; %convert to s
%         info.seq_defs.Trec=str2num(parread{5});
        seq_defs.Trec=str2num(trread{1}); %currently this is what 
            % fp_epi uses for TR delay
        seq_defs.B1pa=str2num(parread{5});

        seq_defs.excFA=str2num(parread{10});
        if ~isempty(parread{11})
            seq_defs.SLFA=str2num(parread{11});
        else
            seq_defs.SLFA=seq_defs.excFA; %use excitation FAs, since that's what 
                % it mistakenly was for a while....
        end
        
        % Store other required values
        nu_0=str2num(parread{6});
        nu_0=nu_0(1); %since an array is pulled in
        offsets_hz=str2num(parread{7});
        if PV360flg %NOTE: convert to Hz for PV360
            offsets_hz=offsets_hz*nu_0;
        end
        isSL=parread{8};
        if ~isempty(strfind(parread{1},'fp_EPI')) || isempty(isSL)
            seq_defs.SLflag=false(size(offsets_hz));
            seq_defs.SLflag(offsets_hz==0)=true;
        else
            seq_defs.SLflag=logical(str2num(isSL));
        end

        seq_pows=str2num(moreparread{3});
        refpow=str2double(parread{9});

        % Check whether any saturation amplitudes were not achieved due to
        % max RF power constraints, using the length of the stored
        % saturation power value, and recalculate the correct values
        powstr=strsplit(moreparread{3},' ');
        overpowidx=find(strlength(powstr)==1 & ~strcmp(powstr,'0'));
        if ~isempty(overpowidx)
            warning(['Saturation amplitudes exceeding the max allowable RF power were detected! '...
                'Readjusting amplitude values to their true values...'])
            seq_defs.B1pa(overpowidx)=0.25/.001/42.577*...
                sqrt(seq_pows(overpowidx)./refpow);
        end

        % Calculate/set other values
        seq_defs.DCsat=seq_defs.tp./(seq_defs.tp+seq_defs.td);
        seq_defs.offsets_ppm=offsets_hz./nu_0;
        seq_defs.Trec_M0=NaN; %currently not reading in
        seq_defs.M0_offset=NaN; %currently not reading in

        % Also save name of schedule file used for acquisition, and B0
        info.schedule=readPars(fullfile(pname,'..','..'),'method',{'##$Fp_FileName'});
        disp(['Schedule file of loaded dataset: ' info.schedule]);
        info.B0=round(nu_0/42.577,1);

        % Run ConfigParams() to generate MRF dictionary parameter ranges
        dictpars=DictConfigParams(info,prefs);

        % Save in .mat format
        save(fullfile(pname,'acquired_data.mat'),'acquired_data','info',...
            'seq_defs','dictpars');
        disp('Data loaded and saved as acquired_data.mat in the same directory as the original 2dseq file');
end
end