function [b,a] = butterFilterHelper(cutoffFreq,order,samplingRate,HighOrLowPass)
%HELPER FOR A SIMPLE HIGH/LOW PASS BUTTERWORTH FILTER
%apply using: filteredSignal = filter(b,a,Signal);

Wn = cutoffFreq/(samplingRate/2); %normalized cutoff freq

[b,a] = butter(order,Wn,HighOrLowPass);

