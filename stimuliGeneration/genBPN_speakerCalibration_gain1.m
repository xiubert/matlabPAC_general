function [] = genBPN_speakerCalibration_gain1()
% genBPN_speakerCalibration_gain1:      create band-pass white noise
%                                       at gain = 1 with lower and upper
%                                       frequency bounds
%
%
%   IMPORTANT: WHEN USING THESE .signal FILES,
%              GAIN SHOULD BE SET TO SOME VALUE THAT RESULTS IN READABLE
%              OUTPUT FROM OSCILLOSCOPE
%
%   See also genPureTone_transcranial_hardcodedGain.m, genPureTone_speakerCalibration_gain1, inspectSignalObject.m

%% PARAMS
signalSavePath = 'C:\Data\Rig Software\250kHzPulses\';
fSampling = 250000; %sample rate for signal (via DAQ settings)
pulseOnset = 0; %seconds | delay time before tone onset in signal
pulseLen = 30; %s | duration of pure-tone (just pure-tone not entire signal)
traceLength = 30; %duration of .signal (s)

%CHOOSE RAMP TYPE (ramp up to pure tone at beginning and ramp down at end)
rampType = 'linear';
% rampType = 'sinSquared';
rampTime = 10; %ms

%BPN params
loFq = 5000; %Low Freq Cutoff (Hz) for BPN
hiFq = 25000; %High Freq Cutoff (Hz) for BPN
filtOrder = 100; %bandpass filter order

defPinput = {signalSavePath,num2str(fSampling),num2str(pulseOnset),num2str(pulseLen),...
    num2str(traceLength),rampType,num2str(rampTime),num2str(loFq),num2str(hiFq),num2str(filtOrder)};
params = inputdlg({'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'BPN onset (s)',...
    'BPN duration (s)',...
    'Duration of entire stimulus (s)',...
    'Onset ramp type ("linear" or "sinSquared")',...
    'Onset ramp time (ms)',...
    'Low Frequency Cutoff (Hz)',...
    'High Frequency Cutoff (Hz)',...
    'Filter order'},'Calibration Stimulus Parameters',...
    [1 120],defPinput);

signalSavePath = params{1};
fSampling = str2double(params{2});
pulseOnset = str2double(params{3});
pulseLen = str2double(params{4});
traceLength = str2double(params{5});
rampType = params{6};
rampTime = str2double(params{7})/1000;
loFq = str2double(params{8});
hiFq = str2double(params{9});
filtOrder = str2double(params{10});

if traceLength<pulseOnset+pulseLen
    error('Trace length must be longer than pulseOnset+pulseLength')
end

clear params

%% Create envelope mask for signal w/r/t parameters set
time = 0:1/fSampling:traceLength-(1/fSampling);

if strcmp(rampType,'sinSquared')
    % %1/4 sin2ramp
    f = 1/rampTime;
    f = 0.25*f; %first quarter of sin(x)^2 is ramp up
    mask = [zeros(1,sum(time<pulseOnset)) ... %pre stim
        sin(2*pi*f*time(time>=pulseOnset & time<pulseOnset+rampTime)).^2 ... %ramp up
        ones(1,sum(time>=pulseOnset+rampTime & time<pulseOnset+pulseLen)) ... %stim
        zeros(1,sum(time>=pulseOnset+pulseLen))]; %post stim
    
elseif strcmp(rampType,'linear')
    %linear ramp
    mask = [zeros(1,sum(time<pulseOnset)) ... %pre stim
        linspace(0,1,length(time(time>=pulseOnset & time<pulseOnset+rampTime))) ... %ramp up
        ones(1,sum(time>=pulseOnset+rampTime & time<pulseOnset+pulseLen)) ... %stim
        zeros(1,sum(time>=pulseOnset+pulseLen))]; %post stim
    
else
    error('Ramp type not defined')
end

%% create BPN vector and envelope signal

% bandpass filter
bpn = design(fdesign.bandpass('N,F3dB1,F3dB2',...
    filtOrder,loFq,hiFq,fSampling));

%white noise vector
wn = wgn(1,fSampling*traceLength,1,'linear');

% filter white noise
y = filter(bpn,wn);

% show signal and PSD
figure('Name','Periodogram of Noise');
periodogram(y,rectwin(length(y)),length(y),fSampling);

y = mask.*y;

figure('Name','Masked signal');
plot(time,y);

%% output signal object file for ephus

dest = fullfile(signalSavePath,['calibration_BPN_' ...
    num2str(loFq) '-' num2str(hiFq) ...
    'Hz']);

if exist(dest,'dir')~=7
    mkdir(dest);
end

tonename = ['BPN_' num2str(round(loFq)) '-' num2str(round(hiFq)) 'Hz_' ...
    'gain1_' num2str(pulseOnset) 'sDelay_' num2str(pulseLen)...
    'sPulse_' rampType 'Ramp' num2str(rampTime*1000) 'ms_' num2str(traceLength)...
    'sTotal_' num2str(fSampling/1000) 'kHzFs'];

so = signalobject('type','literal','name',tonename,...
    'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
S.signal = so;

saveCompatible(fullfile(dest, [get(so, 'Name'), '.signal']), '-struct', 'S');

end %function

