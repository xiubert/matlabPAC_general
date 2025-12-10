clearvars
%script to output legend of qcam / xsg files
%IMPORTANT: the contains function runs on matlab 2016 and above

%Select folder containing qcam+xsg files on day of interest
datapath = uigetdir('C:\Users\Anderson\Desktop','Select folder containing qcam+xsg files on day of interest');
dirinfo = dir(datapath);

% %remove directories from dirinfo:
% dirinfo = dirinfo(~cell2mat(extractfield(dirinfo,'isdir')));

%remove everything but xsg and qcam files
fnames = extractfield(dirinfo,'name');
dirinfo = dirinfo(contains(fnames,["xsg","qcam"]));
% dirinfo = dirinfo(contains(fnames,["xsg","qcam","tif"]));
fnames = extractfield(dirinfo,'name');

dirinfo = rmfield(dirinfo,{'datenum','isdir'});

%for each xsg file in the directory scrape the following data from the xsg
%file header
xsgtf = contains(fnames,'xsg');
for trace = 1:length(dirinfo)
    if xsgtf(trace)
        d = load([dirinfo(trace).folder '\' dirinfo(trace).name],'-mat');
        if trace>1
            [~,xsgname,~] = fileparts([dirinfo(trace).folder '\' dirinfo(trace).name]);
            [~,qcamname,~] = fileparts([dirinfo(trace-1).folder '\' dirinfo(trace-1).name]);
            if strcmp(xsgname,qcamname)
                %NOTE:  this assumes audio pulse is the first stimulator
                %channel (eg 1.audio 2.LED 3.camera trigger)
                dirinfo(trace-1).pulse = d.header.stimulator.stimulator.pulseNameArray{1};
                dirinfo(trace-1).gain = d.header.stimulator.stimulator.extraGainArray(1);
                dirinfo(trace-1).tracelength = d.header.stimulator.stimulator.traceLength;
                dirinfo(trace-1).framesAcq = d.header.qcam.qcam.framesToAcquire;
                dirinfo(trace-1).framesPerFile = d.header.qcam.qcam.framesPerFile;
                dirinfo(trace-1).exposure = d.header.qcam.qcam.exposure;
                dirinfo(trace-1).framerate = dirinfo(trace-1).framesAcq/dirinfo(trace-1).tracelength;
            end
        end
    end
end

%reorder the fields so things make more sense
dirqcam = dirinfo(contains(fnames,'qcam'));
% dirqcam = dirinfo(contains(fnames,['qcam','tif']));

fields = fieldnames(dirqcam);
fields{1} = 'folder';
fields{2} = 'date';
fields{3} = 'bytes';
fields{4} = 'name';
dirqcam = orderfields(dirqcam, fields);

%sort structure by size, pulse, then gain
bytes = extractfield(dirqcam,'bytes');
pulse = extractfield(dirqcam,'pulse');
pulse(cellfun(@isempty,pulse)) = {'Empty'};
gain = {dirqcam(1:length(dirqcam)).gain};
gain(cellfun(@isempty,gain)) = {NaN};
gain = cell2mat(gain);
T = table(bytes',pulse',gain');
% [~,IDX] = sortrows(T,[1 2 3]);
[~,IDX] = sortrows(T,[2 1 3]);
dirqcam = dirqcam(IDX);

[~,foldername] = fileparts(datapath);
folderdate = datestr(dirqcam(1).date,'YYYYmmdd');
filenamenpath = [datapath '\stimfilelegend_qcamraw_' foldername '_' folderdate '.xls'];

%drops an excel spreadsheet with the relevant parameters in the same folder
%as the data
Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
xlswrite(filenamenpath, fields', ['A1:' Alphabet(length(fields)) '1']);
xlswrite(filenamenpath, struct2cell(dirqcam)', ['A2:' Alphabet(length(fields)) num2str(length(dirqcam)+1)]);



