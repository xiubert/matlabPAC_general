function animal = dataPath2animalStr(dataPath)

animal = regexp(dataPath,'[A-Z]{2}\d{4}','match','once');