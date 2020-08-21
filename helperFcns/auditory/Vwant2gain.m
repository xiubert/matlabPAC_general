function Gset = Vwant2gain(Vwant,Vref,varargin)
% Vwant2gain: calculate gain needed to achieve desired voltage.
%   Gset = Vwant2gain(Vwant,Vref,Gref)
%           
%       INPUT:
%           Vwant, --> desired voltage output
%           Vref --> measured reference voltage (eg from mic via oscillocope via
%                       mic calibrator)
%
%           varargin, --> reference gain value used to obtain Vref
%                         defaults to 1              
%
%   See also Volt2dB.m, dBwant2voltage.m

switch nargin
    case 2
        Gref = 1;
    case 3
        Gref = varargin{1};
end

Gset = Gref*(Vwant./Vref);
