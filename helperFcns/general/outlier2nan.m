function inputSansOutlier = outlier2nan(input,SDthresh)

u = nanmean(input);
sd = nanstd(input);

inputSansOutlier = idx2nan(input,input>=u+sd*SDthresh | input<=u-sd*SDthresh);