function outputCellArray = removeEmptyCells(inputCellArray)
    outputCellArray = inputCellArray(~cellfun(@isempty,inputCellArray));