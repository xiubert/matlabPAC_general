function dB = Volt2dB(Vout,Vref,varargin)
% Volt2dB: calculate dB from voltage output (eg mic voltage reading on oscillosope).
%   dB = Volt2dB(Vout,VmicCal,dBref)
%           
%       INPUT:
%           Vout, --> measured voltage from mic via oscilloscope
%           Vref --> measured reference voltage (eg from mic via oscillocope via
%                       mic calibrator)
%           varargin, --> reference dB of Vref (eg from mic calibrator
%                         default is 94 dB (B&K Sound Calibrator Type 4231)
%
%
%   See also dBwant2voltage.m, Vwant2gain.m

if ~isempty(varargin) && length(varargin)==1
    dBref = varargin{1};
elseif isempty(varargin)
    dBref = 94;
else
    error('Too many inputs')
end

dB = 20*log10(Vout/Vref)+dBref;
