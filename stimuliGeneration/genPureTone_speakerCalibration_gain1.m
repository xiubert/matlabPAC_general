function [] = genPureTone_speakerCalibration_gain1()
% genPureTone_speakerCalibration_gain1: create simple test tones 
%                                       at gain = 1 at defined frequencies
%                                       for speaker calibration
%
%   NOTE: List of pure-tone frequencies generated is either manually
%         entered or loaded from file
%
%   IMPORTANT: WHEN USING THESE .signal FILES,
%              GAIN SHOULD BE SET TO SOME VALUE THAT RESULTS IN READABLE
%              OUTPUT FROM OSCILLOSCOPE
%
%   See also genPureTone_transcranial_hardcodedGain.m, inspectSignalObject.m

%may want to run stim_in_DRC_to_signal_cutout_loop.m first or
%MakeContrastDRClvlMat.m to get frequency vector

freqSavePath = 'C:\Users\PAC\OneDrive - University of Pittsburgh\Personal\Thanos Lab\speaker calibration\';
signalSavePath = 'C:\Data\Rig Software\250kHzPulses\';
fSampling = 250000; %sample rate for signal (via DAQ settings)
preDelay = 0; %seconds | delay time before tone onset in signal
tON = 30; %s | duration of pure-tone (just pure-tone not entire signal)
traceLength = 30; %duration of .signal (s)

%CHOOSE RAMP TYPE (ramp up to pure tone at beginning and ramp down at end)
rampType = 'linear';
% rampType = 'sinsquared';

defPinput = {freqSavePath,signalSavePath,num2str(fSampling),num2str(preDelay),num2str(tON),...
    num2str(traceLength),rampType};
params = inputdlg({'Frequency Vector Save Path',...
    'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Delay time before pure-tone (s)',...
    'Duration of pure-tone (s)',...
    'Duration of entire stimulus (s)',...
    'Envelope ramp type ("linear" or "sinsquared")'},'Calibration Stimulus Parameters',...
    [1 120],defPinput);

freqSavePath = params{1};
signalSavePath = params{2};
fSampling = str2double(params{3});
preDelay = str2double(params{4});
tON = str2double(params{5});
traceLength = str2double(params{6});
rampType = params{7};

clear params
%% frequencies
% load('C:\Users\2Photon\Documents\Patrick\OneDrive - University of Pittsburgh\Personal\Thanos Lab\stimuli\DRC mat files\5kHz-25kHz_DRC_freq.mat')

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
%             freq = [lfq lfq*(2^oct).^(1:nfq) hfq];
            freq = freqAtOctaveInterval(lfq,hfq,oct);
        else
            freq = [lfq lfq*(2^oct).^(1:nfq)];
        end
        
        save(fullfile(freqSavePath,['CalibrationTestTones_' ...
            num2str(round(freq(1)/1000)) '-' num2str(round(freq(end)/1000)) ...
            'kHz_' num2str(round(1/oct)) 'thOctInt_' datestr(now,'yyyymmdd') '.mat']),'freq','oct')
        
    case 'Load Previous'
        %load freq
        [freqFile, freqFilePath] = uigetfile('C:\Users\2Photon\Documents\Patrick\OneDrive - University of Pittsburgh\Personal\Thanos Lab\speakercal\*.mat',...
            'Choose mat file containing frequency vector...');
        load(fullfile(freqFilePath,freqFile))
        oct = log2(freq(2)/freq(1));
        noct = log2(freq(end)/freq(1));
end

dest = fullfile(signalSavePath,['PC_TestTones_speakercal_' ...
    num2str(round(freq(1)/1000)) '-' num2str(round(freq(end)/1000)) ...
    'kHz_' num2str(round(1/oct)) 'thOctInt']);

if exist(dest,'dir')~=7
    mkdir(dest);
end

%% create envelope mask for signal w/r/t parameters set
tSampling = 1/fSampling;

poststim = traceLength-preDelay-tON;
time = 0:tSampling:traceLength-tSampling;

if strcmp(rampType,'sinsquared')
    % %1/4 sin2ramp
    rmpt = 0; %ms ramp time
    rmpt = rmpt/1000;
    f = 1/rmpt;
    f = 0.25*f; %first quarter of sin(x)^2 is ramp up
    mask = [zeros(1,sum(time<preDelay)) sin(2*pi*f*time(time>=preDelay & time<preDelay+rmpt)).^2 ...
        ones(1,sum(time>=preDelay+rmpt & time<preDelay+tON)) zeros(1,sum(time>=preDelay+tON))];
    
elseif strcmp(rampType,'linear')
    %linear ramp (same as fiveKAMsounds)
    rmpt = 10; %ms ramp time
    rmpt = rmpt/1000;
    linenv = linspace(0,1,length(time(time>=preDelay & time<preDelay+rmpt)));
    mask = [zeros(1,sum(time<preDelay)) linenv ...
        ones(1,sum(time>=preDelay+rmpt & time<preDelay+tON)) zeros(1,sum(time>=preDelay+tON))];
    
else
    error('Ramp type not defined')
end

%% -1 to 1 (normal; gain done in ephus)
for fq = 1:length(freq)
    y = mask.*sin(2*pi*freq(fq)*time);
%     figure;plot(time(time>preDelay-rmpt & time<preDelay+(rmpt*4)),y(time>preDelay-rmpt & time<preDelay+(rmpt*4)));
%     figure;plot(time(time>preDelay-0.01 & time<preDelay+tON+0.01),y(time>preDelay-0.01 & time<preDelay+tON+0.01));
%     figure;plot(time,y);
    tonename = [num2str(round(freq(fq))) 'Hz_TestTone_' num2str(preDelay*1000) 'msDelay_' num2str(tON*1000)...
        'msPulse_' num2str(rmpt*1000) 'ms_' rampType 'Ramp_' num2str(traceLength*1000)...
        'msTotal_Fs' num2str(fSampling/1000) 'kHz'];
    so = signalobject('type','literal','name',tonename,...
        'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
    S.signal = so;
    saveCompatible(fullfile(dest, [get(so, 'Name'), '.signal']), '-struct', 'S');
end

end %function