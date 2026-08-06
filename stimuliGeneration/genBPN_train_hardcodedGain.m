function [] = genBPN_train_hardcodedGain()
% genBPN_train_hardcodedGain: generate band-pass noise (BPN) pulse train
% .signal files with hardcoded gain corresponding to dB value in
% calibration file
%
%   NOTE: BPN calibration signal (and hence the reference Vrms) is
%         selected from the loaded calibration file
%
%   NOTE: Unlike genPureTone_train_hardcodedGain.m (which writes one
%         constant-level file per dB value), this script writes ONE
%         .signal file whose train can carry a DIFFERENT sound level on
%         each pulse. The level sequence is set by the dB list together
%         with the randomize flag:
%
%           - dBlvls scalar
%               every pulse in the train is at that one level
%               (randomize is ignored)
%
%           - dBlvls list, randomize = false
%               list is used in the order given and must therefore have
%               exactly nStim entries (errors otherwise); pulse k gets
%               dBlvls(k)
%
%           - dBlvls list, randomize = true, length(dBlvls) == nStim
%               levels are shuffled WITHOUT replacement, so each listed
%               level appears exactly once in the train
%
%           - dBlvls list, randomize = true, length(dBlvls) ~= nStim
%               levels are drawn WITH replacement, so a level may repeat
%               or not appear at all
%
%   NOTE: The file name carries a mode tag ('const', 'ordered',
%         'randWOR', 'randWR') matching the four cases above. The level
%         part of the name is the realized pulse sequence for trains of
%         up to 4 pulses (eg. '70-50-60dB_randWOR'), and the range of the
%         requested list for longer ones (eg. '10to80dB_randWR'), which
%         keeps names from growing with pulse count.
%
%         Because the range form does not distinguish two randomized
%         runs, the FULL per-pulse sequence of every train is appended to
%         stimLog.csv in the save folder, along with the mode and the
%         calibration file used. An existing file of the same name is
%         never overwritten: a _02, _03, ... suffix is added instead.
%
%   NOTE: A single band-pass filtered noise token is drawn for the whole
%         trace, so each pulse is a different segment of that one token
%         (pulses are not frozen copies of each other).
%
%   REQUIRES: Communications Toolbox (wgn) for the white noise vector,
%             and Signal Processing Toolbox (fdesign/design, periodogram)
%             for the band-pass filter
%
%   IMPORTANT: WHEN USING THESE .signal FILES,
%              GAIN SHOULD ALWAYS BE SET TO '1'
%              IN EPHUS STIMULATOR
%
%   See also genBPN_hardcodedGain.m,
%   genPureTone_train_hardcodedGain.m,
%   inspectSignalObject.m,
%   genPureTone_speakerCalibration_gain1.m

%Because these stimuli are hardcoded with respective gain:
%GAIN SHOULD ALWAYS BE SET TO '1' IN EPHUS STIMULATOR

signalSavePath = 'C:\Data\Rig Software\250kHzPulses\stimTrain'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
bitDepth = 16; %bit depth of DAQ (USB-6229 is 16-bit)
dither = true;
stimOnset = 3; %seconds | time of first BPN pulse onset in signal
pulseLen = 400; %ms | duration of BPN pulse (just the pulse not entire signal)
ISI = 1000; %ms
nStim = 3;
afterStim = 3000; %ms
rampType = 'linear';
rampTime = 10; %ms
loFq = 6000; %Low Freq Cutoff (Hz) for BPN
hiFq = 64000; %High Freq Cutoff (Hz) for BPN
filtOrder = 100; %bandpass filter order
dBlvls = '50, 60, 70';
randomize = true; %shuffle level order across pulses (ignored if one dB level)

defPinput = {signalSavePath,num2str(fSampling),num2str(bitDepth),num2str(dither),...
    num2str(stimOnset),num2str(pulseLen),...
    num2str(ISI),num2str(nStim),num2str(afterStim),...
    rampType,num2str(rampTime),...
    num2str(loFq),num2str(hiFq),num2str(filtOrder),...
    dBlvls,num2str(randomize)};

params = inputdlg({
    'Signal file save path',...
    'Sampling Rate for stimulus signal file (Hz)',...
    'Bit-depth for stimulus signal file (bit)',...
    'Dither (Yes: 1; No: 0)',...
    'BPN onset time (s)',...
    'BPN duration (duration of each pulse) (ms)',...
    'ISI: time between BPN pulses (ms)',...
    'Number of BPN pulses',...
    'Time after last BPN pulse until end of signal (ms)',...
    'Ramp type ("linear" or "sinSquared")',...
    'Ramp time (ms)',...
    'Low Frequency Cutoff (Hz)',...
    'High Frequency Cutoff (Hz)',...
    'Filter order',...
    'BPN stimulus amplitude (dB) (comma separated list)',...
    'Randomize level order across pulses (Yes: 1; No: 0)'},...
    'Stimulus Parameters (BPN calibration signal selected from calibration file)',...
    [1 120],defPinput);

signalSavePath = params{1};
if ~isfolder(signalSavePath)
    mkdir(signalSavePath)
end
fSampling = str2double(params{2});
bitDepth = str2double(params{3});
dither = str2double(params{4});
stimOnset = str2double(params{5});
pulseLen = str2double(params{6})/1000;
ISI = str2double(params{7});
nStim = str2double(params{8});
afterStim = str2double(params{9})/1000;
rampType = params{10};
rampTime = str2double(params{11})/1000;
loFq = str2double(params{12});
hiFq = str2double(params{13});
filtOrder = str2double(params{14});
dBlvls = cellfun(@str2double,strsplit(params{15},','));
randomize = logical(str2double(params{16}));

if pulseLen < 2*rampTime
    error('Pulse duration must be at least twice the ramp time')
end
%randomize is meaningless for a single level, and an ordered list must
%supply one level per pulse (see header)
if length(dBlvls)>1 && ~randomize && length(dBlvls)~=nStim
    error(['With randomize off, the dB list must have exactly one entry '...
        'per pulse (%d levels given for %d pulses)'],length(dBlvls),nStim)
end

%% Load calibration file w/ BPN reference
cal = loadSpeakerCal();
[~,meanVout] = calSelectSounds(cal,...
    'PromptString','Select BPN calibration signal','SelectionMode','single');

%% gain per requested dB level
Vwant = dBwant2voltage(dBlvls,cal.micCalV);
Gset = Vwant2gain(Vwant,meanVout,cal.Gcal);
%   any(...,'all') not valid in versions prior to R2018b
if any(Gset(:) > 10000)
    warning('Some dB levels require a voltage greater than max input to speaker amp (TDT ED1)')
    b = find(Gset>10000);
    Tproblem = table(dBlvls(b)',Gset(b)',Gset(b)'./1000,...
        'VariableNames',{'dBwant','Gset','voltage'}) %#ok<NOPRT>
    error('Can''t send more than 10V to speaker driver')
end

%% level sequence across pulses (see header for the four cases)
if length(dBlvls)==1
    %same level on every pulse; randomize is ignored
    lvlIdx = ones(1,nStim);
    modeStr = 'const';
elseif ~randomize
    %list order is the train order (length already validated == nStim)
    lvlIdx = 1:nStim;
    modeStr = 'ordered';
elseif length(dBlvls)==nStim
    %one of each listed level, shuffled: without replacement
    lvlIdx = randperm(nStim);
    modeStr = 'randWOR';
else
    %list length doesn't match pulse count: draw with replacement
    lvlIdx = randi(length(dBlvls),1,nStim);
    modeStr = 'randWR';
end
dBseq = dBlvls(lvlIdx); %dB of each pulse, in train order
Gseq = Gset(lvlIdx); %gain of each pulse, in train order

%% create per-pulse ramp mask
tPulse = 0:1/fSampling:pulseLen-(1/fSampling);
nPulseSamp = length(tPulse);

if strcmp(rampType,'linear')
    nRampSamp = round(rampTime*fSampling);

    pulseRampMask = [linspace(0,1,nRampSamp) ... %ramp up
        ones(1,nPulseSamp-2*nRampSamp) ... %stim
        linspace(1,0,nRampSamp)]; %ramp down

elseif strcmp(rampType,'sinSquared')
    f = 1/rampTime;
    f = 0.25*f; %first quarter of sin(x)^2 is ramp up
    tRamp = tPulse(tPulse<rampTime);

    pulseRampMask = [sin(2*pi*f*tRamp).^2 ... %ramp up
        ones(1,nPulseSamp-2*length(tRamp)) ... %stim
        cos(2*pi*f*tRamp).^2]; %ramp down
else
    error('Ramp type not defined')
end

%% build gained train envelope
%unlike the pure-tone train, gain is applied PER PULSE while building the
%envelope (rather than scaling the whole amplitude-one train at once), so
%that each pulse can sit at its own sound level
nGapSamp = round((ISI./1000)*fSampling);

gainedEnvelope = zeros(1,round(stimOnset*fSampling)); %before train
for pulseNo = 1:nStim
    gainedEnvelope = [gainedEnvelope Gseq(pulseNo).*pulseRampMask]; %#ok<AGROW>
    if pulseNo<nStim
        gainedEnvelope = [gainedEnvelope zeros(1,nGapSamp)]; %#ok<AGROW> %ISI
    end
end
gainedEnvelope = [gainedEnvelope zeros(1,round(afterStim*fSampling))]; %after train

traceLength = length(gainedEnvelope)/fSampling;

%% create BPN vector and envelope signal
% bandpass filter
bpn = design(fdesign.bandpass('N,F3dB1,F3dB2',...
    filtOrder,loFq,hiFq,fSampling));

%white noise vector spanning the whole trace
%NOTE: wgn requires the Communications Toolbox
wn = wgn(1,length(gainedEnvelope),1,'linear');

% filter white noise
y = filter(bpn,wn);

% show signal and PSD
figure('Name','Periodogram of Noise');
periodogram(y,rectwin(length(y)),length(y),fSampling);

%apply per-pulse gained envelope
y = gainedEnvelope.*y;

figure('Name','Masked signal');
plot(0:1/fSampling:traceLength-(1/fSampling),y);
xlabel('time (s)'); ylabel('signal (V)');

%% quantize, dither, and save signal
y = quantize_dither(y, bitDepth, dither);

%level tag: keep the realized sequence in the name while it stays readable,
%otherwise fall back to the range of the requested list. Either way the full
%per-pulse sequence is written to the log file below.
maxPulsesInName = 4; %above this, the sequence is summarized as a range
if length(unique(dBseq))==1
    lvlStr = num2str(dBseq(1));
elseif nStim<=maxPulsesInName
    lvlStr = strjoin(arrayfun(@(x) num2str(x),dBseq,'UniformOutput',false),'-');
else
    lvlStr = [num2str(min(dBlvls)) 'to' num2str(max(dBlvls))];
end

BPNname = ['BPN_' num2str(round(loFq/1000)) '-' num2str(round(hiFq/1000)) 'kHz_' ...
    lvlStr 'dB_' modeStr '_BPNtrain_' ...
    num2str(ISI) 'msISI_' ...
    num2str(nStim) 'pulses_' ...
    num2str(pulseLen*1000) 'msPulse_' ...
    num2str(stimOnset) 'sBegin_' ...
    num2str(afterStim*1000) 'msAfterTrain_' ...
    rampType 'Ramp' ...
    num2str(rampTime*1000) 'ms_' ...
    num2str(traceLength*1000) 'msTotal_Fs' ...
    num2str(fSampling/1000) 'kHz'];

%Two randomized runs share a name whenever the sequence is summarized as a
%range, so never clobber an existing stimulus: suffix instead.
if isfile(fullfile(signalSavePath,[BPNname '.signal']))
    nDup = 2;
    while isfile(fullfile(signalSavePath,sprintf('%s_%02d.signal',BPNname,nDup)))
        nDup = nDup+1;
    end
    BPNname = sprintf('%s_%02d',BPNname,nDup);
    warning('a signal of that name already exists; saving as %s',BPNname)
end

so = signalobject('type','literal','name',BPNname,...
    'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
S.signal = so;
saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');

%% log the realized sequence
%the name only carries it for short trains, so record every train here
logFile = fullfile(signalSavePath,'stimLog.csv');
writeHeader = ~isfile(logFile);
fid = fopen(logFile,'a');
if fid<0
    warning('could not open %s for logging; sequence not recorded',logFile)
else
    if writeHeader
        fprintf(fid,'date,signalName,mode,nPulses,dBsequence,calFile\n');
    end
    fprintf(fid,'%s,%s,%s,%d,"%s",%s\n', datestr(now,'yyyymmdd_HHMMSS'),...
        BPNname, modeStr, nStim,...
        strjoin(arrayfun(@(x) num2str(x),dBseq,'UniformOutput',false),' '), cal.file);
    fclose(fid);
end

end %function
