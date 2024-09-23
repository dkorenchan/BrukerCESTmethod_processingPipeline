function quesp = QUESPfcn(Zlab,Zref,P,ext_opts,PlotFlag)
%Function from Moritz Zaiss folder: (www.cest-sources.org)
%Change log: 07/24/18 - minor syntax change by OP
%                       Added PlotFlag
%            2/22/19  - removed offset frequency from legend (OP)
%            12/22/23 - added optional field P.fitidx to fit a subset of
%                       input points while plotting excluded points too (DK)
%            3/21/24  - tightened up QUESP fitting routine to be more
%                       robust over a large range of values - big help! (DK)
%            5/4/24   - BUG FIX: P.Zi parameter was not being incorporated
%                       into model fitting -- fixed now
%            9/20/20  - Added in omega plot fitting from function
%                       OmegaPlot.m (only the fitting corresponding with
%                       ii=1 in that file). Also adjusted so that the
%                       function can take an additional parameter
%                       P.fittypes, which is a cell array of strings
%                       containing all desired fitting functions to use 
%                       (options: {'Regular','Inverse','OmegaPlot'}).
%                       Output is now a struct with fieldnames above
%                       containing all fitted parameters
if iscell(P.vary)
    P.vary=P.vary{1};
end


if strcmp(P.vary,'B1')==0
    error('It seems you varied %s, you need to vary B1 for QUESP',P.vary{1});
end

if isfield(P,'fitidx')
    Zref_nofit=Zref;
    Zref_nofit(P.fitidx)=[]; %remove points to be fitted
    Zlab_nofit=Zlab;
    Zlab_nofit(P.fitidx)=[]; %remove points to be fitted
    Zref=Zref(P.fitidx);
    Zlab=Zlab(P.fitidx);

    P.varyval_nofit=P.varyval;
    P.varyval_nofit(P.fitidx)=[]; %remove points to be fitted
    P.varyval=P.varyval(P.fitidx);
else
    Zref_nofit=[];
    Zlab_nofit=[]; 
    P.varyval_nofit=[];
end

% ID which fitting types in cell array P.fittypes are specified
validIdx=strcmpi(P.fittypes,'Regular') | strcmpi(P.fittypes,'Inverse') | ...
    strcmpi(P.fittypes,'OmegaPlot');
fitFcns=P.fittypes(validIdx);
if isempty(fitFcns)
    error(['No valid QUESP fitting function types were specified! '...
        'Valid options are "Regular", "Inverse", or "OmegaPlot"'])
end

for ii=1:numel(fitFcns)
    fcn=fitFcns{ii};
    switch fcn
        case 'Regular'
            MTR=Zref-Zlab;
            MTR_nofit=Zref_nofit-Zlab_nofit;
%             MTR=(Zref-Zlab)./(Zref-Zlab+Zref.*Zlab);
%             MTR_nofit=(Zref_nofit-Zlab_nofit)./(Zref_nofit-Zlab_nofit+Zref_nofit.*Zlab_nofit);
            if isempty(P.normalized)
%                 modelstr= @(fb,kb,R1,x,w1) fb.*kb.*w1.^2./(w1.^2+kb.^2)./(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2))-(P.Zi- R1./(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2))).*exp(-(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2)).*x)+(P.Zi-1).*exp(-R1.*x);
                modelstr= @(fb,kb,R1,x,Zi,w1) fb.*kb.*w1.^2./(w1.^2+kb.^2)./(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2))-(Zi- R1./(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2))).*exp(-(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2)).*x)+(Zi-1).*exp(-R1.*x);
            else
%                 modelstr= @(fb,kb,R1,x,w1) (fb.*kb.*w1.^2./(w1.^2+kb.^2)./(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2))-(P.Zi- R1./(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2))).*exp(-(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2)).*x)+(P.Zi-1).*exp(-R1.*x))./(1+(P.Zi-1).*exp(-R1.*x));
                modelstr= @(fb,kb,R1,x,Zi,w1) (fb.*kb.*w1.^2./(w1.^2+kb.^2)./(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2))-(Zi- R1./(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2))).*exp(-(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2)).*x)+(Zi-1).*exp(-R1.*x))./(1+(Zi-1).*exp(-R1.*x));
            end
            probvarnames={'R1','x','Zi'};
            probvals={P.R1A P.tp P.Zi};
            if P.pulsed
                probvals{2}=P.tp*P.n/P.DC;
            end

            [xData, yData] = prepareCurveData( P.varyval*gamma_2pi, MTR );
            [xData_nofit, yData_nofit] = prepareCurveData( P.varyval_nofit*gamma_2pi, MTR_nofit );

            ft = fittype(modelstr, 'problem', probvarnames, 'independent', {'w1'}, 'dependent', 'y' ); 

            % Plotting items
            ylbl='MTR_{asym}';
            eqn_lbl='QUESP fit, \nf_s=%.2e±%.2e \nk_{sw}=%.2f±%.2f s^{-1} \nR^2=%.3f';

        case 'Inverse'        
            MTR=1./Zlab-1./Zref;
            MTR_nofit=1./Zlab_nofit-1./Zref_nofit;
            
            modelstr= @(fb,kb,R1,x,w1) fb.*kb.*w1.^2./(w1.^2+kb.^2)./R1*x/x;
            %NOTE: THE PULSED CONDITION NEEDS TO BE TESTED
            if P.pulsed
                c1= 1/(2*2.92)*sqrt(2*pi);
                c22=(c1*sqrt(sqrt(2))).^2;
%                  c1=0.5
%                  c22=0.35;
                modelstr= @(fb,kb,R1,x,DC,c1,c22,w1) DC.*c1.*fb.*kb.*w1.^2./(w1.^2+kb.^2.*c22)./R1*x/x;
                probvarnames={'R1','x','DC','c1','c22'};
                probvals={P.R1A P.tp*P.n/P.DC P.DC c1 c22};
            else
                probvarnames={'R1','x'};
                probvals={P.R1A P.tp};
            end
%             .*(1-exp(-(R1+fb.*kb.*w1.^2./(w1.^2+kb.^2)).*x));

            [xData, yData] = prepareCurveData( P.varyval*gamma_2pi, MTR );
            [xData_nofit, yData_nofit] = prepareCurveData( P.varyval_nofit*gamma_2pi, MTR_nofit );
    
            ft = fittype(modelstr, 'problem', probvarnames, 'independent', {'w1'}, 'dependent', 'y' ); 

            % Plotting items
            ylbl='MTR_{Rex}';
            eqn_lbl='QUESP fit, \nf_s=%.2e±%.2e \nk_{sw}=%.2f±%.2f s^{-1} \nR^2=%.3f';

        case 'OmegaPlot'
            MTR=1./Zlab-1./Zref;
            MTR_nofit=1./Zlab_nofit-1./Zref_nofit;
%             ylab='(MTR_{Rex})^{-1}';
                    
            modelstr= @(fb,kb,R1,xx) R1*(1./(fb.*kb) + kb./fb.*xx );
    
            probvarnames={'R1'};
            probvals={P.R1A};

            [xData, yData] = prepareCurveData( 1./(P.varyval*gamma_2pi).^2, 1./MTR );
            [xData_nofit, yData_nofit] = prepareCurveData( 1./(P.varyval_nofit*gamma_2pi).^2, 1./MTR_nofit );
    
            ft = fittype(modelstr, 'problem', probvarnames, 'independent', {'xx'}, 'dependent', 'y' );

            % Plotting items
            ylbl='(MTR_{Rex})^{-1}';
            eqn_lbl='Omega-plot fit, \nf_s=%.2e±%.2e \nk_{sw}=%.2f±%.2f s^{-1} \nR^2=%.3f';

            % DK: Modified to put excluded points into non-fitted data, but haven't
            % tested!
            findneg = (yData < 0);
            if sum(findneg) > 0 %detect if some yData values are negative
                warning('Omega plot: some yData values are negative! Excluding from fit')
                xData_nofit = [xData_nofit; xData(findneg)];
                yData_nofit = [yData_nofit; yData(findneg)];
                xData(findneg) = [];        
                yData(findneg) = [];
            end
    
            opts.Weights=1./yData;

    end

    % Set up fittype and options.
    % ft = fittype(modelstr, 'problem', {'R1','x'}, 'independent', {'w1'}, 'dependent', 'y' ); 
    % opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts = fitoptions('Method','NonlinearLeastSquares','DiffMaxChange',1e-3,...
        'DiffMinChange',1e-12,'MaxFunEvals',6000,'MaxIter',4000,'TolFun',1e-12,...
        'TolX',1e-12);
    opts.Display = 'Off';
    opts.Lower      = [0.0000135 0];
    opts.StartPoint = [0.000135 4000];
    opts.Upper      = [0.0135 150000];
    
    if nargin>4  % read in extern options
        opts.Lower  = ext_opts.Lower  ;
        opts.StartPoint = ext_opts.StartPoint;
        opts.Upper      = ext_opts.Upper ;
    
    else
            warning('Internal Startvalue and boundaries used');
    end
        
    
    % Fit model to data.
%     if P.pulsed
%     [fitresult, gof] = fit( xData, yData, ft, opts, 'problem', {P.R1A (P.tp*P.n/P.DC)} );
%     else
%     [fitresult, gof] = fit( xData, yData, ft, opts, 'problem', {P.R1A P.tp} );
%     end
    
    [fitresult, gof] = fit( xData, yData, ft, opts, 'problem', probvals );
    
    % Plot fit with data if requested by user
    if PlotFlag
        subplot(1,numel(fitFcns),ii);
        h = plot(xData,yData,'bo'); hold on;
        if ~isempty(xData_nofit)
            h(2) = plot(xData_nofit,yData_nofit,'bx');
        end
        h(end+1) = plot(fitresult);
    end

    % Store fitted values in struct 
    ci = confint(fitresult);
    ci = ci(2,:)-coeffvalues(fitresult);
    
    quesp.(fcn).kBA=[fitresult.kb ci(2)];
    quesp.(fcn).fB=[fitresult.fb ci(1)];
    quesp.(fcn).MTR=MTR;
    quesp.(fcn).w_x=xData;
    quesp.(fcn).rsq=gof.rsquare;
    quesp.(fcn).fit=fitresult;
    
    % Plot fit with data if requested by user
    if PlotFlag
        if ~isempty(xData_nofit)
            legend( h, sprintf(ylbl), sprintf('Excluded from fit'),...
                sprintf(eqn_lbl,fitresult.fb,ci(1),fitresult.kb,ci(2),...
                gof.rsquare), 'Location', 'NorthWest','FontSize',14);
        else
            legend( h, sprintf('MTR_{asym}'),...
                sprintf(eqn_lbl,fitresult.fb,ci(1),fitresult.kb,ci(2),...
                gof.rsquare), 'Location', 'NorthWest','FontSize',14);
        end
        % Label axes
        xlabel( P.vary );
        ylabel( ylbl );
        grid on
        axis square tight
    end

end

end