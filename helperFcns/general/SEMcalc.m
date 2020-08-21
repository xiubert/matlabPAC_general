function SEM = SEMcalc(data,varargin)
% SEMcalc: calculate SEM of input data.
%   SEM = SEMcalc(data,dimension)
%           
%       INPUT:
%           data, --> data for which SEM is calculated
%
%           varargin, --> dimension along which to calculate SEM
%                         defaults to 1              

switch nargin
    case 1
        dimension = 1;
    case 2
        dimension = varargin{1};
end

SEM = nanstd(data,0,dimension)./sqrt(sum(~isnan(data),dimension));
