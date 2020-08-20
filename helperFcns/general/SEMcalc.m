function SEM = SEMcalc(data,dimension)

SEM = nanstd(data,0,dimension)./sqrt(sum(~isnan(data),dimension));

end