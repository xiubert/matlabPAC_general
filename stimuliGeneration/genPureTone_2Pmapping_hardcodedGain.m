function [] = genPureTone_2Pmapping_hardcodedGain()
% genPureTone_2Pmapping_hardcodedGain: generate pure-tone .signal files for
% 2P TRF mapping stimuli with hardcoded gain corresponding to dB value in
% calibration file
%
%   NOTE: List of pure-tone frequencies generated is determined
%         from calibration file
%
%   IMPORTANT: WHEN USING THESE .signal FILES,
%              GAIN SHOULD ALWAYS BE SET TO '1' 
%              IN EPHUS STIMULATOR
%
%   See also genPureTone_speakerCalibration_gain1.m, inspectSignalObject.m,
%   genPureTone_train_hardcodedGain.m, genFMsignal_hardcodedGain.m

%Pure-tones for 2P mapping:  Creates test tones for each frequency in the
%fit file containing respective gain for each amplitude defined here.

%Because these test tones are hardcoded with respective gain:
%GAIN SHOULD ALWAYS BE SET TO '1' IN EPHUS STIMULATOR

%% PARAMS
%Because these test tones are hardcoded with respective gain:
%GAIN SHOULD ALWAYS BE SET TO '1' IN EPHUS STIMULATOR

%Folder for .signal files
signalSavePath = 'C:\Data\Rig Software\250kHzPulses\PC_TestTones_MappingBF_quick';
sampleRate = 250000; %samples / s | Max dictated by the NI-DAQ
traceLen = 1.5; %seconds
pulseLen = 400; %ms
pulseOnset = '0.6, 1'; %seconds | time at which stim happens
%Tones are ramped up and down by rampType over time defined by rampTime
rampType = 'linear';
rampTime = 10; %ms

gSetDBstart = 30;
gSetDBstep = 20;
gSetDBend = 70;
% dBwant = [30:20:70]; %quick (30:20:70) %denseLvl (30:10:70)
% dBwant = [30:20:70]; %quick (30:20:70) %denseLvl (30:10:70)

definput = {signalSavePath,num2str(sampleRate),num2str(traceLen),...
    num2str(pulseLen),num2str(pulseOnset),rampType,num2str(rampTime),...
    num2str(gSetDBstart),num2str(gSetDBstep),num2str(gSetDBend)};

x = inputdlg({'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Duration of entire trace (s)',...
    'Pulse duration (ms)',...
    'Pulse onset time (s) (comma separated list)',...
    'Pulse envelope ramp type ("linear" or "sinSquared")',...
    'Pulse envelope ramp time (ms)',...
    'pulse dB range: start dB', ...
    'pulse dB range: step dB', ...
    'pulse dB range: end dB'},...
    'Pure-tone Stimulus Parameters (frequencies defined in calibration file)',...
              [1 80],definput);
          
signalSavePath = x{1};   
if ~isfolder(signalSavePath)
    mkdir(signalSavePath)
end
sampleRate = str2double(x{2});
traceLen = str2double(x{3});
pulseLen = str2double(x{4})/1000;          
if ~contains(x{5},',')
    pulseOnset = str2double(x{5});
else
    pulseOnset = cellfun(@str2double,strsplit(x{5},','));
end
rampType = x{6};
rampTime = str2double(x{7})/1000;
gSetDBstart = str2double(x{8});
gSetDBstep = str2double(x{9});
gSetDBend = str2double(x{10});
dBwant = gSetDBstart:gSetDBstep:gSetDBend;
clear gSet*

%% Load calibration file w/ frequencies
[calFile,calFilPath] = uigetfile(...
    'C:\Data\Rig Software\speakerCalibration\calibrationOutput*.mat',...
    'Load inverse filter calibration file for respective frequencies');
calS = load([calFilPath calFile]);
calSname = fieldnames(calS);
calSname = calSname{1};
meanVout = mean(calS.(calSname).Vout,2);
uMicCalV = mean(calS.(calSname).micCalV);
freq = calS.(calSname).freq;

%% create enveloped tones

tPulse = 0:1/sampleRate:pulseLen-(1/sampleRate);
tones = sin(2.*pi.*freq'.*tPulse);

if strcmp(rampType,'linear')
    toneRampMask = [linspace(0,1,rampTime*sampleRate) ... %ramp up
        ones(1,(pulseLen-2*rampTime)*sampleRate)... %stim
        linspace(1,0,rampTime*sampleRate)]; %ramp down
elseif strcmp(rampType,'sinSquared')
    f = 1/rampTime;
    f = 0.25*f; %first quarter of sin(x)^2 is ramp up
    toneRampMask = [sin(2*pi*f*tPulse(tPulse<rampTime)).^2 ... %ramp up
        ones(1,(pulseLen-2*rampTime)*sampleRate) ... %stim
        cos(2*pi*f*tPulse(tPulse<rampTime)).^2]; %ramp down
end

rampMaskedTones = toneRampMask.*tones;


%% confirm correct frequencies
% t = 0:1/sampleRate:pulseLen-(1/sampleRate);
% tone = tones(7,:);
% len=length(tone);
% fs=250000; % assuming you know the sampling frequency of your signal
% n=0:len-1;
% N=n*fs/(len-1); % convert x-axis in actual frequency
% y=fft(tone);
% figure;plot(N,abs(y));

%% gain tones and save signals
Vwant = dBwant2voltage(dBwant,uMicCalV);
Gset = Vwant2gain(Vwant,meanVout,calS.(calSname).Gcal);
if any(Gset>10000,'all')
    warning('Some freq/dB combinations require a voltage greater than max input to speaker amp (TDT ED1)')
    [a,b] = find(Gset>10000);
    Tproblem = table(freq(a)',dBwant(b)',...
        Gset(sub2ind(size(Gset),a,b)),Gset(sub2ind(size(Gset),a,b))./1000,...
        'VariableNames',{'sound_ID','dBwant','Gset','voltage'})
    error('Can''t send more than 10V to speaker driver')
end
nFq = length(freq);

for nAmpl = 1:length(dBwant)
    clear gainedRampMaskedTones
    gainedRampMaskedTones = Gset(:,nAmpl).*rampMaskedTones;
    
    for tStimNo  = 1:length(pulseOnset)
        clear stimV
        stimV = [zeros(nFq,pulseOnset(tStimNo)*sampleRate) ... %before stim
            gainedRampMaskedTones ... %stim
            zeros(nFq,round((traceLen-(pulseOnset(tStimNo)+pulseLen))*sampleRate))]; %after stim
    
        for freqNo = 1:size(stimV,1)
            clear y tonename so S
            y = stimV(freqNo,:);
            tonename = [num2str(round(freq(freqNo))) 'Hz_' ...
                num2str(dBwant(nAmpl)) 'dB_TestTone_' ...
                num2str(pulseLen*1000) 'msPulse_at_' ...
                num2str(pulseOnset(tStimNo)) 's_' ...
                num2str(rampTime*1000) 'msRamp_' ...
                num2str(traceLen*1000) 'msTotal_Fs' ...
                num2str(sampleRate/1000) 'kHz'];
            
            so = signalobject('type','literal','name',tonename,...
                'length',length(y)/sampleRate,'sampleRate',sampleRate,'signal',y);
            S.signal = so;
            saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');
        end %for each frequency create signal
        
    end %for each pt onset time
    
end %for each amplitude
        
    