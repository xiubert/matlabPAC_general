function [t,V,oscSettings] = importOscCSVfile(fullFilename)
% importOscCSVfile: imports .csv data file from oscillocope.
%   [t,V] = importOscCSVfile(fullFilename,varargin)
%           
%       INPUT:
%           fullFilename, --> full path to data file
%
%       OUTPUT:
%           t = time points
%           V = voltage
%           oscSettings = oscilloscope settings at time of data save
%
%
%   See also dBwant2voltage.m, Vwant2gain.m

%get settings 
sMat = xlsread(fullFilename,'B1:B12');
oscSettings.nSamples = sMat(1);
oscSettings.sampleInterval = sMat(2);
oscSettings.timeInterval = sMat(12);
oscSettings.fS = 1/oscSettings.sampleInterval;
oscSettings.verticalScale = sMat(9);
oscSettings.verticalOffest = sMat(10);
clear sMat

dMat = xlsread(fullFilename,['D1:E' num2str(oscSettings.nSamples)]);
t = dMat(:,1);
V = dMat(:,2).*oscSettings.verticalScale+oscSettings.verticalOffest;
end
