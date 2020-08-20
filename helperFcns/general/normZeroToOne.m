function normOutput = normZeroToOne(input,varargin)


% normOutput = (inputVector-min(inputVector))./...
%     max(inputVector-min(inputVector));

if isempty(varargin) && isvector(input)
    normOutput = (input-min(input))./...
        (max(input)-min(input));
    
elseif isempty(varargin) && ~isvector(input)
    error('must input dimension along which to normalize')
    
elseif isnumeric(varargin{1}) && varargin{1}==1
    normOutput = (input-min(input))./...
        (max(input)-min(input));
    
elseif isnumeric(varargin{1}) && varargin{1}==2
    
    normOutput = (input-min(input,[],2))./...
        (max(input,[],2)-min(input,[],2));
    
elseif ~isnumeric(varargin{1}) && strcmp(varargin{1},'all')
    
    normOutput = reshape((input(:)-min(input(:)))./...
        (max(input(:))-min(input(:))),size(input));
end
    
    
    

