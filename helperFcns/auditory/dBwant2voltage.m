function Vwant = dBwant2voltage(dBwant,Vref,varargin)
% dBwant2voltage: calculate voltage needed to achieve desired dB.
%   Vwant = dBwant2voltage(dBwant,Vref,dBref)
%           
%       INPUT:
%           dBwant, --> desired dB
%           Vref --> measured reference voltage (eg from mic via oscillocope via
%                       mic calibrator)
%           varargin, --> reference dB from Vref (eg via mic calibrator)
%                         default is 94 dB (B&K Sound Calibrator Type 4231)
%
%
%   See also Volt2dB.m, Vwant2gain.m

switch nargin
    case 2
        dBref = 94;
    case 3
        dBref = varargin{1};
end

Vwant = 10.^((dBwant-dBref)/20).*Vref;
