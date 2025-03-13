function [] = genPureTone_train_hardcodedGain()
% genPureTone_train_hardcodedGain: generate pure-tone pulse train
% .signal files with hardcoded gain corresponding to dB value in
% calibration file
%
%   NOTE: List of pure-tone frequencies generated is determined
%         from calibration file
%
%   IMPORTANT: WHEN USING THESE .signal FILES,
%              GAIN SHOULD ALWAYS BE SET TO '1' 
%              IN EPHUS STIMULATOR
%
%   See also genPureTone_transcranial_hardcodedGain.m,
%   inspectSignalObject.m,
%   genPureTone_speakerCalibration_gain1.m,
%   genFMsignal_hardcodedGain.m

%Because these test tones are hardcoded with respective gain:
%GAIN SHOULD ALWAYS BE SET TO '1' IN EPHUS STIMULATOR

signalSavePath = 'C:\Data\Rig Software\250kHzPulses\stimTrain'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
bitDepth = 16; %bit depth of DAQ (USB-6229 is 16-bit)
dither = true;
stimOnset = 3; %seconds | time of tone onset in signal
pulseLen = 400; %ms | duration of pure-tone (just pure-tone not entire signal)
ISI = 1000; %ms
nStim = 3;
afterStim = 3000; %ms
rampType = 'linear';
rampTime = 10; %ms
dBlvls = '50, 60, 70';

defPinput = {signalSavePath,num2str(fSampling),num2str(bitDepth),num2str(dither),...
    num2str(stimOnset),num2str(pulseLen),...
    num2str(ISI),num2str(nStim),num2str(afterStim),...
    rampType,num2str(rampTime),dBlvls};

params = inputdlg({
    'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Bit-depth for stimulus signal file (bit)',...
    'Dither (Yes: 1; No: 0)',...
    'Pure-tone onset time (s)',...
    'Pure-tone duration (duration of each pulse) (ms)',...
    'ISI: time between pure-tone pulses (ms)',...
    'Number of pure-tone pulses',...
    'Time after last pure-tone pulse until end of signal (ms)',...
    'Tone ramp type ("linear" or "sinSquared")',...
    'Tone ramp time (ms)',...
    'Pure-tone stimulus amplitude (dB) (comma separated list)'},...
    'Stimulus Parameters (frequencies defined in calibration file)',...
    [1 120],defPinput);

signalSavePath = params{1};
if ~isfolder(signalSavePath)
    mkdir(signalSavePath)
end
fSampling = str2double(params{2});
bitDepth = str2double(x{3});
dither = str2double(x{4});
stimOnset = str2double(params{5});
pulseLen = str2double(params{6})/1000;
ISI = str2double(params{7});
nStim = str2double(params{8});
afterStim = str2double(params{9})/1000;
rampType = params{10};
rampTime = str2double(params{11})/1000;
dBlvls = cellfun(@str2double,strsplit(params{12},','));

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
        ones(1,(pulseLen-2*rampTime)*fSampling) ... %stim
        cos(2*pi*f*tPulse(tPulse<rampTime)).^2]; %ramp down
end

%scale tones for each frequency by ramp mask
rampMaskedTones = toneRampMask.*tones;

%vector of before train --> stimTrain --> after train for each freq
stimTrainAmpOne = [zeros(length(freq),stimOnset*fSampling) ... %before train
    repmat([rampMaskedTones ...
    zeros(length(freq),(ISI./1000)*fSampling)],1,nStim-1) rampMaskedTones ... %train
    zeros(length(freq),(afterStim)*fSampling)]; %after train

traceLength = size(stimTrainAmpOne,2)/fSampling;

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

for nAmpl = 1:length(dBlvls)
    clear gainedRampMaskedTones
    %set gain
    gainedTrains = Gset(:,nAmpl).*stimTrainAmpOne;

    for freqNo = 1:size(gainedTrains,1)
            clear y tonename so S
            y = gainedTrains(freqNo,:);
            %quantize and dither
            y = quantize_dither(y, bitDepth, dither);
            
            tonename = [num2str(round(freq(freqNo))) 'Hz_' ...
                num2str(dBlvls(nAmpl)) 'dB_pureToneTrain_' ...
                num2str(ISI) 'msISI_' ...
                num2str(nStim) 'pulses_' ...
                num2str(pulseLen*1000) 'msPulse_' ...
                num2str(stimOnset) 'sBegin_' ...           
                num2str(afterStim*1000) 'msAfterTrain_' ...
                rampType 'Ramp' ...
                num2str(rampTime*1000) 'ms_' ...
                num2str(traceLength*1000) 'msTotal_Fs' ...
                num2str(fSampling/1000) 'kHz'];
            
            so = signalobject('type','literal','name',tonename,...
                'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
            S.signal = so;
            saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');
    end %freq iter
end %dB iter

end %function