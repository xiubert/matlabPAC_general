function pctBase = pctBaseline(inputMatTraceByRow,baselineLogicalRow)
% tmp = nanmean(inputMatTraceByRow(:,baselineLogicalRow),2);
pctBase = bsxfun(@rdivide,inputMatTraceByRow,...
    nanmean(inputMatTraceByRow(:,baselineLogicalRow),2)).*100;