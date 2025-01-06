% plotAxImg: Plots all axial images within the GUI given the selected 
% settings. 
%
%   INPUTS:
%       img             -   Struct containing images
%       roi             -   Struct containing ROI data       
%       settings        -   Struct containing dynamic GUI display settings
%                           determined by user interfacing with GUI
%       si              -   Handle for UI control item in GUI that sets a
%                           label string indicating the status of the GUI
%
%   OUTPUTS:    None
%
function plotAxImg(img,roi,settings,si)

nROI=numel(roi);
[i_flds,lbls,cblims]=initPlotParams;

if strcmp(settings.plotgrp,'MRF') && settings.maskImgs 
    % Mask all MRF images using dot-product loss
    mask.MRF=(img.MRF.dp>settings.dpMaskVal);
else
    mask.(settings.plotgrp)=true(img.(settings.plotgrp).size);
end
% mask.ErrorMaps=true(size(img.(settings.plotgrp).(i_flds.(settings.plotgrp){1})));
% mask.zSpec=true(size(img.(settings.plotgrp).(i_flds.(settings.plotgrp){1})));
% mask.other=true(size(img.(settings.plotgrp).(i_flds.(settings.plotgrp){1})));
set(si,'String','Loading...')
pause(0.01) % ensures the status text above displays
if strcmp(settings.plotgrp,'ErrorMaps')
    tiledlayout(2,9);
    nexttile;axis('off')
else
    tiledlayout(2,6);
end
for iii = 1:length(i_flds.(settings.plotgrp))
    % Plot image, making voxels outside ROIs black (if ErrorMaps)
    nexttile([1 2]); 
    if strcmp(settings.plotgrp,'ErrorMaps')
        imagesc(zeros([img.(settings.plotgrp).size,3])); hold on;
        if isfield(roi,'mask')
            if contains(i_flds.ErrorMaps{iii},'fs')
                allROImask=zeros(size(img.ErrorMaps.(i_flds.ErrorMaps{iii})));
                if isfield(roi,'nomConc')
                    for jjj=1:nROI           
                        if ~isempty(roi(jjj).nomConc)
                            if ~isinf(roi(jjj).nomConc) && ~isnan(roi(jjj).nomConc)
                                allROImask=allROImask+roi(jjj).mask;
                            end
                        end
                    end
                end    
            else
                allROImask=sum(reshape([roi.mask],[size(roi(1).mask),length(roi)]),3);
            end
            ei=imagesc(img.ErrorMaps.(i_flds.ErrorMaps{iii}).*mask.ErrorMaps); ...
                title(lbls.ErrorMaps.title{iii},'FontSize',18);
            % If QUESP error maps: use R^2 mask to mask out non-fitted values
            if contains(i_flds.ErrorMaps{iii},'QUESP')
                set(ei,'AlphaData',allROImask.*img.other.RsqMask);
            else
                set(ei,'AlphaData',allROImask);
            end
            axis('equal','off');
            cb=colorbar; clim(cblims.ErrorMaps{iii}); cb.FontSize = 14;
            cb.Label.String=lbls.ErrorMaps.cb{iii}; cb.Label.FontSize=16;
            colormap(bluewhitered);
            hold off;
        end
        if iii==4 %jump down to next plotting row
            nexttile; axis('off')
        end
    else
        if strcmp(i_flds.(settings.plotgrp){iii},'avgZspec') %plot spectrum, not image!
            if isfield(img.zSpec,'avgZspec')
                scatter(img.zSpec.ppm,img.zSpec.avgZspec.all.spec(settings.roiidx,:),...
                    'LineWidth',1);
                hold on; 
                
                % Plot MTR asymmetry
                plot(img.zSpec.MTRppm,img.zSpec.avgZspec.all.MTRasym(settings.roiidx,:),...
                    'r--*','MarkerSize',4);

                % Plot fitted pools
                pools=fieldnames(img.zSpec.avgZspec);
                for jjj=1:numel(pools)
                    pool=pools{jjj};
                    plot(img.zSpec.ppm,img.zSpec.avgZspec.(pool).fitSpec(settings.roiidx,:));
                end
                legend([{'Raw data'};{'MTR_{asym}'};pools],'Location','southeast');
                title([lbls.zSpec.title{iii} ', ROI ' roi(settings.roiidx).name],...
                    'FontSize',18);
                xlabel('Offset (ppm)'); ylabel('M_{sat}/M_0');
                xlim([min(img.zSpec.ppm) max(img.zSpec.ppm)]);
                axis('square'); set(gca,'XDir','reverse');
            else
                axis('off');
            end
        else
            if strcmp(i_flds.(settings.plotgrp){iii},'fitImg') %display the fitted subimage!
                imagesc(img.(settings.plotgrp).fitImg.(settings.selPool)...
                    .*mask.(settings.plotgrp)); 
                title([lbls.(settings.plotgrp).title{iii} ', ' settings.selPool],...
                    'FontSize',18);  
                %DK TO DO: Scale image based upon the max (non-water)
                %fitted voxel intensity across all pools
            else
                imagesc(img.(settings.plotgrp).(i_flds.(settings.plotgrp){iii})...
                    .*mask.(settings.plotgrp));
                if strcmp(i_flds.(settings.plotgrp){iii},'MTRimg')
                    title([lbls.(settings.plotgrp).title{iii} ', ' ...
                        num2str(settings.MTRppm,'%2.1f') ' ppm'],'FontSize',18);
                else
                    title(lbls.(settings.plotgrp).title{iii},'FontSize',18);
                end
            end
            axis('equal','off');
            cb=colorbar; clim(cblims.(settings.plotgrp){iii}); cb.FontSize = 14;
            cb.Label.String=lbls.(settings.plotgrp).cb{iii}; cb.Label.FontSize=16;
            colormap default;
            if isfield(roi,'coords') 
                for jjj=1:length(roi)
                    drawpolygon('Position',roi(jjj).coords);
                end
            end
        end
        if iii==3 % add in another spacer plot
            nexttile; axis('off')
        end
    end
end
set(si,'String','')
end