% MTRphase: Optimization function used to perform 1st-order phasing of 
% (1-z), if desired by user
%
%   INPUTS:
%       x       -   Linear phase factor to apply across the MTR spectrum,
%                   in units of rad/ppm
%       w       -   Vector of frequency values corresponding to each point
%                   in the MTR spectrum, in ppm
%       z       -   Vector of signal values comprising the MTR spectrum
%
%   OUTPUTS:
%       res     -   Value corresponding to the difference between the first
%                   and last signal amplitudes after phasing, to be
%                   minimized by the optimization method
%
function res=MTRphase(x,w,z)
zph=real(z.*exp(-x*w));
% res=z(1)-zph(1)+z(end)-zph(end); %I don't think this is right....
res=abs(zph(1)-zph(end));
end