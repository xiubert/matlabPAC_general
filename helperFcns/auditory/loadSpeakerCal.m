function cal = loadSpeakerCal(varargin)
% loadSpeakerCal: load a speaker calibration file into one canonical struct,
% whichever schema the file uses.
%   cal = loadSpeakerCal()          --> prompt for a file
%   cal = loadSpeakerCal(fullPath)
%   cal = loadSpeakerCal(path,file)
%
%       OUTPUT: struct with fields
%           file, path  --> where it was loaded from
%           schema      --> 'Tmean'  oscilloscope-file calibration
%                           (calibrationOutput_oscopeFile_*.mat)
%                       --> 'legacy' inverse-filter calibration carrying
%                           freq + Vout (InvFiltCal_*.mat)
%           micCalV     --> reference Vrms of the mic calibrator (scalar)
%           micCaldB    --> dB SPL of that reference (94 if file omits it)
%           Gcal        --> stimulator gain the calibration stimuli were
%                           played at
%           soundID     --> nSounds x 1 cellstr, one per calibrated
%                           stimulus (the calibrator reference is removed)
%           Vrms        --> nSounds x 1 measured Vrms at Gcal
%           freq        --> 1 x nSounds numeric value of each soundID,
%                           NaN where the ID is not a bare frequency
%
%   Vrms is a column and freq is a row because that is how the generation
%   scripts use them: Vwant2gain(Vwant,Vrms,Gcal) then broadcasts to
%   nSounds x nLevels, and sin(2*pi*freq'.*t) builds one tone per row.
%
%   NOTE: gain is always recomputed from Vrms rather than read out of the
%         file's TgainSet table. TgainSet column names differ between rigs
%         ('lvl_70_dB' vs '70 dB'), so indexing it by name is not portable.
%
%   See also calSelectSounds.m, calFindSound.m, dBwant2voltage.m,
%   Vwant2gain.m

switch nargin
    case 0
        [f,p] = uigetfile(...
            'C:\Data\Rig Software\speakerCalibration\calibrationOutput*.mat',...
            'Load speaker calibration file');
        if isequal(f,0)
            error('loadSpeakerCal:cancelled','no calibration file selected')
        end
    case 1
        [p,n,x] = fileparts(varargin{1});
        f = [n x];
        p = [p filesep];
    case 2
        p = varargin{1};
        f = varargin{2};
    otherwise
        error('loadSpeakerCal:nargin','too many inputs')
end

S = load(fullfile(p,f));
sFields = fieldnames(S);
c = S.(sFields{1});
if ~isstruct(c)
    error('loadSpeakerCal:notCal','%s does not hold a calibration struct',f)
end

cal.file = f;
cal.path = p;

%% required scalars
if ~isfield(c,'Gcal')
    error('loadSpeakerCal:noGcal','%s has no Gcal field',f)
end
cal.Gcal = c.Gcal;
%micCalV is stored as one value per repeat in some calibrations
cal.micCalV = mean(c.micCalV);
if isfield(c,'micCaldB')
    cal.micCaldB = c.micCaldB;
else
    cal.micCaldB = 94; %B&K Sound Calibrator Type 4231
end

%% stimuli, from whichever schema the file uses
if isfield(c,'Tmean') && istable(c.Tmean)
    cal.schema = 'Tmean';
    %the calibrator reference row is not a stimulus
    isRef = contains(c.Tmean.sound_ID,'reference');
    cal.soundID = c.Tmean.sound_ID(~isRef);
    cal.Vrms = c.Tmean.Vrms(~isRef);
elseif isfield(c,'freq') && isfield(c,'Vout')
    cal.schema = 'legacy';
    cal.soundID = arrayfun(@(x) num2str(x), c.freq(:), 'UniformOutput', false);
    cal.Vrms = mean(c.Vout,2); %one column per repeat
else
    error('loadSpeakerCal:unknownSchema',...
        '%s has neither a Tmean table nor freq/Vout fields',f)
end

cal.soundID = cal.soundID(:);
cal.Vrms = cal.Vrms(:);
if numel(cal.soundID)~=numel(cal.Vrms)
    error('loadSpeakerCal:sizeMismatch',...
        '%d sound IDs but %d Vrms values in %s',...
        numel(cal.soundID), numel(cal.Vrms), f)
end

%NaN wherever the ID is a name rather than a bare frequency (eg. 'BB_6-64')
cal.freq = str2double(cal.soundID)';
