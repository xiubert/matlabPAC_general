% based upon:
% McCollum, Mason, Abbey Manning, Philip T. R. Bender, Benjamin Z. Mendelson, and Charles T. Anderson. “Cell-Type-Specific Enhancement of Deviance Detection by Synaptic Zinc in the Mouse Auditory Cortex.” Proceedings of the National Academy of Sciences of the United States of America 121, no. 40 (October 2024): e2405615121. https://doi.org/10.1073/pnas.2405615121.

% 100 ms pulse width
% 5 ms cos ramp
% ISI/stim frequency 500 ms/2Hz
% Train length 60 sec

% 10% deviant tones
% 90% standard tones

% frequency: 8 and 16 kHz
% Intensity: 80 dB SPL


%% SET PARAMETERS
signalSavePath = 'C:\DATA\Charlie\sinewavePulseFiles\250kHzPulses\oddball'; %Folder for .signal files
fSampling = 250000; %sample rate for signal | samples / s | 250kHz is max dictated by the NI-DAQ
bitDepth = 16; %bit depth of DAQ (USB-6229 is 16-bit)
dither = true;
stimOnset = 3; %seconds | time of tone onset in signal
pulseLen = 100; %ms | duration of pure-tone (just pure-tone not entire signal)
ISI = 500; %ms
afterStim = 4000; %ms
rampType = 'sinSquared';
rampTime = 5; %ms
dB = '80';
stimLength = 60; %s
pctDeviantTones = 10;

pulseLen = pulseLen/1000;
rampTime = rampTime/1000;
afterStim = afterStim/1000;
ISI = ISI/1000;
pctDeviantTones = pctDeviantTones/100;


nTones = stimLength./ISI;
%% save params into struct for export
params.fSampling = fSampling;
params.bitDepth = bitDepth;
params.dither = dither;
params.stimOnset = stimOnset;
params.pulseLen = pulseLen;
params.ISI = ISI;
params.afterStim = afterStim;
params.rampType = rampType;
params.rampTime = rampTime;
params.dB = dB;
params.stimLength = stimLength;

%% make random stim sequence
% define standard and oddball frequencies (usually an octave apart)
% should exist in calibration data
freq = [7711 15422];

% standard tone is frequency index 1
stimVec = ones(1, nTones);
randloc = randsample(nTones, nTones*pctDeviantTones);
while min(randloc)<4
    randloc = randsample(nTones, nTones*pctDeviantTones);
end

% oddball is frequency index 2
stimVec(randloc) = 2;
randloc
% 20250519
% randloc = [12; 86; 82; 57; 61; 21; 9; 63; 8; 6; 118; 59];
%% visualize
close all
t_vis = [1:nTones]/(1/ISI);
plot(t_vis,stimVec,'.')
ylim([0 3])

%% Add constraint: minimum of number of replicates below a certain time between oddball tones
% show distribution of time between oddball stimuli for different oddball
% stimulus trains
close all
min_rep = 8; %minimum number of tones
min_diff_min_rep = 5; %minimum time between oddball tones
n_variants = 12; %number of oddball train stimuli variations
min_median = 2; %seconds | minimum median time diff between oddball


% for rep = 1:3
    figure;
    randlocs = [];
    oddballdiffs = [];
    for i = 1:n_variants
        stimVec_iter = ones(1, nTones);
        randloc_iter = randsample(nTones, nTones*pctDeviantTones);
        while min(randloc_iter)<4
            randloc_iter = randsample(nTones, nTones*pctDeviantTones);
        end
        oddball_diff_iter = diff(sort(t_vis(randloc_iter)));
        randlocs = [randlocs randloc_iter];
        oddballdiffs = [oddballdiffs; oddball_diff_iter];
    end

    % ENFORCE constraints
    while ~all(groupcounts(findgroups(oddballdiffs(oddballdiffs<min_diff_min_rep)))>min_rep) || ~all(median(oddballdiffs,2)>min_median)
        randlocs = [];
        oddballdiffs = [];
        for i = 1:n_variants
            stimVec_iter = ones(1, nTones);
            randloc_iter = randsample(nTones, nTones*pctDeviantTones);
            while min(randloc_iter)<4
                randloc_iter = randsample(nTones, nTones*pctDeviantTones);
            end
            oddball_diff_iter = diff(sort(t_vis(randloc_iter)));
            randlocs = [randlocs randloc_iter];
            oddballdiffs = [oddballdiffs; oddball_diff_iter];
        end
    end

    % histogram(oddballdiffs(:),20)
    histogram(oddballdiffs(:),[0:0.5:22])
    
    ylabel('count')
    xlabel('time between oddball stimulus (s)')
    title({['number of trains: ' num2str(n_variants)],['stim len: ' num2str(stimLength) ' s | ISI: ' num2str(ISI) ' s']})
    % saveas(gcf,['~/Downloads/oddball_time_between_stim_' num2str(rep) '.png'])
    % saveas(gcf,['~/Downloads/oddball_time_between_stim_min_rep-' num2str(min_rep) '_minDiff-' num2str(min_diff_min_rep) '_' num2str(rep) '.png'])

    % create stimVec for each oddball stimulus train and plot
    % each column of randlocs contains oddball location in stimVec
    stimVec = ones(n_variants, nTones);
    figure;
    for i = 1:n_variants
        stimVec(i,randlocs(:,i)) = 2;
        plot((stimVec(i,:)==2)*i,'O')
        hold on
    end


% end

% minimum median difference between oddball stimuli:
% min_median = 2; %seconds
% all(median(oddballdiffs,2)>min_median)

%% Alternative/optional constraint: minimum percentage of stimuli over some time difference between oddball tones 
% show distribution of time between oddball stimuli for 10 different stims [over x seconds at least x percent]
close all
min_time = 5;
% min_pct = 0.333;
min_pct = 0.45;


% (sum(oddballdiffs(:)>min_time)/nTones)<min_pct

% for rep = 1:4
    figure;
    % oddball_diff = diff(sort(t_vis(randloc)));
    randlocs = [];
    oddballdiffs = [];
    for i = 1:n_variants
        stimVec_iter = ones(1, nTones);
        randloc_iter = randsample(nTones, nTones*pctDeviantTones);
        while min(randloc_iter)<4
            randloc_iter = randsample(nTones, nTones*pctDeviantTones);
        end
        oddball_diff_iter = diff(sort(t_vis(randloc_iter)));
        randlocs = [randlocs randloc_iter];
        oddballdiffs = [oddballdiffs; oddball_diff_iter];
    end

    % ENFORCE constraints
    while (sum(oddballdiffs(:)>min_time)/nTones)<min_pct || ~all(median(oddballdiffs,2)>min_median)
        randlocs = [];
        oddballdiffs = [];
        for i = 1:n_variants
            stimVec_iter = ones(1, nTones);
            randloc_iter = randsample(nTones, nTones*pctDeviantTones);
            while min(randloc_iter)<4
                randloc_iter = randsample(nTones, nTones*pctDeviantTones);
            end
            oddball_diff_iter = diff(sort(t_vis(randloc_iter)));
            randlocs = [randlocs randloc_iter];
            oddballdiffs = [oddballdiffs; oddball_diff_iter];
        end
    end

    % histogram(oddballdiffs(:),20)
    histogram(oddballdiffs(:),[0:0.5:22])
    
    ylabel('count')
    xlabel('time between oddball stimulus (s)')
    title({['number of trains: ' num2str(n_variants)],['stim len: ' num2str(stimLength) ' s | ISI: ' num2str(ISI) ' s']})
    % saveas(gcf,['~/Downloads/oddball_time_between_stim_' num2str(rep) '.png'])
    % saveas(gcf,['~/Downloads/oddball_time_between_stim_min_time-' num2str(min_time) '_minpct-' num2str(min_pct) '_' num2str(rep) '.png'])
   
    % create stimVec for each oddball stimulus train and plot
    % each column of randlocs contains oddball location in stimVec
    stimVec = ones(n_variants, nTones);
    figure;
    for i = 1:n_variants
        stimVec(i,randlocs(:,i)) = 2;
        plot((stimVec(i,:)==2)*i,'O')
        hold on
    end
% end

%% create pure-tones with onset/offset mask

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
        ones(1,round((pulseLen-2*rampTime)*fSampling)) ... %stim
        cos(2*pi*f*tPulse(tPulse<rampTime)).^2]; %ramp down
end

%scale tones for each frequency by ramp mask
rampMaskedTones = toneRampMask.*tones;

%% Load calibration file for gain needed to achieve desired dB for selected frequencies

[calFile,calFilPath] = uigetfile(...
    'C:\Data\Rig Software\speakerCalibration\calibrationOutput*.mat',...
    'Load inverse filter calibration file for respective frequencies');
calS = load([calFilPath calFile]);
calSname = fieldnames(calS);
calSname = calSname{1};
uMicCalV = mean(calS.(calSname).micCalV);

%% get gain values for tones and gain tones

gainf = zeros(1,length(freq));

for f = 1:length(freq)
    idx = cell2mat(cellfun(@(c) strcmp(c,string(freq(f))),calS.calibration_oscopeFile.TgainSet.sound_ID,'uni',0));
    gainf(f) = calS.calibration_oscopeFile.TgainSet.(['lvl_' dB '_dB'])(idx);
end

gainedRampMaskedTones = gainf'.*rampMaskedTones;

%% make stim sequence with gained tones
% stimVec contains sequence of tone indices (either oddball or standard)
% standard is frequency index 1
% oddball is frequency index 2
% this creates actual sound stimulus train by concatenating gained and
% onset-ramped pure tones based upon stimVec sequence
if size(stimVec,1)==1
    % set pre-stim
    addvec = zeros(1,stimOnset*fSampling);
    % add each tone in sequence w/ ISI
    for stimpos = 1:length(stimVec)
        addvec = cat(2,addvec,[gainedRampMaskedTones(stimVec(stimpos),:) zeros(1,((ISI)-(pulseLen))*fSampling)]);
    end
    % add time after stim
    y = cat(2,addvec,zeros(1,afterStim*fSampling));
else
    y = [];
    for variant = 1:n_variants
        % set pre-stim
        addvec = zeros(1,stimOnset*fSampling);
        % add each tone in sequence w/ ISI
        for stimpos = 1:length(stimVec)
            addvec = cat(2,addvec,[gainedRampMaskedTones(stimVec(stimpos),:) zeros(1,((ISI)-(pulseLen))*fSampling)]);
        end
        % add time after stim
        y = cat(1,y,cat(2,addvec,zeros(1,afterStim*fSampling)));
    end
end

%% look at stim

if size(stimVec,1)==1
    tStim = 0:1/fSampling:length(y)/fSampling-(1/fSampling);
    plot(tStim,y)
else
    tStim = 0:1/fSampling:size(y,2)/fSampling-(1/fSampling);
    plot(tStim,y(1,:))
end

%% make stim SignalObject file for Ephus

if size(y,1)==1
    %quantize and dither
    y = quantize_dither(y, bitDepth, dither);
    
    tonename = ['oddball_' num2str(freq(2)) 'Hz_std_' num2str(freq(1)) 'Hz_'...
        dB 'dB_' ...
        num2str(ISI*1000) 'msISI_' ...
        num2str(pulseLen*1000) 'msPulse_' ...
        num2str(stimOnset) 'sOnset_' ...           
        num2str(afterStim*1000) 'msAfterTrain_' ...
        rampType 'Ramp' ...
        num2str(rampTime*1000) 'ms_' ...
        num2str(length(y)/fSampling) 'sTotal_Fs' ...
        num2str(fSampling/1000) 'kHz'];
    
    so = signalobject('type','literal','name',tonename,...
        'length',length(y)/fSampling,'sampleRate',fSampling,'signal',y);
    S.signal = so;
    saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');
else
    for variant = 1:n_variants
        %quantize and dither
        y_sig = quantize_dither(y(variant,:), bitDepth, dither);
        
        tonename = ['oddball_' num2str(freq(2)) 'Hz_std_' num2str(freq(1)) 'Hz_'...
            dB 'dB_' ...
            num2str(ISI*1000) 'msISI_' ...
            num2str(pulseLen*1000) 'msPulse_' ...
            num2str(stimOnset) 'sOnset_' ...           
            num2str(afterStim*1000) 'msAfterTrain_' ...
            rampType 'Ramp' ...
            num2str(rampTime*1000) 'ms_' ...
            num2str(length(y_sig)/fSampling) 'sTotal_Fs' ...
            num2str(fSampling/1000) 'kHz_' num2str(variant)];
        
        so = signalobject('type','literal','name',tonename,...
            'length',length(y_sig)/fSampling,'sampleRate',fSampling,'signal',y_sig);
        S.signal = so;
        saveCompatible(fullfile(signalSavePath, [get(so, 'Name'), '.signal']), '-struct', 'S');
    end
end

%% optionally save parameters and stimVec
oddballs.params = params;
oddballs.stimVec = stimVec;
save(["./oddball_stim_" string(datetime("today")) ".mat"],"oddballs",'-mat')