function idx = calFindSound(cal,ids)
% calFindSound: index calibrated stimuli by frequency or by sound ID.
%   idx = calFindSound(cal,[7711 15422])
%   idx = calFindSound(cal,{'BB_6-64'})
%
%       INPUT:
%           cal, --> struct from loadSpeakerCal
%           ids, --> numeric frequencies (Hz) or a char/cellstr of sound IDs
%
%       OUTPUT:
%           idx --> index into cal.soundID / cal.Vrms, one per requested id
%
%   Use this instead of reading gains out of a calibration file's TgainSet
%   table: that table's column names differ between rigs ('lvl_70_dB' vs
%   '70 dB'). Look the stimulus up here and recompute the gain with
%   dBwant2voltage/Vwant2gain.
%
%   See also loadSpeakerCal.m, calSelectSounds.m

if ischar(ids)
    ids = {ids};
end

idx = zeros(1,numel(ids));
for k = 1:numel(ids)
    if iscell(ids)
        hit = find(strcmp(cal.soundID, ids{k}));
    else
        %frequencies round-trip through their string IDs, so match on the
        %nearest rather than on exact equality
        [d,hit] = min(abs(cal.freq - ids(k)));
        if isempty(d) || isnan(d) || d > 0.5
            hit = [];
        end
    end
    if isempty(hit)
        if iscell(ids), want = ids{k}; else, want = num2str(ids(k)); end
        error('calFindSound:notFound',...
            '"%s" is not in %s. Available: %s', want, cal.file,...
            strjoin(cal.soundID', ', '))
    end
    idx(k) = hit(1);
end
