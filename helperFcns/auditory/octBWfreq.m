function octDiff = octBWfreq(freqA,freqB)
% octBWfreq: calculate octave distance from freqA to freqB.
%   dB = Volt2dB(freqA,freqB)
%           
%   See also freqAtOctDist.m, freqAtOctaveInterval.m

octDiff = log2(freqB./freqA);