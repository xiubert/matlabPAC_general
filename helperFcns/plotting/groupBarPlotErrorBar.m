function barCenters = groupBarPlotErrorBar(y,error)
% Finding the number of groups and the number of bars in each group
ngroups = size(y, 1);
nbars = size(y, 2);
% Calculating the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
% Set the position of each error bar in the centre of the main bar
% Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
barCenters = [];
for i = 1:nbars
    % Calculate center of each bar
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, y(:,i), error(:,i), 'k','LineWidth',1.5, 'linestyle', 'none','HandleVisibility','off');
    barCenters = [barCenters x];
end

end