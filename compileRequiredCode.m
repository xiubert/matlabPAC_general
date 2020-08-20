%get analysis code list:
clearvars;close all;
[file,path] = uiputfile('C:\Users\*.mat','Designate file for saving list of required code files...');

analysisCodeNeeded = cell(0);

scriptList = {'NoRMCorreFISSApipeline.m',...
    'roiGUI.m',...
    'minimalTifROIgui.m',...
    'compileTRF.m',...
    'plotTRFmap',...
    'adhocBFmap.m',...
    'plotCompiledTRFoutput.m',...
    };
    
for k = 1:length(scriptList)
    analysisCodeNeeded{k,1} = scriptList{k};
    [fList,pList] = matlab.codetools.requiredFilesAndProducts(scriptList{k});
    analysisCodeNeeded{k,2} = fList;
    analysisCodeNeeded{k,3} = pList;
    
    clear fList pList
end

tmp = cellfun(@transpose,analysisCodeNeeded(:,2),'uni',0);
tmp2 = cellfun(@transpose,analysisCodeNeeded(:,3),'uni',0);

analysisCodeNeeded{k+1,1} = 'COMPILED';
analysisCodeNeeded{k+1,2} = unique(cat(1,tmp{:}));
analysisCodeNeeded{k+1,3} = unique(struct2table(cat(1,tmp2{:})));

save(fullfile(path,file),'analysisCodeNeeded')

