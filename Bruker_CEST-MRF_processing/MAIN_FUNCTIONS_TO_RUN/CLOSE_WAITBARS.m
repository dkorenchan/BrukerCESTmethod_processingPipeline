% CLOSE_WAITBARS: Run this to close any waitbar windows from
% MATCH_MRF_MULTI (in case an error was reached or something was terminated
% prematurely)
%
F = findall(0,'type','figure','tag','TMWWaitbar');
delete(F);
