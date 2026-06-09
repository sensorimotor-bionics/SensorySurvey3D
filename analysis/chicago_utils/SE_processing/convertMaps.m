function Survey3DDataRecord = convertMaps(Survey3DData,conversionMatrix, modelIn, modelOut)
    Survey3DDataRecord = Survey3DData;
    if size(modelIn.vertices,1) ~= size(conversionMatrix,2)
        warning(sprintf('The dimension of the input model (%d) does not match the dimension of the conversion matrix (%d).\n',...
            size(modelIn.vertices,1),size(conversionMatrix,2)));
        return;
    end
    if size(modelOut.vertices,1) ~= size(conversionMatrix,1)
        warning(sprintf('The dimension of the output model (%d) does not match the dimension of the conversion matrix (%d).\n',...
            size(modelOut.vertices,1),size(conversionMatrix,1)));
        return;
    end

    qualities = fieldnames(Survey3DData(1).PFQualities);

    for d = 1:length(Survey3DData)
        if Survey3DData(d).ModelName == string(modelIn.name)
            Survey3DDataRecord(d).Model = modelOut;
            Survey3DDataRecord(d).ModelName = modelOut.name;
            for ns = 1:Survey3DData(d).NumSense
                Survey3DDataRecord(d).PFBasics(ns).fields = double((conversionMatrix*Survey3DData(d).PFBasics(ns).fields)>=1.5);
            end
            Survey3DDataRecord(d).binaryMap = double((conversionMatrix*Survey3DData(d).binaryMap)>=1.5);
            for q = 1:length(qualities)
                Survey3DDataRecord(d).binaryQualities.(qualities{q}) = double((conversionMatrix*Survey3DData(d).binaryQualities.(qualities{q}))>=1.5);
            end
        end
    end
end