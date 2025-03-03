%%
signalSavePath = 'C:\Data\Rig Software\250kHzPulses\BPN_transcranial'; %Folder for .signal files
fSampling = 250000; %sample rate for signal (via DAQ settings)
pulseOnset = 3; %seconds | delay time before tone onset in signal
pulseLen = 0.1; %s | duration of pure-tone (just pure-tone not entire signal)
traceLength = 10; %duration of .signal (s)
dBlvls = '10, 20, 30, 40, 50, 60, 70, 80';

%CHOOSE RAMP TYPE (ramp up to pure tone at beginning and ramp down at end)
rampType = 'linear';
% rampType = 'sinSquared';
rampTime = 10; %ms

%BPN params
loFq = 6000; %Low Freq Cutoff (Hz) for BPN
hiFq = 64000; %High Freq Cutoff (Hz) for BPN
filtOrder = 100; %bandpass filter order

defPinput = {num2str(fSampling),num2str(pulseOnset),num2str(pulseLen),...
    num2str(traceLength),rampType,num2str(rampTime),num2str(loFq),num2str(hiFq),num2str(filtOrder),dBlvls, signalSavePath};
params = inputdlg({
    'Sampling Rate for stimulus signal file (Hz)',...
    'BPN onset (s)',...
    'BPN duration (s)',...
    'Duration of entire stimulus (s)',...
    'Onset ramp type ("linear" or "sinSquared")',...
    'Onset ramp time (ms)',...
    'Low Frequency Cutoff (Hz)',...
    'High Frequency Cutoff (Hz)',...
    'Filter order',...
    'Pure-tone amplitude (dB SPL) (comma separated list)',...
    'Signal file save path'},'Calibration Stimulus Parameters',...
    [1 120],defPinput);

fSampling = str2double(params{1});
pulseOnset = str2double(params{2});
pulseLen = str2double(params{3});
traceLength = str2double(params{4});
rampType = params{5};
rampTime = str2double(params{6})/1000;
loFq = str2double(params{7});
hiFq = str2double(params{8});
filtOrder = str2double(params{9});
dBlvls = cellfun(@str2double,strsplit(params{10},','));
signalSavePath = params{11};

if traceLength<pulseOnset+pulseLen
    error('Trace length must be longer than pulseOnset+pulseLength')
end

clear params

%% Create envelope mask for signal w/r/t parameters set
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

%% create BPN vector and envelope signal

% bandpass filter
bpn = design(fdesign.bandpass('N,F3dB1,F3dB2',...
    filtOrder,loFq,hiFq,fSampling));

%white noise vector
wn = wgn(1,fSampling*traceLength,1,'linear');

% filter white noise
y = filter(bpn,wn);

% show signal and PSD
figure('Name','Periodogram of Noise');
periodogram(y,rectwin(length(y)),length(y),fSampling);

y = mask.*y;

figure('Name','Masked signal');
plot(time,y);

%% Load calibration file w/ frequencies
[calFile,calFilPath] = uigetfile(...
    'C:\Data\Rig Software\speakerCalibration\calibrationOutput*.mat',...
    'Load inverse filter calibration file for respective frequencies');
calS = load([calFilPath calFile]);
calSname = fieldnames(calS);
calSname = calSname{1};
uMicCalV = mean(calS.(calSname).micCalV);

%%
bpn_cal_idx = listdlg('PromptString','Select BPN calibration signal','ListString',calS.(calSname).Tmean.sound_ID);
meanVout = calS.(calSname).Tmean.Vrms(bpn_cal_idx);
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

gainedRampMaskedTone = Gset'.*y;

% stimV = [zeros(nFq,pulseOnset(tStimNo)*fSampling) ... %before stim
%     gainedRampMaskedTones ... %stim
%     zeros(nFq,round((traceLength-(pulseOnset(tStimNo)+pulseLen))*fSampling))]; %after stim

for nAmpl = 1:length(dBlvls)
    y_sig = gainedRampMaskedTone(nAmpl,:);
    BPNname = ['BPN_' num2str(round(loFq/1000)) '-' num2str(round(hiFq/1000)) 'kHz_' ...
        num2str(dBlvls(nAmpl)) 'dB_' ...
        num2str(pulseLen*1000) 'msPulse_' ...
        num2str(pulseOnset) 'sOnset_' ...
        num2str(rampType) 'Ramp' ...
        num2str(rampTime*1000) 'ms_' ...
        num2str(traceLength*1000) 'msTotal_' ...
        num2str(fSampling/1000) 'kHzFs'];

    so = signalobject('type','literal','name',BPNname,...
        'length',length(y_sig)/fSampling,'sampleRate',fSampling,'signal',y_sig);
    S.signal = so;
    saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');
end
