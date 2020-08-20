%% Speaker calibration using oscilloscope data files
%obtains dB based upon average of voltage reference readings
clearvars;close all
oscDataDir = 'C:\Users\PAC\OneDrive - University of Pittsburgh\Personal\Thanos Lab\speaker calibration\calibrationData\Stelios\ST';
dataDir = dir(oscDataDir);
dataDir = dataDir(~cellfun(@isempty,regexp({dataDir.name},'[A-Z]{3}\d{4}','match','once')));
refSel = listdlg('PromptString','Select reference folders','ListString',{dataDir.name});
refDir = dataDir(refSel);
dBref = inputdlg('Enter reference dB value (94 dB default)');
if isempty(dBref) || strcmp(dBref,'')
    dBref = 94;
else
    dBref = dBref{1};
end

stimDir = dataDir(~ismember(1:length(dataDir),refSel));
prompt = {stimDir.name};
stimLabels = inputdlg(prompt,'Enter corresponding stimulus',[1 80]);

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
    VgapFix{nDir} = Vraw{nDir}(Vraw{nDir}~=mode(tmp));
    tGapFix{nDir} = tRaw{nDir}(Vraw{nDir}~=mode(tmp));
    
    %MUST DETREND TO ALIGN SIGNAL AT 0 FOR ACCURATE Vrms calculation
    %likely that signal not aligned at 0 on oscilloscope
    VgapFixDetrend{nDir} = detrend(VgapFix{nDir});
    
%     figure; 
%     subplot(1,2,1)
%     plot(tGapFix{nDir},VgapFix{nDir})
%     subplot(1,2,2)
%     plot(tGapFix{nDir},VgapFixDetrend{nDir})
    Vrms(nDir,1) = sqrt(mean((VgapFixDetrend{nDir}).^2)); 
    %Vrms2(nDir,1) = rms(VgapFixDetrend{nDir}); %same as above
    clear tmp
end
%% create output table
dBcalc = Volt2dB(Vrms,nanmean(Vrms(refSel)),dBref);
conds = cell(length(dataDir),1);
conds(refSel) = {'reference'};
conds(~ismember(1:length(dataDir),refSel)) = stimLabels;
T = table(conds,Vrms,dBcalc);
%see
% dBwant2voltage()
% Vwant2gain()