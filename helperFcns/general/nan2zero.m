function output = nan2zero(input)
input(isnan(input))=0;
output = input;