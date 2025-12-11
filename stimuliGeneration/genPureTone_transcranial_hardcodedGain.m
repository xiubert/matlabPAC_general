function [] = genPureTone_transcranial_hardcodedGain()
% genPureTone_transcranial_hardcodedGain: generate pure-tone .signal files for
% transcranial stimuli with hardcoded gain corresponding to dB value in
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

%Pure-tones for Mapping:  Creates test tones for each frequency in the
%fit file containing respective gain for each amplitude defined here.

%Because these test tones are hardcoded with respective gain:
%GAIN SHOULD ALWAYS BE SET TO '1' IN EPHUS STIMULATOR

%% PARAMS

signalSavePath = 'C:\Data\Rig Software\250kHzPulses\pureTones_transcranial'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
pulseOnset = 3; %seconds | time of tone onset in signal
pulseLen = 100; %ms | duration of pure-tone (just pure-tone not entire signal)
traceLength = 10; %duration of .signal (s)
rampType = 'linear';
rampTime = 10; %ms
dBlvls = '10, 20, 30, 40, 50, 60, 70, 80';
bitDepth = 16; %bit depth of DAQ (USB-6229 is 16-bit)
dither = true;

defPinput = {signalSavePath,num2str(fSampling),num2str(bitDepth),num2str(dither),num2str(pulseOnset),num2str(pulseLen),...
    num2str(traceLength),rampType,num2str(rampTime),dBlvls};
params = inputdlg({
    'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Bit-depth for stimulus signal file (bit)',...
    'Dither (Yes: 1; No: 0)',...
    'Pulse onset time (s) (comma separated list)',...
    'Pulse duration (ms)',...
    'Duration of entire trace (s)',...
    'Pulse envelope ramp type ("linear" or "sinSquared")',...
    'Pulse envelope ramp time (ms)',...
    'Pure-tone amplitude (dB SPL) (comma separated list)'},...
    'Pure-tone Stimulus Parameters (frequencies defined in calibration file)',...
    [1 120],defPinput);

signalSavePath = params{1};
if ~isfolder(signalSavePath)
    mkdir(signalSavePath)
end
fSampling = str2double(params{2});
bitDepth = str2double(params{3});
dither = str2double(params{4});
if ~contains(params{5},',')
    pulseOnset = str2double(params{5});
else
    pulseOnset = cellfun(@str2double,strsplit(params{5},','));
end
pulseLen = str2double(params{6})/1000;
traceLength = str2double(params{7});
rampType = params{8};
rampTime = str2double(params{9})/1000;
dBlvls = cellfun(@str2double,strsplit(params{10},','));

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
uMicCalV = mean(calS.(calSname).micCalV);

try
    meanVout = mean(calS.(calSname).Vout,2);
    freq = calS.(calSname).freq;
catch
    freq_idx = listdlg('PromptString','Select frequencies','ListString',calS.(calSname).Tmean.sound_ID);
    cellfun(@str2num,{calS.(calSname).Tmean.sound_ID{freq_idx}})
    freq = cellfun(@str2num,{calS.(calSname).Tmean.sound_ID{freq_idx}});
    meanVout = calS.(calSname).Tmean.Vrms(freq_idx);
end

%% Tones and amplitune mask 
tTone = 0:1/fSampling:pulseLen-(1/fSampling);
tones = sin(2.*pi.*freq'.*tTone);

if rem((pulseLen-2*rampTime)*fSampling,1)>0.000001
    error("stim not integer")
end

if strcmp(rampType,'linear')
    toneRampMask = [linspace(0,1,rampTime*fSampling) ... %ramp up
        ones(1,(pulseLen-2*rampTime)*fSampling)... %stim
        linspace(1,0,rampTime*fSampling)]; %ramp down
elseif strcmp(rampType,'sinSquared')
    f = 1/rampTime;
    f = 0.25*f; %first quarter of sin(x)^2 is ramp up    
    toneRampMask = [sin(2*pi*f*tTone(tTone<rampTime)).^2 ... %ramp up
        ones(1,round((pulseLen-2*rampTime)*fSampling)) ... %stim
        cos(2*pi*f*tTone(tTone<rampTime)).^2]; %ramp down
end

rampMaskedTones = toneRampMask.*tones;

%% Gain tones and save signals
Vwant = dBwant2voltage(dBlvls,uMicCalV);
Gset = Vwant2gain(Vwant,meanVout,calS.(calSname).Gcal);
%   not valid in versions prior to R2018b
%   if any(Gset>10000,'all')
if any(Gset(:) > 10000)
    warning('Some freq/dB combinations require a voltage greater than max input to speaker amp (TDT ED1)')
    [a,b] = find(Gset>10000);
    Tproblem = table(freq(a)',dBlvls(b)',...
        Gset(sub2ind(size(Gset),a,b)),Gset(sub2ind(size(Gset),a,b))./1000,...
        'VariableNames',{'sound_ID','dBwant','Gset','voltage'})
    error('Can''t send more than 10V to speaker driver')
end
nFq = length(freq);

for nAmpl = 1:length(dBlvls)
    clear gainedRampMaskedTones
    gainedRampMaskedTones = Gset(:,nAmpl).*rampMaskedTones;
    
    for tStimNo  = 1:length(pulseOnset)
        clear stimV
        stimV = [zeros(nFq,pulseOnset(tStimNo)*fSampling) ... %before stim
            gainedRampMaskedTones ... %stim
            zeros(nFq,round((traceLength-(pulseOnset(tStimNo)+pulseLen))*fSampling))]; %after stim
    
        for freqNo = 1:size(stimV,1)
            clear y tonename so S
            y = stimV(freqNo,:);
            
            %quantize and dither
            y = quantize_dither(y, bitDepth, dither);

            tonename = [num2str(round(freq(freqNo))) 'Hz_' ...
                num2str(dBlvls(nAmpl)) 'dB_pureTone_' ...
                num2str(pulseLen*1000) 'msPulse_' ...
                num2str(pulseOnset(tStimNo)) 'sOnset_' ...
                num2str(rampType) 'Ramp' ...
                num2str(rampTime*1000) 'ms_' ...
                num2str(traceLength*1000) 'msTotal_' ...
                num2str(fSampling/1000) 'kHzFs'];
            
            so = signalobject('type','literal','name',tonename,...
                'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
            S.signal = so;
            saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');
        end %for each frequency create signal
        
    end %for each pt onset time
    
end %for each amplitude

end %function