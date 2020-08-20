function freqAtOctFromFreqIn = freqAtOctDist(freqIn,octaves)
% freqAtOctDist: calculate frequency at [octaves] from [freqIn].
%   freqAtOctDist(freqIn,octaves)
%           
%   See also octBWfreq.m, freqAtOctaveInterval.m

freqAtOctFromFreqIn = freqIn.*(2.^(octaves));
    
end