function [] = genFMsignal_hardcodedGain()
% genFMsignal_hardcodedGain: generate FM modulated tone .signal files
% at various dB SPL using genFMsignal calibration file
%
%   NOTE: List of carrier frequencies generated is determined
%         from calibration file
%
%   IMPORTANT: WHEN USING THESE .signal FILES,
%              GAIN SHOULD ALWAYS BE SET TO '1' 
%              IN EPHUS STIMULATOR
%
%
%   See also genFMsignal_speakerCalibration_gain1.m, genPureTone_transcranial_hardcodedGain.m, genPureTone_speakerCalibration_gain1.m, inspectSignalObject.m


%% PARAMS

signalSavePath = 'C:\Data\Rig Software\250kHzPulses\FM_tones'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
pulseOnset = 3; %seconds | time of tone onset in signal
pulseLen = 400; %ms | tone duration (just tone, not entire signal)
traceLength = 10; %duration of .signal (s)
rampType = 'linear';
rampTime = 10; %ms
dBlvls = '50, 60, 70';

%FM params
Fmod = 5; %Hz modulation frequency
modIdx = 2; %modulation index --> dFm/Fm

defPinput = {signalSavePath,num2str(fSampling),num2str(pulseOnset),num2str(pulseLen),...
    num2str(traceLength),rampType,num2str(rampTime),dBlvls,num2str(Fmod),num2str(modIdx)};
params = inputdlg({
    'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Pulse onset time (s)',...
    'Pulse duration (ms)',...
    'Duration of entire trace (s)',...
    'Pulse envelope ramp type ("linear" or "sinSquared")',...
    'Pulse envelope ramp time (ms)',...
    'Pulse amplitude (dB SPL) (comma separated list)',...
    'Modulation frequency (Hz)',...
    'Modulation index (b = dFm/Fm)'},...
    'Stimuli Generation Parameters...',...
    [1 120],defPinput);

signalSavePath = params{1};
if ~isfolder(signalSavePath)
    mkdir(signalSavePath)
end
fSampling = str2double(params{2});
pulseOnset = str2double(params{3});
pulseLen = str2double(params{4})/1000;
traceLength = str2double(params{5});
rampType = params{6};
rampTime = str2double(params{7})/1000;
dBlvls = cellfun(@str2double,strsplit(params{8},','));

%FM
Fmod = str2double(params{9});
modIdx = str2double(params{10});
% modulation index to frequency deviation
dFm = Fmod.*modIdx; %peak frequency deviation

if traceLength<pulseOnset+pulseLen
    error('Trace length must be longer than pulseOnset+pulseLength')
end

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


%% Tones and amplitune mask 

tPulse = 0:1/fSampling:pulseLen-(1/fSampling);
pulses = sin((2*pi.*freq'.*tPulse) + (dFm./Fmod).*sin(2*pi*Fmod*tPulse));

if strcmp(rampType,'linear')
    toneRampMask = [linspace(0,1,rampTime*fSampling) ... %ramp up
        ones(1,(pulseLen-2*rampTime)*fSampling)... %stim
        linspace(1,0,rampTime*fSampling)]; %ramp down
elseif strcmp(rampType,'sinSquared')
    f = 1/rampTime;
    f = 0.25*f; %first quarter of sin(x)^2 is ramp up    
    toneRampMask = [sin(2*pi*f*tPulse(tPulse<rampTime)).^2 ... %ramp up
        ones(1,(pulseLen-2*rampTime)*fSampling) ... %stim
        cos(2*pi*f*tPulse(tPulse<rampTime)).^2]; %ramp down
end

rampMaskedPulses = toneRampMask.*pulses;


%% gain tones and save signals
Vwant = dBwant2voltage(dBlvls,uMicCalV);
Gset = Vwant2gain(Vwant,meanVout,calS.(calSname).Gcal);
if any(Gset>10000,'all')
    warning('Some freq/dB combinations require a voltage greater than max input to speaker amp (TDT ED1)')
    [a,b] = find(Gset>10000);
    Tproblem = table(freq(a)',dBlvls(b)',...
        Gset(sub2ind(size(Gset),a,b)),Gset(sub2ind(size(Gset),a,b))./1000,...
        'VariableNames',{'sound_ID','dBwant','Gset','voltage'})
    error('Can''t send more than 10V to speaker driver')
end
nFq = length(freq);

for nAmpl = 1:length(dBlvls)
    clear gainedRampMaskedPulses stimV
    gainedRampMaskedPulses = Gset(:,nAmpl).*rampMaskedPulses;
    
    stimV = [zeros(nFq,pulseOnset*fSampling) ... %before stim
        gainedRampMaskedPulses ... %stim
        zeros(nFq,round((traceLength-(pulseOnset+pulseLen))*fSampling))]; %after stim

    for freqNo = 1:size(stimV,1)        
            clear y tonename so S  
            
            y = stimV(freqNo,:);
            tonename = [num2str(round(freq(freqNo))) 'HzCarrierTone_' ...
                num2str(Fmod) 'HzModTone_' ...
                num2str(modIdx) 'modIdx_' ...
                num2str(dBlvls(nAmpl)) 'dB_' ...
                num2str(pulseOnset) 'sOnset_' ...
                num2str(pulseLen*1000) 'msPulse_' ...
                rampType 'Ramp' ...
                num2str(rampTime*1000) 'ms_' ...
                num2str(traceLength*1000) 'msTotal_' ...
                num2str(fSampling/1000) 'kHzFs'];
            
            so = signalobject('type','literal','name',tonename,...
                'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
            S.signal = so;
            saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');
    end %freq iter
end %dB iter

end %function

