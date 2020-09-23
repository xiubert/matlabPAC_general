function Gset = Vwant2gain(Vwant,V_Gref,varargin)
% Vwant2gain: calculate gain needed to achieve desired voltage.
%   Gset = Vwant2gain(Vwant,Vref,Gref)
%           
%       INPUT:
%           Vwant, --> desired voltage output
%           V_Gref --> measured voltage at Gain reference
%                      eg. if calibrated using 1500 gain, V_Gref is
%                      output voltage from mic of stimulus (usually
%                      pure-tone) given Gref gain
%
%           varargin, --> reference gain value used to obtain V_Gref
%                         defaults to 1              
%
%   See also Volt2dB.m, dBwant2voltage.m

switch nargin
    case 2
        Gref = 1;
    case 3
        Gref = varargin{1};
end

Gset = Gref.*(Vwant./V_Gref);
