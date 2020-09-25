%% Inverse filter calibration approach

%Basic idea: 
%1. obtain mic calibration factor
%2. set gain to Gcal, record Vout for each frequency in DRC / test tones
%   (cycle Vrms from FFT fit of frequency on oscilloscope)
%3. Determine Gset from Vwant,Vout, and Gcal for each frequency for given dBwant
    %gain vs Vout is linear, thus can scale V by some gain to obtain
    %desired Vout

%% Inverse Filter Calibration Approach w/ Dialog Input
%new freq range:  5-40kHz 1/8 oct interval (25 freq) %pre 2019
%2019 onward: 5-52 kHz @ 1/8 oct interval (29 freq)
%load freq
clearvars;close all;
[freqFile, freqFilePath] = uigetfile('C:\Data\Rig Software\speakerCalibration\*.mat',...
    'Choose mat file containing frequency vector...');
load([freqFilePath freqFile])

%default values
micType = 'BK4954-B'; %<-- 1/4 in | other: BK4183-A-015 (1/8 in) 
VtoPa = 3.16;
Gcal = 1500;
micCalV = '36.6 36.3 36.2';
micCaldB = 94; %decibel level of square mic calibration speaker (B&K TYPE 4231 SOUND CALIBRATOR)

definput = {micType,num2str(VtoPa),micCalV,num2str(Gcal)};

x = inputdlg({'Mic Type','Amp V/Pa','Mic Calibration (V)',...
    'Gain for Calibration'},'Speaker Calibration Settings',...
              [1 30; 1 30;  1 30; 1 30],definput);

micType = x{1};
VtoPa = str2double(x{2});          
micCalV = str2num(x{3});
Gcal = str2double(x{4});

freqPerWindow = 15;
nWindows = ceil(numel(freq)/freqPerWindow);

for nWin = 1:nWindows
    if nWin==nWindows
        calInput{nWin} = inputdlg(string(round(freq(freqPerWindow*(nWin-1)+1:end))),...
            ['3 space separated voltage readings at G = ' num2str(Gcal)],[1 60]);
    else
        calInput{nWin} = inputdlg(string(round(freq(freqPerWindow*(nWin-1)+1:nWin*freqPerWindow))),...
            ['3 space separated voltage readings at G = ' num2str(Gcal)],[1 60]);
    end
end

Vout = cell2mat(cellfun(@str2num,vertcat(calInput{:}),'uni',0));

%% save data in structure
calibration_oscopeVrms.date = datestr(now,'yyyymmdd');
calibration_oscopeVrms.micType = micType;
calibration_oscopeVrms.VtoPa = VtoPa;
calibration_oscopeVrms.micCalV = micCalV;
calibration_oscopeVrms.micCaldB = micCaldB;
calibration_oscopeVrms.Gcal = Gcal;
calibration_oscopeVrms.freq = freq;
calibration_oscopeVrms.Vout = Vout;
calibration_oscopeVrms.oct = oct;

savePath = 'C:\Data\Rig Software\speakerCalibration\';
save(fullfile(savePath,['calibrationOutput_oscopeVrms_'...
    micType 'mic_'...
    num2str(Gcal) 'gain_'...
    num2str(round(freq(1)/1000)) '-' num2str(round(freq(end)/1000)) ...
    'kHz_' num2str(round(1./oct)) 'thOctInt_' ...
    num2str(datestr(now,'yyyymmdd')) '.mat']),'calibration_oscopeVrms');

%% Plot
close all

%input maximum dB needed
dBwant = 75;

%in case deleted local vars
if exist('Vout','var')~=1
    Vout = calibration_oscopeVrms.Vout;
    micCalV = calibration_oscopeVrms.micCalV;
    micCaldB = calibration_oscopeVrms.micCaldB;
    freq = calibration_oscopeVrms.freq;
    Gcal = calibration_oscopeVrms.Gcal;
    oct = calibration_oscopeVrms.oct;
end
    
meanVout = mean(Vout,2);
uMicCalV = mean(micCalV);

figure;  
subplot(2,1,1)
semilogx(freq,meanVout,'o-')
xlabel('Frequency (Hz)')
ylabel('Voltage (V)')
title({['Gain Setting: ' num2str(Gcal)],...
    ['Frequencies: ' num2str(round(freq(1)/1000)) '-' num2str(round(freq(end)/1000)) ...
    'kHz at 1/' num2str(round(1./oct)) 'th Octave Interval'],...
    ['Red Bar: ' num2str(dBwant) ' dB SPL']})

subplot(2,1,2)
semilogx(freq,Volt2dB(meanVout,uMicCalV,micCaldB),'o-')
xlabel('Frequency (Hz)')
ylabel('dB SPL')
% subplot(2,1,2)
hold on
plot([freq(1) freq(end)],[dBwant dBwant],'r-')

Vwant = dBwant2voltage(dBwant,uMicCalV,micCaldB);
Gset = Vwant2gain(Vwant,meanVout,Gcal);

%Show frequencies that would require gain above 10000 and those that do not
subplot(2,1,2)
hold on
plot(freq(Gset>10000),Volt2dB(meanVout(Gset>10000),uMicCalV,micCaldB),'ro')

hold on
plot(freq(Gset<=10000),Volt2dB(meanVout(Gset<=10000),uMicCalV,micCaldB),'go')

%% Create gain chart
dBwant = 30:5:80;
Vwant = dBwant2voltage(dBwant,uMicCalV,micCaldB);
Gset = Vwant2gain(Vwant,meanVout,Gcal);

