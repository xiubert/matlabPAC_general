%% Speaker calibration trend plot
% Compare the current (most recent) speaker calibration against the trend
% of all prior calibration sessions.
%
% Purpose:
%   Each calibration session (see speakerCal_oscDataFile.m) saves a
%   "calibrationOutput_oscopeFile_*.mat" file containing a
%   `calibration_oscopeFile` struct with a per-stimulus mean table
%   (`Tmean`) and a session `date`. This script loads all such files in a
%   directory, plots Vrms vs. frequency for every session, and highlights
%   the most recent session so it can be eyeballed against the historical
%   mean. A large deviation of the current calibration from the trend
%   suggests a change in the rig (speaker, amp gain, mic, positioning).
%
% Usage:
%   Set `caldir`, `calFileFilter`, and (optionally) `nameFilter` below, then
%   run. Pure-tone stimuli are identified as those whose `sound_ID` parses to
%   a numeric frequency (Hz); non-numeric sound IDs (e.g. noise tokens) are
%   ignored.
%
% See also: speakerCal_oscDataFile

%% Settings
caldir = "C:\Rig\speakerCalibration";          % folder containing calibration .mat files
calFileFilter = "calibrationOutput_oscopeFile*.mat";  % glob for calibration files

% Optional further filter on the matched file names (regexp, case-sensitive).
% Use this to restrict the trend to a subset of files, e.g. a specific
% experimenter's calibration files ("_JC"), mic, or gain. Set to "" to
% include every file matched by calFileFilter.
nameFilter = "";   % e.g. "_JC" or "BK4939.*1800gain"

calFiles = dir(fullfile(caldir,calFileFilter));

if isempty(calFiles)
    error('speakerCal_trendPlot:noFiles',...
        'No files matching "%s" found in "%s".',calFileFilter,caldir);
end

% Apply the optional name filter.
if strlength(nameFilter) > 0
    keep = ~cellfun(@isempty,regexp({calFiles.name},nameFilter,'once'));
    calFiles = calFiles(keep);
    if isempty(calFiles)
        error('speakerCal_trendPlot:noFilesAfterFilter',...
            'No files matching "%s" also matched nameFilter "%s".',...
            calFileFilter,nameFilter);
    end
end

%% Iteratively load cal data
% Collect frequency vectors, Vrms vectors, and session dates from each file.
fqs_c = {};
Vrms_c = {};
dates = {};

for fNo = 1:length(calFiles)
    caltmp = load(fullfile(calFiles(fNo).folder,calFiles(fNo).name));
    cal = caltmp.calibration_oscopeFile;
    dates = cat(1,dates,string(cal.date));
    disp(dates{end})

    % Keep only stimuli whose sound_ID parses to a numeric frequency (Hz).
    fq_tmp = cellfun(@str2double,cal.Tmean.sound_ID,'uni',0);
    fq_idx = cell2mat(cellfun(@isnan,fq_tmp,'uni',0));
    fqs = cell2mat(fq_tmp(~fq_idx));
    Vrms = cal.Tmean.Vrms(~fq_idx);

    fqs_c = cat(2,fqs_c,fqs);
    Vrms_c = cat(2,Vrms_c,Vrms);
end

% Ensure the same frequencies were measured across sessions.
if ~all(cellfun(@(c) isequal(c,fqs_c{1}),fqs_c))
    warning('speakerCal_trendPlot:freqMismatch',...
        'Different frequencies measured across calibration sessions; trend comparison may be invalid.')
end

% Will error if sessions have differing numbers of frequencies.
Vrms_all = cell2mat(Vrms_c);

%% Sort sessions chronologically so the last column is the most recent
% Dates are yyyymmdd strings, which sort correctly lexicographically.
[dates,sortIdx] = sort(string(dates));
Vrms_all = Vrms_all(:,sortIdx);
fqs = fqs_c{sortIdx(end)};

%% Plot trend with current calibration highlighted
close all;
figure;
% Prior sessions in light grey, the mean trend in black, current in red.
hPrior = semilogx(fqs,Vrms_all(:,1:end-1),'Color',[0.7 0.7 0.7]);
hold on
hMean = semilogx(fqs,mean(Vrms_all,2),'LineWidth',2,'Color','k');
hCurrent = semilogx(fqs,Vrms_all(:,end),'LineWidth',2,'Color','r');

xlabel("frequency (Hz)")
ylabel("V_{rms}")
title("Speaker calibration trend")

% Build a clean legend: one entry for prior sessions (if any), plus mean
% and current.
if isempty(hPrior)
    legHandles = [hMean; hCurrent];
    legLabels = ["mean" "current ("+dates(end)+")"];
else
    legHandles = [hPrior(1); hMean; hCurrent];
    legLabels = ["prior sessions" "mean" "current ("+dates(end)+")"];
end
legend(legHandles,legLabels,"Location","bestoutside")
