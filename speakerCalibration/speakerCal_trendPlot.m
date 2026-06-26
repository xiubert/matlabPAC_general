%% load cal files
caldir = "C:\Rig\speakerCalibration";
calFileFilter = "calibrationOutput_oscopeFile*_JC.mat";
calFiles = dir(fullfile(caldir,calFileFilter));

%% iteratively load cal data (single)
% 
% % example file first
% f1 = fullfile(calFiles(1).folder,calFiles(1).name);
% x1 = load(f1);
% 
% x1.calibration_oscopeFile.Tmean.sound_ID
% 
% % get only pure tone frequencies
% fq_tmp = cellfun(@str2double,x1.calibration_oscopeFile.Tmean.sound_ID,'uni',0);
% fq_idx = cell2mat(cellfun(@isnan,fq_tmp,'uni',0));
% fqs = cell2mat(fq_tmp(~fq_idx));
% Vrms = x1.calibration_oscopeFile.Tmean.Vrms(~fq_idx);
% 
% % plot example
% plot(fqs,Vrms)

%% iteratively load cal data
fqs_c = {};
Vrms_c = {};
dates = {};

for fNo = 1:length(calFiles)
    caltmp = load(fullfile(calFiles(fNo).folder,calFiles(fNo).name));
    dates = cat(1,dates,caltmp.calibration_oscopeFile.date);
    disp(dates{end})

    fq_tmp = cellfun(@str2double,caltmp.calibration_oscopeFile.Tmean.sound_ID,'uni',0);
    fq_idx = cell2mat(cellfun(@isnan,fq_tmp,'uni',0));
    fqs = cell2mat(fq_tmp(~fq_idx));
    Vrms = caltmp.calibration_oscopeFile.Tmean.Vrms(~fq_idx);
    
    fqs_c = cat(2,fqs_c,fqs);
    Vrms_c = cat(2,Vrms_c,Vrms);
    
end

% ensure same fqs
if ~all(cell2mat(cellfun(@(c) all(c==fqs_c{1}),fqs_c,'uni',0)))
    warning('check to ensure the same frequencies are measured across calibration sessions')
end

% will error if not all same length
Vrms_all = cell2mat(Vrms_c);

%% plot
close all;
% plot(fqs_c{end},Vrms_all)
semilogx(fqs_c{end},Vrms_all)
xlabel("frequency (Hz)")
ylabel("V_{rms}")
hold on
semilogx(fqs_c{end},mean(Vrms_all,2),'LineWidth',3,'Color','k')
legend(dates,"Location","bestoutside")

