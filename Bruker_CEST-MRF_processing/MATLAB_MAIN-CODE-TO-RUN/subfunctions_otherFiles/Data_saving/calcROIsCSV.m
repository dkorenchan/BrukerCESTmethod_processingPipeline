% calcROIsCSV: Generate table for saving data as .csv
%
%   INPUTS:
%       roi     -   Struct containing information on ROI data.
%       grpstr  -   String identifying which values to put in table.
%                   Options are grpstr={'MRF','other','zSpec'} 
%
%   OUTPUTS:
%       tbl     -   Table containing all values extracted from struct roi.
%       
function tbl = calcROIsCSV(roi,grpstr)
ROIName = {roi.name}';
nROI=numel(roi);
switch grpstr
    case 'MRF'
        DotProductLossMean=zeros(nROI,1);
        DotProductLossStDev=zeros(nROI,1);
        T1Mean=zeros(nROI,1);
        T1StDev=zeros(nROI,1);
        T2Mean=zeros(nROI,1);
        T2StDev=zeros(nROI,1);
        ConcentrationMean=zeros(nROI,1);
        ConcentrationStDev=zeros(nROI,1);
        ExchangeRateMean=zeros(nROI,1);
        ExchangeRateStDev=zeros(nROI,1);
        QUESP_ROIConcentration=zeros(nROI,1);
        QUESP_ROIExchangeRate=zeros(nROI,1);    
        % Construct table of ROI values
        for iii=1:nROI
            DotProductLossMean(iii)=roi(iii).dp.mean;
            DotProductLossStDev(iii)=roi(iii).dp.std;
            T1Mean(iii)=roi(iii).t1w.mean;
            T1StDev(iii)=roi(iii).t1w.std;
            T2Mean(iii)=roi(iii).t2w.mean;
            T2StDev(iii)=roi(iii).t2w.std;    
            ConcentrationMean(iii)=roi(iii).fs.mean;
            ConcentrationStDev(iii)=roi(iii).fs.std;
            ExchangeRateMean(iii)=roi(iii).ksw.mean;
            ExchangeRateStDev(iii)=roi(iii).ksw.std;
            QUESP_ROIConcentration(iii)=roi(iii).fsQUESP.ROIfit;
            QUESP_ROIExchangeRate(iii)=roi(iii).kswQUESP.ROIfit;        
        end
        tbl=table(ROIName,DotProductLossMean,DotProductLossStDev,T1Mean,T1StDev,...
            T2Mean,T2StDev,ConcentrationMean,ConcentrationStDev,ExchangeRateMean,...
            ExchangeRateStDev,QUESP_ROIConcentration,QUESP_ROIExchangeRate);
    case 'other'
        B0Mean=zeros(nROI,1);
        B0StDev=zeros(nROI,1);
        T1Mean=zeros(nROI,1);
        T1StDev=zeros(nROI,1);
        T2Mean=zeros(nROI,1);
        T2StDev=zeros(nROI,1);
        QUESPConcentrationMean=zeros(nROI,1);
        QUESPConcentrationStDev=zeros(nROI,1);
        QUESPExchangeRateMean=zeros(nROI,1);
        QUESPExchangeRateStDev=zeros(nROI,1);    
        % Construct table of ROI values
        for iii=1:nROI
            B0Mean(iii)=roi(iii).B0WASSR_Hz.mean;
            B0StDev(iii)=roi(iii).B0WASSR_Hz.std;
            T1Mean(iii)=roi(iii).t1wIR.mean;
            T1StDev(iii)=roi(iii).t1wIR.std;
            T2Mean(iii)=roi(iii).t2wMSME.mean;
            T2StDev(iii)=roi(iii).t2wMSME.std;
            QUESPConcentrationMean(iii)=roi(iii).fsQUESP.mean;
            QUESPConcentrationStDev(iii)=roi(iii).fsQUESP.std;
            QUESPExchangeRateMean(iii)=roi(iii).kswQUESP.mean;
            QUESPExchangeRateStDev(iii)=roi(iii).kswQUESP.std; 
        end
        tbl = table(ROIName,B0Mean,B0StDev,T1Mean,T1StDev,T2Mean,T2StDev,...
            QUESPConcentrationMean,QUESPConcentrationStDev,...
            QUESPExchangeRateMean,QUESPExchangeRateStDev);    
    case 'zSpec'
        MTRasymMean=zeros(nROI,1);
        MTRasymStDev=zeros(nROI,1); 
        fitOHMean=zeros(nROI,1);
        fitOHStDev=zeros(nROI,1);   
        fitAmineMean=zeros(nROI,1);
        fitAmineStDev=zeros(nROI,1);
        fitAmideMean=zeros(nROI,1);
        fitAmideStDev=zeros(nROI,1);
        fitNOEMean=zeros(nROI,1);
        fitNOEStDev=zeros(nROI,1);
        fitMTMean=zeros(nROI,1);
        fitMTStDev=zeros(nROI,1);        
        B0Mean(iii)=roi(iii).B0WASSRppm.mean;
        B0StDev(iii)=roi(iii).B0WASSRppm.std;
        % Construct table of ROI values
        for iii=1:nROI
            MTRasymMean(iii)=roi(iii).MTRimg.mean;
            MTRasymStDev(iii)=roi(iii).MTRimg.std;
            fitOHMean(iii)=roi(iii).fitImg.OH.mean;
            fitOHStDev(iii)=roi(iii).fitImg.OH.std;
            fitAmineMean(iii)=roi(iii).fitImg.amine.mean;
            fitAmineStDev(iii)=roi(iii).fitImg.amine.std;
            fitAmideMean(iii)=roi(iii).fitImg.amide.mean;
            fitAmideStDev(iii)=roi(iii).fitImg.amide.std; 
            fitNOEMean(iii)=roi(iii).fitImg.NOE.mean;
            fitNOEStDev(iii)=roi(iii).fitImg.NOE.std; 
            fitMTMean(iii)=roi(iii).fitImg.MT.mean;
            fitMTStDev(iii)=roi(iii).fitImg.MT.std;             
        end
        tbl = table(ROIName,MTRasymMean,MTRasymStDev,fitOHMean,fitOHStDev,...
            fitAmineMean,fitAmineStDev,fitAmideMean,fitAmideStDev,fitNOEMean,...
            fitNOEStDev,fitMTMean,fitMTStDev,B0Mean,B0StDev);   
end
end