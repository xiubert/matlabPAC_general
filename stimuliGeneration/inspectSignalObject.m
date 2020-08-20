function varargout = inspectSignalObject(varargin)
% inspectSignalObject plots signal amplitude across time for provided
% .signal file
%
%           IMPORTANT NOTE: 
%                Ephus @signalObject class library must be added to path
%                eg. ephus_library
%
%
%           INPUT: 
%               varargin --> no input: browse .signal file
%                            otherwise: provide full path to .signal file                             
%
%           OUTPUT:
%               y --> signal vector (amplitude over time)
%               signalSampleRate --> signal sample rate
%               sigFilePath --> absolute path to signal file
%
%
%   See also getContrastDRCvars.m

switch nargin
    case 0
        [sigfile, sigpath] = uigetfile('C:\Data\Rig Software\250kHzPulses\*.signal','Choose signal to analyze...','MultiSelect','on');
    case 1
        [path, file, ext] = fileparts(varargin{1});
        sigpath = [path filesep];
        sigfile = [file ext];
end

if ~iscell(sigfile)
    tmp = sigfile;
    clear sigfile
    sigfile{1} = tmp;
end

for fileNo = 1:length(sigfile)
    sigS = load(fullfile(sigpath,sigfile{fileNo}),'-mat');
    signalduration = get(sigS.signal,'length'); %in seconds
    signalSampleRate = get(sigS.signal,'sampleRate'); %in Hz
    time = 0:1/signalSampleRate:signalduration-1/signalSampleRate;
    disp(sigfile{fileNo})
    %get time series data
    y = getdata(sigS.signal,signalduration); %or get(signal,'signal');
    
    figure('Name',strrep(sigfile{fileNo},'.signal',''))    
    
    if contains(sigfile{fileNo},'DRC') 
        
        %determine contrast level
        [colors,~] = getContrastDRCvars();
        pColor = colors.lohiPre((abs(eval(string(regexp(sigfile{fileNo},'(?<a>\d{2}-\d{2})dB','tokens'))))>15)+1,:);

        
        if contains(sigfile{fileNo},'stim')
            ptOnset = str2double(strrep(string(regexp(sigfile{fileNo},...
                '_at_(?<a>(\dpt\d|\d))s','tokens')),'pt','.'));
            
            startT = find(time==ptOnset-0.5);
            endT = find(time==ptOnset+1.5);

            plot(time(startT:endT),y(startT:endT),'Color',pColor);          
        else
            startT = find(time==1.5);
            endT = find(time==3.5);            
            plot(time(startT:endT),y(startT:endT),'Color',pColor);
        end
        
    else
        plot(time,y);
        yl = ylim;
        if yl(2)==1
            ylim([-1.2 1.2])
        end
    end
    
    ylabel('Amplitude')
    xlabel('Time (s)')
    box('off')
    title(strrep(sigfile{fileNo},'.signal',''),'Interpreter','none','FontWeight','normal','FontSize',8)
end
clear signalduration signalSampleRate time y sigS

%handle output
switch nargout
    case 0
        varargout{1} = '';
    case 1
        varargout{1} = y;
    case 2
        varargout{1} = y;
        varargout{2} = signalSampleRate;
    case 3
        varargout{1} = y;
        varargout{2} = signalSampleRate;
        varargout{3} = fullfile(sigpath,sigfile);      
end


end
