% DictConfigParams: Outputs a structure variable dictparams containing the  
% values to simulate for the dictionary generation, to be saved in 
% acquired_data.mat  
%
%   INPUT:  seq_info    -   Struct containing pulse sequence info and
%                           parameter values
%           prefs       -   Struct containing user specific processing options
%   OUTPUT: dictparams  -   Struct containing vector arrays pertaining to
%                           the values to simulate during dictionary
%                           generation
%
function dictparams = DictConfigParams(seq_info,prefs)
disp('Loading dictionary simulation settings from file DictConfigParams.m...')

% Water pool
dictparams.water_t1 = 1.5:.05:4; %water T1 values, in s
dictparams.water_t2 = .5:.05:2.5; %water T2 values, in s
% dictparams.water_t1 = 2:.05:3.5; %water T1 values, in s
% dictparams.water_t2 = .5:.05:2; %water T2 values, in s
% dictparams.water_t2 = 2.3;
dictparams.water_f = 1; %water proton volume fraction(?)

% Solute pool
dictparams.cest_amine_t1 = 2.8;  % fixed solute t1, in s
dictparams.cest_amine_t2 = .04;  % fixed solute t2, in s
dictparams.cest_amine_k = 50:50:5000;  % solute exchange rate, in s^-1
% dictparams.cest_amine_k = 10:10:1500;  % solute exchange rate, in s^-1
dictparams.cest_amine_dw = 3;  % solute chemical shift offset, in ppm

% solute concentration * protons / water concentration
% dictparams.cest_amine_sol_conc = 2:2:120;  % solute concentration, in mM
dictparams.cest_amine_sol_conc = 0.5:0.5:30;  % solute concentration, in mM
dictparams.cest_amine_protons = 3;
dictparams.cest_amine_water_conc = 110000;  %in mM
dictparams.cest_amine_f = dictparams.cest_amine_sol_conc * ...
    dictparams.cest_amine_protons ./ dictparams.cest_amine_water_conc;

if prefs.nPools > 2
    disp('More than 2 pools specified! Adding additional pool...')
    dictparams.cest_mt_t1 = dictparams.cest_amine_t1;
    dictparams.cest_mt_t2 = dictparams.cest_amine_t2;
    dictparams.cest_mt_k = 100:100:3000;
    dictparams.cest_mt_dw = 0.6;
    
    % "MT" solute concentration * protons / water concentration
    dictparams.cest_mt_protons = 2;
    dictparams.cest_mt_water_conc = 110000;
    dictparams.cest_mt_sol_conc = dictparams.cest_amine_sol_conc * ...
        dictparams.cest_mt_protons / dictparams.cest_amine_protons;
    dictparams.cest_mt_f = dictparams.cest_mt_sol_conc * ...
        dictparams.cest_mt_protons / dictparams.cest_mt_water_conc;
end

% Fill initial magnetization info
dictparams.magnetization_scale = 1;
dictparams.magnetization_reset = 0;

% Fill scanner info
dictparams.b0 = seq_info.B0;  % [T]
dictparams.gamma = 267.5153;  % [rad / uT]
dictparams.b0_inhom = 0;
dictparams.rel_b1 = 1;

% Initial magnetization info: this is important now for the mrf simulation! 
% For the regular pulseq-cest simulation, we usually assume that the 
% magnetization reached a steady state after the readout, which means we 
% can set the magnetization vector to a specific scale, e.g. 0.5. This is 
% because we do not simulate the readout there. For mrf we include the 
% readout in the simulation, which means we need to carry the same 
% magnetization vector through the entire sequence. To avoid that the 
% magnetization vector gets set to the initial value after each readout, we 
% need to set reset_init_mag to false

% Check that size of dictionary won't be too large to save!
max_size=18800000; %from current experience
dict_size=size(dictparams.water_t1,2)*size(dictparams.water_t2,2)*...
    size(dictparams.cest_amine_k,2)*size(dictparams.cest_amine_f,2);
if dict_size > max_size
    error('Dictionary size is too large! Python script will crash at end if run')
end
end