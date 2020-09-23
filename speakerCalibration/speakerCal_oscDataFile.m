%% Speaker calibration using oscilloscope data files
%obtains dB based upon average of voltage reference readings
clearvars;close all
% oscDataDir = 'C:\Data\Rig Software\speakerCalibration\20200921';

%default values
oscDataDir = 'C:\Data\Rig Software\speakerCalibration\';
micType = 'BK4183';
micCaldB = 94; %decibel level of square mic calibration speaker (B&K TYPE 4231 SOUND CALIBRATOR)
VtoPa = 3.16;
Gcal = 1500;

definput = {oscDataDir,micType,num2str(micCaldB),num2str(VtoPa),num2str(Gcal)};

x = inputdlg({'o-scope data folder','mic Type',...
    'mic calibration dB',...
    'amp V/Pa',...
    'gain used for calibration'},'Speaker Calibration Settings',...
              [1 80; 1 80;  1 80; 1 80; 1 80],definput);

oscDataDir = x{1};          
micType = x{2};
dBref = str2double(x{3});
VtoPa = str2double(x{4});          
Gcal = str2double(x{5});


%% create sound ID legend

dataDir = dir(oscDataDir);
dataDir = dataDir(~cellfun(@isempty,regexp({dataDir.name},'[A-Z]{3}\d{4}','match','once')));
refSel = listdlg('PromptString','Select reference folders','ListString',{dataDir.name});
refDir = dataDir(refSel);
% dBref = inputdlg('Enter reference dB value (94 dB default)');
if isempty(dBref) || strcmp(dBref,'')
    dBref = 94;
else
    dBref = dBref{1};
end

stimDir = dataDir(~ismember(1:length(dataDir),refSel));

loadYN = questdlg('Create folder legend or load existing?','Folder Legend',...
    'Create new folder legend','Load existing','Create new folder legend');
if strcmp(loadYN,'Create new folder legend')
    [lFile,lFolder] = uiputfile(fullfile(oscDataDir,'*.xlsx'),'Enter file to save folder legend...');
    idT = table(cellstr({stimDir.name})',cell(size(stimDir)),'VariableNames',{'Folder_ID','Sound_ID'});
    writetable(idT,fullfile(lFolder,lFile));
elseif strcmp(loadYN,'Load existing')
    [lFile,lFolder] = uigetfile(fullfile(oscDataDir,'*.xlsx'),'Load folder legend'); 
end

%% LOAD COMPLETED LEGEND

idTc = readtable(fullfile(lFolder,lFile));
stimLabels = string(idTc.Sound_ID);

%% scrape Vrms from all the osc output folders
[tRaw,Vraw,tGapFix,VgapFix,VgapFixDetrend] = deal(cell(length(dataDir),1));
Vrms = zeros(length(dataDir),1);
for nDir = 1:length(dataDir)
    [tRaw{nDir},Vraw{nDir},oscSettings(nDir)] = importOscCSVfile(fullfile(dataDir(nDir).folder,dataDir(nDir).name,...
    [regexprep(dataDir(nDir).name,'[A-Z]{3}','F') 'CH1.CSV'])); 
    
    %remove gap in signal from oscilloscpe sampling window
    tmp = find(diff(Vraw{nDir})==0);
    tmp = tmp(3:end); %shortened b/c 3 diffs
    tmp = Vraw{nDir}(tmp(diff(diff(find(diff(Vraw{nDir})==0)))==0));
    %sum(Vraw{nDir}==mode(tmp)) %can check for consistent gap length
    
    %if there's a sampling window gap to remove, do so
    if length(Vraw{nDir})-length(Vraw{nDir}(Vraw{nDir}~=mode(tmp)))>=...
            0.9*(oscSettings(nDir).timeInterval.*oscSettings(nDir).fS)
        
        VgapFix{nDir} = Vraw{nDir}(Vraw{nDir}~=mode(tmp));
        tGapFix{nDir} = tRaw{nDir}(Vraw{nDir}~=mode(tmp));
    else
        VgapFix{nDir} = Vraw{nDir};
        tGapFix{nDir} = tRaw{nDir};
    end
    
    %MUST DETREND TO ALIGN SIGNAL AT 0 FOR ACCURATE Vrms calculation
    %likely that signal not aligned at 0 on oscilloscope
    VgapFixDetrend{nDir} = detrend(VgapFix{nDir});
    
%     figure; 
%     subplot(1,3,1)
%     plot(tRaw{nDir},Vraw{nDir})
%     subplot(1,3,2)
%     plot(tGapFix{nDir},VgapFix{nDir})
%     subplot(1,3,3)
%     plot(tGapFix{nDir},VgapFixDetrend{nDir})
    Vrms(nDir,1) = sqrt(mean((VgapFixDetrend{nDir}).^2)); 
    %Vrms2(nDir,1) = rms(VgapFixDetrend{nDir}); %same as above
    clear tmp
end
%% main output table

dBcalc = Volt2dB(Vrms,nanmean(Vrms(refSel)),dBref);
sound_ID = cell(length(dataDir),1);
sound_ID(refSel) = {['reference: ' num2str(dBref) ' dB SPL']};
sound_ID(~ismember(1:length(dataDir),refSel)) = cellstr(stimLabels);
T = table(sound_ID,Vrms,dBcalc);

%% mean output table

[Sound_ID,~,G] = unique(T.sound_ID,'stable');
Tmean = table(Sound_ID,...
    splitapply(@mean,T.Vrms,G),...
    splitapply(@mean,T.dBcalc,G),...
    'VariableNames',{'sound_ID','Vrms','dB'});

%% get gain values and table
micCalV = Tmean{contains(Tmean.sound_ID,'reference'),'Vrms'};

dBwant = 30:5:70;

Vwant = dBwant2voltage(dBwant,micCalV,dBref);
Gwant = Vwant2gain(Vwant,Tmean{~contains(Tmean.sound_ID,'reference'),'Vrms'},1800);

TgSet = splitvars(table(Tmean{~contains(Tmean.sound_ID,'reference'),'sound_ID'},Gwant));
TgSet.Properties.VariableNames = horzcat('sound_ID',strcat(cellstr(string(dBwant)),' dB'));

writetable(TgSet,fullfile(lFolder,'gainTable.xlsx'));

%% save data in structure

calibrationOutput_oscope.date = datestr(now,'yyyymmdd');
calibrationOutput_oscope.micType = micType;
calibrationOutput_oscope.VtoPa = VtoPa;
calibrationOutput_oscope.micCalV = micCalV;
calibrationOutput_oscope.micCaldB = dBref;
calibrationOutput_oscope.Gcal = Gcal;
calibrationOutput_oscope.Tcal = T;
calibrationOutput_oscope.Tmean = Tmean;
calibrationOutput_oscope.TgainSet = TgSet;

savePath = 'C:\Data\Rig Software\speakerCalibration\';
save(fullfile(savePath,['calibrationOutput_oscope_'...
    micType 'mic_' ...
    num2str(Gcal) 'gain_' ...
    num2str(datestr(now,'yyyymmdd')) '.mat']),'calibrationOutput_oscope');



