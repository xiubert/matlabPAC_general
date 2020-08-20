function freqVector = freqAtOctaveInterval(startFreq,endFreq,octaveInterval)
% freqAtOctaveInterval: create frequency vector from startFreq to endFreq
%                       with frequency steps at octave interval
%   freqVector = freqAtOctaveInterval(startFreq,endFreq,octaveInterval)
%           
%   See also octBWfreq.m, freqAtOctDist.m

freqVector = [startFreq ...
    freqAtOctDist(startFreq,octaveInterval:octaveInterval:octBWfreq(startFreq,endFreq))...
    startFreq.*2^(octBWfreq(startFreq,endFreq))];

end