% initPlotParams: Initialize structures containing fieldnames for all MRF 
% parameter maps, plus associated plot labels (titles, colorbars) and 
% colorbar limits. If you want to change colorbar limits for image
% plotting, change the 
%   INPUTS:     None
%   OUTPUTS:    
%       i_flds      -   Struct containing cell arrays of names of the 
%                       images pertaining to how struct 'img' is organized, 
%                       further organized by plotting groups
%       lbls        -   Struct containing cell arrays of titles and labels 
%                       of the images, organized by plotting groups
%       cblims      -   Struct containing cell arrays of the colorbar
%                       limits for image plotting, organized by plotting 
%                       groups
%
function [i_flds,lbls,cblims] = initPlotParams()
if nargout==3
    disp(['Loading plotting colormap bounds, labels, and image names from '...
        'file initPlotParams.m...'])
end

% You will probably want to change the values below at some point! These 
% are organized in the following way:
%       .MRF: colorbar limits for   {[MRF dot product loss (unitless)],
%                                    [MRF T1 values (s)],
%                                    [MRF T2 values (s)],
%                                    [MRF concentration (mM)],
%                                    [MRF exchange rate (s^-1)]}
%       .other: colorbar limits for {[WASSR B0 map (Hz)],
%                                    [T1 map (s)],
%                                    [T2 map (s)],
%                                    [QUESP concentration (mM)],
%                                    [QUESP exchange rate (s^-1)]}
%       .zspec: colorbar limits for {[MTR asymmetry],
%                                    [z-spectrum],
%                                    [voxelwise z-spectral peak fits],
%                                    [WASSR B0 map (ppm)],
%                                    [M0 image]}
%       .ErrorMaps: cb lims for     {[MRF raw concentration error (mM)],
%                                    [MRF % concentration error (%)],
%                                    [MRF raw exchange rate error (s^-1)],
%                                    [MRF % exchange rate error (%)],
%                                    [QUESP raw concentration error (mM)],
%                                    [QUESP % concentration error (%)],
%                                    [QUESP raw exchange rate error (s^-1)],
%                                    [QUESP % exchange rate error (%)]}
%
cblims.MRF={[0.997 1],[0 Inf],[0 Inf],[0 Inf],[0 Inf]};
cblims.other={[-100 100],[0 3],[0 1.5],cblims.MRF{4},cblims.MRF{5}};
cblims.zSpec={[-0.01 0.15],[0 1.1],[0 .2],[-1 1],[0 Inf]};
cblims.ErrorMaps={[-1 1]*8,[-1 1]*30,[-1 1]*2000,[-1 1]*75,[-1 1]*8,...
    [-1 1]*30,[-1 1]*2000,[-1 1]*75};

% You probably DO NOT want to change anything below here!
%
i_flds.MRF={'dp','t1w','t2w','fs','ksw'};
i_flds.ErrorMaps={'fsAbs','fsPct','kswAbs','kswPct','fsQUESPAbs','fsQUESPPct',...
    'kswQUESPAbs','kswQUESPPct'};
i_flds.zSpec={'MTRimg','avgZspec','fitImg','B0WASSRppm','M0img'}; 
i_flds.other={'B0WASSR_Hz','t1wIR','t2wMSME','fsQUESP','kswQUESP'};

% This is for z-spectral fitting pools
i_flds.poolnames={'water','NOE','MT','OH','amine','amide'};

lbls.MRF.title={'MRF dot product loss','MRF T_1','MRF T_2',...
    'MRF concentration','MRF exchange rate'};
lbls.MRF.cb={'','T_1 (s)','T_2 (s)','Concentration (mM)','k_{sw} (s^{-1})'};
lbls.zSpec.title={'MTR_{asym}','Average z-spectrum','Fitted peak amplitude',...
    'WASSR \DeltaB_0','M_0 image'};
lbls.zSpec.cb={'MTR_{asym}','','','\DeltaB_0 (ppm)',''};
lbls.other.title={'WASSR \DeltaB_0','T_1 map, RAREVTR','T_2 map, MSME',...
    'QUESP concentration (mM)','QUESP k_{sw} (s^{-1})'};
lbls.other.cb={'\DeltaB_0 (Hz)','T_1 (s)','T_2 (s)','Concentration (mM)',...
    'k_{sw} (s^{-1})'};
lbls.ErrorMaps.title={'MRF f_s error from nominal, mM','MRF f_s error from nominal, %',...
    'MRF k_{sw} error from nominal, s^{-1}','MRF k_{sw} error from nominal, %',...
    'QUESP f_s error from nominal, mM','QUESP f_s error from nominal, %',...
    'QUESP k_{sw} error from nominal, s^{-1}','QUESP k_{sw} error from nominal, %'};
lbls.ErrorMaps.cb={'Concentration error (mM)','Concentration error (%)',...
    'k_{sw} error (s^{-1})','k_{sw} error (%)','Concentration error (mM)',...
    'Concentration error (%)','k_{sw} error (s^{-1})','k_{sw} error (%)'};
end