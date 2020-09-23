function [] = genFMsignal_speakerCalibration_gain1()
% genFMsignal_speakerCalibration_gain1: generate FM modulated tone
% .signal files with gain 1 for calibration
%
%   NOTE: List of frequencies generated is either manually
%         entered or loaded from file
%
%
%   See also genPureTone_transcranial_hardcodedGain.m, genPureTone_speakerCalibration_gain.m, inspectSignalObject.m


%% PARAMS

freqSavePath = 'C:\Data\Rig Software\speakerCalibration\';
signalSavePath = 'C:\Data\Rig Software\250kHzPulses\'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
pulseOnset = 0; %seconds | time of tone onset in signal
pulseLen = 30; %s | duration of pure-tone (just pure-tone not entire signal)
traceLength = 30; %duration of .signal (s)
rampType = 'linear';
rampTime = 10; %ms

%FM params
Fmod = 20; %Hz modulation frequency
modIdx = 2; %modulation index --> dFm/Fm

defPinput = {freqSavePath,signalSavePath,num2str(fSampling),num2str(pulseOnset),num2str(pulseLen),...
    num2str(traceLength),rampType,num2str(rampTime),num2str(Fmod),num2str(modIdx)};
params = inputdlg({
    'Frequency list save path',...
    'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Pulse onset time (s)',...
    'Pulse duration (ms)',...
    'Duration of entire trace (s)',...
    'Onset ramp type ("linear" or "sinSquared")',...    
    'Onset ramp time (ms)',...
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
rampType = params{7};
rampTime = str2double(params{8})/1000;

%FM
Fmod = str2double(params{9});
modIdx = str2double(params{10});
%modulation index to frequency deviation
dFm = Fmod.*modIdx; %peak frequency deviation

if traceLength<pulseOnset+pulseLen
    error('Trace length must be longer than pulseOnset+pulseLength')
end

%% Frequencies
answer = questdlg('Define or Load Frequency Range?','Frequency Range',...
    'Define','Load Previous','Define');

switch answer
    case 'Define'
        definput = {'8','5000','52000'};
        x = inputdlg({'1/Octave Interval','Lower Frequency (Hz)',...
            'Upper Frequency (Hz)'},'Frequency Range',...
            [1 35],definput);
        oct = 1./str2double(x{1});
        lfq = str2double(x{2}); %lower frequency
        hfq = str2double(x{3}); %upper frequency
        
        noct = log2(hfq/lfq); %# octaves b/w 2 freq
        nfq = noct/oct;
        if rem(nfq,1)~=0
            freq = freqAtOctaveInterval(lfq,hfq,oct);
        else
            freq = [lfq lfq*(2^oct).^(1:nfq)];
        end
        
        save(fullfile(freqSavePath,['calibrationFMtones_' ...
            num2str(round(freq(1))) '-' num2str(round(freq(end))) ...
            'Hz_' num2str(round(1/oct)) 'thOctInt_' datestr(now,'yyyymmdd') '.mat']),'freq','oct')
        
    case 'Load Previous'
        %load freq
        [freqFile, freqFilePath] = uigetfile('C:\Data\Rig Software\speakerCalibration\*.mat',...
            'Choose mat file containing frequency vector...');
        load(fullfile(freqFilePath,freqFile))
        oct = log2(freq(2)/freq(1));
        noct = log2(freq(end)/freq(1));
end

dest = fullfile(signalSavePath,['calibration_FMtones_' ...
    num2str(round(freq(1))) '-' num2str(round(freq(end))) ...
    'Hz_' num2str(round(1/oct)) 'thOctInt_' ...
    num2str(Fmod) 'HzModTone_' ...
    num2str(modIdx) 'modIdx']);

if exist(dest,'dir')~=7
    mkdir(dest);
end

%% create envelope mask for signal w/r/t parameters set
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


%% Create signals w/ amplitude -1 to 1 (normal; gain done in ephus)
for fq = 1:length(freq)
    
    y = mask.*sin((2*pi*freq(fq)*time) + (dFm./Fmod).*sin(2*pi*Fmod*time)); %carrier frequency modulated by single frequency
    
    tonename = [num2str(round(freq(fq))) 'HzCarrierTone_' ...
        num2str(Fmod) 'HzModTone_' ...
        num2str(modIdx) 'modIdx_' ...
        num2str(pulseOnset*1000) 'msDelay_' ...
        num2str(pulseLen*1000) 'msPulse_' ...
        rampType 'Ramp' ...
        num2str(rampTime*1000) 'ms_' ...
        num2str(traceLength*1000) 'msTotal_' ...
        num2str(fSampling/1000) 'kHzFs'];
    
    so = signalobject('type','literal','name',tonename,...
        'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
    S.signal = so;
    saveCompatible(fullfile(dest, [get(so, 'Name'), '.signal']), '-struct', 'S');
end

end %function
