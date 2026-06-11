function ConsolidatedElec = consolidateElectrodes(Survey3DData, subject, modelName, earliest, latest)

    % Filter to consolidate the requested subject
    subjects = {Survey3DData.Subject};
    subjectIdx = find(strcmp(subjects,subject));
    Survey3DDataRecord = Survey3DData(subjectIdx);

    % Filter to use the requested model and No_Report
    models = {Survey3DDataRecord.ModelName};
    modelIdx = find(strcmp(models,modelName) | strcmp(models,"No_Report"));
    Survey3DDataRecord = Survey3DDataRecord(modelIdx);

    % Filter by dates
    dates = {Survey3DDataRecord.Date};
    dateIdx = find(dates>earliest & dates<latest);
    Survey3DDataRecord = Survey3DDataRecord(dateIdx);

    % Get example model information 
    exModelIdx = find(strcmp({Survey3DDataRecord.ModelName},modelName),1);
    exModel = Survey3DDataRecord(exModelIdx);
    model = exModel.Model;
    modelVertices = size(exModel.Model.vertices,1);
    qualities = fieldnames(exModel.PFQualities);

    chList = cell2mat([{Survey3DDataRecord.Ch1};{Survey3DDataRecord.Ch2};{Survey3DDataRecord.Ch3};{Survey3DDataRecord.Ch4}])';
    [u_channels dataIdx channelIdx] = unique(chList,'rows');

    ConsolidatedElec = struct();

    for c = 1:length(u_channels)        

        electrodeIdx = find(channelIdx == c);
        numTest = length(electrodeIdx);
        electrodeData = Survey3DDataRecord(electrodeIdx);

        ConsolidatedElec(c).Subject = subject;
        ConsolidatedElec(c).Ch1 = electrodeData(1).Ch1;
        ConsolidatedElec(c).Ch2 = electrodeData(1).Ch2;
        ConsolidatedElec(c).Ch3 = electrodeData(1).Ch3;
        ConsolidatedElec(c).Ch4 = electrodeData(1).Ch4;
        ConsolidatedElec(c).ElectrodeID = electrodeData(1).ElectrodeID;
        

        summedMap = zeros(modelVertices,1);
        for q = 1:length(qualities)
            qualityStruct.(qualities{q}) = [];
            summedQualities.(qualities{q}) = zeros(modelVertices,1);
        end

        ConsolidatedElec(c).PFQualities = qualityStruct;
        ConsolidatedElec(c).NumTest = numTest;
        ConsolidatedElec(c).Model = model;
        ConsolidatedElec(c).ModelName = modelName;

        for ci = 1:numTest
            if electrodeData(ci).ModelName ~= "No_Report"
                summedMap = summedMap + electrodeData(ci).binaryMap;
                for q = 1:length(qualities)
                    currQuality = qualities{q};
                    summedQualities.(currQuality) = summedQualities.(currQuality) + electrodeData(ci).binaryQualities.(currQuality);
                end
            end
        end

        ConsolidatedElec(c).binaryMap = (summedMap > 0);
        ConsolidatedElec(c).freqMap = (summedMap/numTest);

        for q = 1:length(qualities)
            currQuality = qualities{q};
            binaryQualities.(currQuality) = (summedQualities.(currQuality) > 0);
            freqQualities.(currQuality) = (summedQualities.(currQuality) / numTest);
        end

        ConsolidatedElec(c).binaryQualities = binaryQualities;
        ConsolidatedElec(c).freqQualities = freqQualities;
    end
end