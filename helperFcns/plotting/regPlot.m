function [mdl, ciRegLine, hFig, hScatter, hRegLine, hRegLineCI, hRef] = regPlot(X,Y,varargin)

p = inputParser;
addRequired(p, 'X', @isnumeric);
addRequired(p, 'Y', @isnumeric);
addParameter(p,'regLine',true,@islogical)
addParameter(p,'intercept',true,@islogical)
addParameter(p,'colors',[],@(x) isequal(size(x),[2 3]))
addParameter(p,'logScale',false,@islogical)
addParameter(p,'sigID',false,@islogical)
addParameter(p,'fName','scatter plot with regression line and CI',@ischar)
addParameter(p,'refLine',false,@islogical)
addParameter(p,'mRefLine',1,@isnumeric)
addParameter(p,'bRefLine',0,@isnumeric)
addParameter(p,'squareAxis',false,@islogical)

parse(p, X, Y, varargin{:})
X = p.Results.X;
Y = p.Results.Y;
intercept = p.Results.intercept;
colors = p.Results.colors;
logScale = p.Results.logScale;
sigID = p.Results.sigID;
fName = p.Results.fName;
refLine = p.Results.refLine;
mRefLine = p.Results.mRefLine;
bRefLine = p.Results.bRefLine;
regLine = p.Results.regLine;
squareAxis = p.Results.squareAxis;

%scatter with regression line and confidence interval
if logScale
    X = log10(X);
    Y = log10(Y);
end
tbl = table(X,Y);
if ~intercept
    mdl = fitlm(tbl,'Y ~ X-1'); % '-1' means remove intercept
else
    mdl = fitlm(tbl,'Y ~ X'); % '-1' means remove intercept
end

g = groot;
if isempty(g.Children) || ~strcmp(fName,'scatter plot with regression line and CI')
    hFig = figure('Name',fName);
end

if length(sigID)>1
    hScatter = gscatter(X,Y,sigID,'kk','o.');
else
    hScatter = scatter(X,Y,'k','o');
end
if squareAxis
    xlim(round([min([xlim ylim]) max([xlim ylim])]))
    ylim(round([min([xlim ylim]) max([xlim ylim])]))
end
hold on
if refLine
    hRef = refline(mRefLine,bRefLine);
    hRef.LineStyle = '--';
    % hRef.Color = colors.ratio(1,:);
    hRef.Color = 'r';
    hRef.LineWidth = 2;
end
if min([xlim ylim])>0
    xRegLine = linspace(min([xlim ylim]),max([xlim ylim]),1000);
else
    xRegLine = linspace(0,max([xlim ylim]),1000);
end
% yRegLine = xRegLine.*mdl.Coefficients.Estimate;
[yRegLine,ciRegLine] = predict(mdl,xRegLine(:));

if regLine
    hRegLine = plot(xRegLine,yRegLine,...
        'LineWidth',1.5);
    if ~isempty(colors)
        hRegLine.Color = colors(1,:);
        hRegLineCI = fill([xRegLine';flipud(xRegLine')],...
            [ciRegLine(:,1);flipud(ciRegLine(:,2))],...
            colors(2,:),'linestyle','none',...
            'HandleVisibility','off');
    else
        hRegLine.Color = 'k';
        hRegLineCI = fill([xRegLine';flipud(xRegLine')],...
            [ciRegLine(:,1);flipud(ciRegLine(:,2))],...
            [0.6510    0.6510    0.6510],'linestyle','none',...
            'HandleVisibility','off');
    end
    
    chi=get(gca, 'Children');
    set(gca, 'Children',flipud(chi));
end

title('')
axis square