function [] = genFMsignal_speakerCalibration_gain1()
% genFMsignal_speakerCalibration_gain1: generate FM modulated pure-tone
% .signal files with gain 1 for calibration
%
%   NOTE: List of pure-tone frequencies generated is either manually
%         entered or loaded from file
%
%
%   See also genPureTone_transcranial_hardcodedGain.m, genPureTone_speakerCalibration_gain.m, inspectSignalObject.m


%% PARAMS
clearvars;close all;clc;
freqSavePath = 'C:\Data\Rig Software\speaker calibration\';
signalSavePath = 'C:\Data\Rig Software\250kHzPulses\FM_tones'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
pulseOnset = 0; %seconds | time of tone onset in signal
pulseLen = 30; %s | duration of pure-tone (just pure-tone not entire signal)
traceLength = 30; %duration of .signal (s)
toneLinRampTime = 10; %ms
dBlvls = '50, 60, 70';

%FM params
Fmod = 20; %Hz modulation frequency
modIdx = 2; %modulation index --> dFm/Fm

defPinput = {freqSavePath,signalSavePath,num2str(fSampling),num2str(pulseOnset),num2str(pulseLen),...
    num2str(traceLength),num2str(toneLinRampTime),dBlvls,num2str(Fmod),num2str(modIdx)};
params = inputdlg({
    'Frequency list save path',...
    'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Pulse onset time (s)',...
    'Pulse duration (ms)',...
    'Duration of entire trace (s)',...
    'Envelope ramp time (linear) (s)',...
    'Pulse amplitude (dB SPL) (comma separated list)',...
    'Modulation frequency (Hz)',...
    'Modulation index (b = dFm/Fm)'},...
    'Stimuli Generation Parameters...',...
    [1 120],defPinput);

freqSavePath = params{1};
if ~isfolder(freqSavePath)
    mkdir(freqSavePath)
end
signalSavePath = params{2};
if ~isfolder(signalSavePath)
    mkdir(signalSavePath)
end
fSampling = str2double(params{3});
pulseOnset = str2double(params{4});
pulseLen = str2double(params{5});
traceLength = str2double(params{6});
toneLinRampTime = str2double(params{7})/1000;
dBlvls = cellfun(@str2double,strsplit(params{8},','));

%FM
Fmod = str2double(params{9});
modIdx = str2double(params{10});

if traceLength<pulseOnset+pulseLen
    error('Trace length must be longer than pulseOnset+pulseLength')
end

%% Frequencies
answer = questdlg('Define or Load Frequency Range?','Frequency Range',...
    'Define','Load Previous','Define');

switch answer
    case 'Define'
        definput = {'8','5','52'};
        x = inputdlg({'1/Octave Interval','Lower Frequency (kHz)',...
            'Upper Frequency (kHz)'},'Frequency Range',...
            [1 35],definput);
        oct = 1./str2double(x{1});
        lfq = str2double(x{2}).*1000; %lower frequency
        hfq = str2double(x{3}).*1000; %upper frequency
        
        noct = log2(hfq/lfq); %# octaves b/w 2 freq
        nfq = noct/oct;
        if rem(nfq,1)~=0
            freq = freqAtOctaveInterval(lfq,hfq,oct);
        else
            freq = [lfq lfq*(2^oct).^(1:nfq)];
        end
        
        save(fullfile(freqSavePath,['CalibrationFMtones_' ...
            num2str(round(freq(1)/1000)) '-' num2str(round(freq(end)/1000)) ...
            'kHz_' num2str(round(1/oct)) 'thOctInt_' datestr(now,'yyyymmdd') '.mat']),'freq','oct')
        
    case 'Load Previous'
        %load freq
        [freqFile, freqFilePath] = uigetfile('C:\Data\Rig Software\speaker calibration\*.mat',...
            'Choose mat file containing frequency vector...');
        load(fullfile(freqFilePath,freqFile))
        oct = log2(freq(2)/freq(1));
        noct = log2(freq(end)/freq(1));
end

dest = fullfile(signalSavePath,['FMtones_speakercal_' ...
    num2str(round(freq(1))) '-' num2str(round(freq(end))) ...
    'Hz_' num2str(round(1/oct)) 'thOctInt_' ...
    num2str(Fmod) 'HzModTone_' ...
    num2str(modIdx) 'modIdx']);

if exist(dest,'dir')~=7
    mkdir(dest);
end


%% modulation index to frequency deviation
%FM params
dFm = Fmod.*modIdx; %peak frequency deviation

%% create envelope mask for signal w/r/t parameters set
t = 0:1/fSampling:traceLength-(1/fSampling);

mask = [zeros(1,sum(t<pulseOnset))... %pre tone
    linspace(0,1,length(t(t>=pulseOnset & t<pulseOnset+toneLinRampTime))) ... %ramp up
    ones(1,sum(t>=pulseOnset+toneLinRampTime & t<pulseOnset+pulseLen)) ... %tone
    zeros(1,sum(t>=pulseOnset+pulseLen))]; %time after tone


%% Create signals w/ amplitude -1 to 1 (normal; gain done in ephus)
for fq = 1:length(freq)
    
    %     y = mask.*sin(2*pi*freq(fq)*t); simple pure tone
    y = mask.*sin((2*pi*freq(fq)*t) + (dFm./Fmod).*sin(2*pi*Fmod*t)); %carrier frequency modulated by single frequency
    
    tonename = [num2str(round(freq(fq))) 'HzCarrierTone_' ...
        num2str(Fmod) 'HzModTone_' ...
        num2str(modIdx) 'modIdx_' ...
        num2str(pulseOnset*1000) 'msDelay_' ...
        num2str(pulseLen*1000) 'msPulse_' ...
        num2str(toneLinRampTime*1000) 'msLinearRamp_' ...
        num2str(traceLength*1000) 'msTotal_' ...
        num2str(fSampling/1000) 'kHzFs'];
    
    so = signalobject('type','literal','name',tonename,...
        'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
    S.signal = so;
    saveCompatible(fullfile(dest, [get(so, 'Name'), '.signal']), '-struct', 'S');
end

end %function
