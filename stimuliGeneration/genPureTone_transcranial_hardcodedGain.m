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
%   See also genPureTone_speakerCalibration_gain.m, inspectSignalObject.m

%Test Tones for Mapping:  Creates test tones for each frequency in the
%fit file containing respective gain for each amplitude defined here.

%Because these test tones are hardcoded with respective gain:
%GAIN SHOULD ALWAYS BE SET TO '1' IN EPHUS STIMULATOR

signalSavePath = 'C:\Data\Rig Software\250kHzPulses\PC_TestTones_transcranial'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
stimOnset = 3; %seconds | time of tone onset in signal
stimLen = 0.4; %seconds | duration of pure-tone (just pure-tone not entire signal)
traceLength = 10; %duration of .signal (s)
toneLinRampTime = 0.010; %seconds
dBlvls = '50, 60, 70';


defPinput = {signalSavePath,num2str(fSampling),num2str(stimOnset),num2str(stimLen),...
    num2str(traceLength),num2str(toneLinRampTime),dBlvls};
params = inputdlg({
    'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Pure-tone onset time (s) (comma separated list)',...
    'Pure-tone duration (s)',...
    'Duration of entire trace (s)',...
    'Envelope ramp time (linear) (s)',...
    'Pure-tone stimulus amplitude (dB) (comma separated list)'},...
    'Calibration Stimulus Parameters (frequencies defined in calibration file)',...
    [1 120],defPinput);

signalSavePath = params{1};
if ~isfolder(signalSavePath)
    mkdir(signalSavePath)
end
fSampling = str2double(params{2});
if ~contains(params{3},',')
    stimOnset = str2double(params{3});
else
    stimOnset = cellfun(@str2double,strsplit(params{3},','));
end
stimLen = str2double(params{4});
traceLength = str2double(params{5});
toneLinRampTime = str2double(params{6});
dBlvls = cellfun(@str2double,strsplit(params{7},','));


%Load inverseFilter calibration file
[invCalFile,InvCalFilPath] = uigetfile(...
    'C:\Users\PAC\OneDrive - University of Pittsburgh\Personal\Thanos Lab\Speaker Calibration\calibrationData\InvFiltCal*.mat',...
    'Load inverse filter calibration file for respective frequencies');
load([InvCalFilPath invCalFile]);
meanVout = mean(calibrationInvFilt.Vout,2);
uMicCalV = mean(calibrationInvFilt.micCalV);

%freq list
freq = calibrationInvFilt.freq;

tones = sin(2.*pi.*freq'.*(0:1/fSampling:stimLen-(1/fSampling)));

toneRampMask = [linspace(0,1,toneLinRampTime*fSampling) ... %ramp up
    ones(1,(stimLen-2*toneLinRampTime)*fSampling)... %stim
    linspace(1,0,toneLinRampTime*fSampling)]; %ramp down

rampMaskedTones = toneRampMask.*tones;

%% gain tones and save signals
Vwant = dBwant2voltage(dBlvls,uMicCalV);
Gset = Vwant2gain(Vwant,meanVout,calibrationInvFilt.Gcal);
nFq = length(freq);

for nAmpl = 1:length(dBlvls)
    clear gainedRampMaskedTones
    gainedRampMaskedTones = Gset(:,nAmpl).*rampMaskedTones;
    
    for tStimNo  = 1:length(stimOnset)
        clear stimV
        stimV = [zeros(nFq,stimOnset(tStimNo)*fSampling) ... %before stim
            gainedRampMaskedTones ... %stim
            zeros(nFq,round((traceLength-(stimOnset(tStimNo)+stimLen))*fSampling))]; %after stim
    
        for freqNo = 1:size(stimV,1)
            clear y tonename so S
            y = stimV(freqNo,:);
            tonename = [num2str(round(freq(freqNo))) 'Hz_' ...
                num2str(dBlvls(nAmpl)) 'dB_TestTone_' ...
                num2str(stimLen*1000) 'msPulse_at_' ...
                num2str(stimOnset(tStimNo)) 's_' ...
                num2str(toneLinRampTime*1000) 'msRamp_' ...
                num2str(traceLength*1000) 'msTotal_Fs' ...
                num2str(fSampling/1000) 'kHz'];
            
            so = signalobject('type','literal','name',tonename,...
                'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
            S.signal = so;
            saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');
        end %for each frequency create signal
        
    end %for each pt onset time
    
end %for each amplitude

end %function