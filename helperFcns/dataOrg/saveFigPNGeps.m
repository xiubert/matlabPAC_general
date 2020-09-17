function saveFigPNGeps(figHandle,filePath,fileNameWOext)
fileNameWOext = [fileNameWOext '.ext'];
savefig(figHandle,fullfile(filePath,strrep(fileNameWOext,'.ext','.fig')));
saveas(figHandle,fullfile(filePath,strrep(fileNameWOext,'.ext','.png')));
saveas(figHandle,fullfile(filePath,strrep(fileNameWOext,'.ext','.eps')));