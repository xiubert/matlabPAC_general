function [freq,Vrms,sel] = calSelectSounds(cal,varargin)
% calSelectSounds: choose which calibrated stimuli to generate from.
%   [freq,Vrms,sel] = calSelectSounds(cal)
%   [freq,Vrms,sel] = calSelectSounds(cal,'PromptString','Select frequencies')
%   [freq,Vrms,sel] = calSelectSounds(cal,'SelectionMode','single')
%
%       INPUT:
%           cal, --> struct from loadSpeakerCal
%           varargin, --> name/value pairs passed through to listdlg
%
%       OUTPUT:
%           freq --> 1 x nSelected frequencies (NaN for named stimuli
%                    such as broadband noise)
%           Vrms --> nSelected x 1 measured Vrms at cal.Gcal
%           sel  --> indices into cal.soundID
%
%   Legacy inverse-filter calibrations hold nothing but tones, so every
%   entry is returned without prompting. Oscilloscope-file calibrations mix
%   tones and broadband noise, so the user is asked which to use.
%
%   See also loadSpeakerCal.m, calFindSound.m

if strcmp(cal.schema,'legacy')
    sel = 1:numel(cal.soundID);
else
    sel = listdlg('PromptString','Select calibration sounds',...
        'ListString',cal.soundID, varargin{:});
    if isempty(sel)
        error('calSelectSounds:cancelled','no calibration sound selected')
    end
end

freq = cal.freq(sel);
Vrms = cal.Vrms(sel);
