function cellsOutput = emptyCells2NaN(cellsInput)
cellsInput(cellfun(@(c) isempty(c),cellsInput)) = {NaN};
cellsOutput = cellsInput;
 

