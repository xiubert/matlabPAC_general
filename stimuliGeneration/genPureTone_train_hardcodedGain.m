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
%   See also genPureTone_transcranial_hardcodedGain.m, genPureTone_speakerCalibration_gain.m, inspectSignalObject.m

%Because these test tones are hardcoded with respective gain:
%GAIN SHOULD ALWAYS BE SET TO '1' IN EPHUS STIMULATOR

signalSavePath = 'C:\Data\Rig Software\250kHzPulses\stimTrain'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
stimOnset = 3; %seconds | time of tone onset in signal
pulseLen = 400; %ms | duration of pure-tone (just pure-tone not entire signal)
ISI = 1000; %ms
nStim = 3;
afterStim = 3000; %ms
toneLinRampTime = 10; %ms
dBlvls = '50, 60, 70';

defPinput = {signalSavePath,num2str(fSampling),...
    num2str(stimOnset),num2str(pulseLen),...
    num2str(ISI),num2str(nStim),num2str(afterStim),...
    num2str(toneLinRampTime),dBlvls};

params = inputdlg({
    'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Pure-tone onset time (s)',...
    'Pure-tone duration (duration of each pulse) (ms)',...
    'ISI: time between pure-tone pulses (ms)',...
    'Number of pure-tone pulses',...
    'Time after last pure-tone pulse until end of signal (ms)',...
    'Envelope ramp time (linear) (ms)',...
    'Pure-tone stimulus amplitude (dB) (comma separated list)'},...
    'Stimulus Parameters (frequencies defined in calibration file)',...
    [1 120],defPinput);

signalSavePath = params{1};
if ~isfolder(signalSavePath)
    mkdir(signalSavePath)
end
fSampling = str2double(params{2});
stimOnset = str2double(params{3});
pulseLen = str2double(params{4});
ISI = str2double(params{5});
nStim = str2double(params{6});
afterStim = str2double(params{7});
toneLinRampTime = str2double(params{8});
dBlvls = cellfun(@str2double,strsplit(params{9},','));

%% Load inverseFilter calibration file for frequencies and associated gain
[invCalFile,InvCalFilPath] = uigetfile(...
    'C:\Users\PAC\OneDrive - University of Pittsburgh\Personal\Thanos Lab\Speaker Calibration\calibrationData\InvFiltCal*.mat',...
    'Load inverse filter calibration file for respective frequencies');
load([InvCalFilPath invCalFile],'calibrationInvFilt');
meanVout = mean(calibrationInvFilt.Vout,2);
uMicCalV = mean(calibrationInvFilt.micCalV);

%freq list
freq = calibrationInvFilt.freq;

%% create pure-tones and train matrix

%create pulse for each frequency
tones = sin(2.*pi.*freq'.*(0:1/fSampling:(pulseLen/1000)-(1/fSampling)));

%ramp mask for a single pulse of length pulseLen for each frequency
toneRampMask = [linspace(0,1,(toneLinRampTime/1000)*fSampling) ... %ramp up
    ones(1,((pulseLen/1000)-2*(toneLinRampTime/1000))*fSampling)... %stim
    linspace(1,0,(toneLinRampTime/1000)*fSampling)]; %ramp down

%scale tones for each frequency by ramp mask
rampMaskedTones = toneRampMask.*tones;

%vector of before train --> stimTrain --> after train for each freq
stimTrainAmpOne = [zeros(length(freq),stimOnset*fSampling) ... %before train
    repmat([rampMaskedTones ...
    zeros(length(freq),(ISI./1000)*fSampling)],1,nStim-1) rampMaskedTones ... %train
    zeros(length(freq),(afterStim./1000)*fSampling)]; %after train

traceLength = size(stimTrainAmpOne,2)/fSampling;

%% gain tones and save signals
Vwant = dBwant2voltage(dBlvls,uMicCalV);
Gset = Vwant2gain(Vwant,meanVout,calibrationInvFilt.Gcal);

for nAmpl = 1:length(dBlvls)
    clear gainedRampMaskedTones
    %set gain
    gainedTrains = Gset(:,nAmpl).*stimTrainAmpOne;

    for freqNo = 1:size(gainedTrains,1)
            clear y tonename so S
            y = gainedTrains(freqNo,:);
            tonename = [num2str(round(freq(freqNo))) 'Hz_' ...
                num2str(dBlvls(nAmpl)) 'dB_pureToneTrain_' ...
                num2str(ISI) 'msISI_' ...
                num2str(nStim) 'pulses_' ...
                num2str(pulseLen) 'msPulse_' ...
                num2str(stimOnset) 'sBegin_' ...           
                num2str(afterStim) 'msAfterTrain_' ...
                num2str(toneLinRampTime) 'msRamp_' ...
                num2str(traceLength*1000) 'msTotal_Fs' ...
                num2str(fSampling/1000) 'kHz'];
            
            so = signalobject('type','literal','name',tonename,...
                'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
            S.signal = so;
            saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');
    end %freq iter
end %dB iter

end %function