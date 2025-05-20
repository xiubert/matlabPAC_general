% based upon:
% McCollum, Mason, Abbey Manning, Philip T. R. Bender, Benjamin Z. Mendelson, and Charles T. Anderson. “Cell-Type-Specific Enhancement of Deviance Detection by Synaptic Zinc in the Mouse Auditory Cortex.” Proceedings of the National Academy of Sciences of the United States of America 121, no. 40 (October 2024): e2405615121. https://doi.org/10.1073/pnas.2405615121.

% 100 ms pulse width
% 5 ms cos ramp
% ISI/stim frequency 500 ms/2Hz
% Train length 60 sec

% 10% deviant tones
% 90% standard tones

% frequency: 8 and 16 kHz
% Intensity: 80 dB SPL


%%
signalSavePath = 'C:\DATA\Charlie\sinewavePulseFiles\250kHzPulses\oddball'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
bitDepth = 16; %bit depth of DAQ (USB-6229 is 16-bit)
dither = true;
stimOnset = 3; %seconds | time of tone onset in signal
pulseLen = 100; %ms | duration of pure-tone (just pure-tone not entire signal)
ISI = 500; %ms
% nStim = 3;
afterStim = 4000; %ms
rampType = 'sinSquared';
rampTime = 5; %ms
dB = '80';

pulseLen = pulseLen/1000;
rampTime = rampTime/1000;
afterStim = afterStim/1000;
ISI = ISI/1000;

%% make random stim times
stimVec = ones(1, 120);
randloc = randsample(120, 12);
while min(randloc)<4
    randloc = randsample(120, 12);
end
stimVec(randloc) = 2;
randloc
% 20250519
% randloc = [12; 86; 82; 57; 61; 21; 9; 63; 8; 6; 118; 59];


%% create pure-tones and train matrix

tPulse = 0:1/fSampling:pulseLen-(1/fSampling);
%create pulse for each frequency
tones = sin(2.*pi.*freq'.*tPulse);

%ramp mask for a single pulse of length pulseLen for each frequency
if strcmp(rampType,'linear')
    
    toneRampMask = [linspace(0,1,(rampTime)*fSampling) ... %ramp up
        ones(1,((pulseLen)-2*(rampTime))*fSampling)... %stim
        linspace(1,0,(rampTime)*fSampling)]; %ramp down

elseif strcmp(rampType,'sinSquared')
    f = 1/rampTime;
    f = 0.25*f; %first quarter of sin(x)^2 is ramp up
    
    toneRampMask = [sin(2*pi*f*tPulse(tPulse<rampTime)).^2 ... %ramp up
        ones(1,round((pulseLen-2*rampTime)*fSampling)) ... %stim
        cos(2*pi*f*tPulse(tPulse<rampTime)).^2]; %ramp down
end

%scale tones for each frequency by ramp mask
rampMaskedTones = toneRampMask.*tones;

%% Load calibration file w/ frequencies
[calFile,calFilPath] = uigetfile(...
    'C:\Data\Rig Software\speakerCalibration\calibrationOutput*.mat',...
    'Load inverse filter calibration file for respective frequencies');
calS = load([calFilPath calFile]);
calSname = fieldnames(calS);
calSname = calSname{1};
uMicCalV = mean(calS.(calSname).micCalV);

%% get gain values for tones and gain tones
% ODDBALL IS ALWAYS SECOND
freq = [7711 15422];
gainf = zeros(1,length(freq));

for f = 1:length(freq)
    idx = cell2mat(cellfun(@(c) strcmp(c,string(freq(f))),calS.calibration_oscopeFile.TgainSet.sound_ID,'uni',0));
    gainf(f) = calS.calibration_oscopeFile.TgainSet.(['lvl_' dB '_dB'])(idx);
end

gainedRampMaskedTones = gainf'.*rampMaskedTones;

%% make stim
addvec = zeros(1,stimOnset*fSampling);
for stimpos = 1:length(stimVec)
    addvec = cat(2,addvec,[gainedRampMaskedTones(stimVec(stimpos),:) zeros(1,((ISI)-(pulseLen))*fSampling)]);
end
% add after stim
y = cat(2,addvec,zeros(1,afterStim*fSampling));
%% look at stim
tStim = 0:1/fSampling:length(y)/fSampling-(1/fSampling);
plot(tStim,y)

%% make stim file

%quantize and dither
y = quantize_dither(y, bitDepth, dither);

tonename = ['oddball_' num2str(freq(2)) 'Hz_std_' num2str(freq(1)) 'Hz_'...
    dB 'dB_' ...
    num2str(ISI*1000) 'msISI_' ...
    num2str(pulseLen*1000) 'msPulse_' ...
    num2str(stimOnset) 'sOnset_' ...           
    num2str(afterStim*1000) 'msAfterTrain_' ...
    rampType 'Ramp' ...
    num2str(rampTime*1000) 'ms_' ...
    num2str(length(y)/fSampling) 'sTotal_Fs' ...
    num2str(fSampling/1000) 'kHz'];

so = signalobject('type','literal','name',tonename,...
    'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
S.signal = so;
saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');