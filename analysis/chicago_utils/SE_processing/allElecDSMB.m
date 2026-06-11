function allElec = allElecDSMB(Survey3DData, subject, modelName)

    % Filter to consolidate the requested subject
    subjects = {Survey3DData.Subject};
    subjectIdx = find(strcmp(subjects,subject));
    Survey3DDataRecord = Survey3DData(subjectIdx);

    % Filter to use the requested model and No_Report
    models = {Survey3DDataRecord.ModelName};
    modelIdx = find(strcmp(models,modelName) | strcmp(models,"No_Report"));
    Survey3DDataRecord = Survey3DDataRecord(modelIdx);

    % Get example model information 
    exModelIdx = find(strcmp({Survey3DDataRecord.ModelName},modelName),1);
    exModel = Survey3DDataRecord(exModelIdx);
    model = exModel.Model;
    modelVertices = size(exModel.Model.vertices,1);
    qualities = fieldnames(exModel.PFQualities);

    chList = cell2mat([{Survey3DDataRecord.Ch1};{Survey3DDataRecord.Ch2};{Survey3DDataRecord.Ch3};{Survey3DDataRecord.Ch4}])';
    % Keep only channel groups that are single electrode
    chIdx = find(chList(:,2)==0);
    Survey3DDataRecord = Survey3DDataRecord(chIdx);

    chList = cell2mat([{Survey3DDataRecord.Ch1};{Survey3DDataRecord.Ch2};{Survey3DDataRecord.Ch3};{Survey3DDataRecord.Ch4}])';
    [u_channels dataIdx channelIdx] = unique(chList,'rows');
    numChannels = length(u_channels);

    allElec = struct();

    allElec.Subject = subject;
    allElec.Ch1 = 10000;
    allElec.Ch2 = 0;
    allElec.Ch3 = 0;
    allElec.Ch4 = 0;
    allElec.ElectrodeID = 'e_10000_0_0_0';

    summedMap = zeros(modelVertices,1);
    for q = 1:length(qualities)
        qualityStruct.(qualities{q}) = [];
        summedQualities.(qualities{q}) = zeros(modelVertices,1);
    end

    allElec.PFQualities = qualityStruct;
    allElec.Model = model;
    allElec.ModelName = modelName;

    for c = 1:numChannels
        electrodeIdx = find(channelIdx == c);
        electrodeData = Survey3DDataRecord(electrodeIdx);

        summedMap = summedMap + electrodeData.binaryMap;
        for q = 1:length(qualities)
            currQuality = qualities{q};
            summedQualities.(currQuality) = summedQualities.(currQuality) + electrodeData.binaryQualities.(currQuality);
        end
    end

    allElec.binaryMap = (summedMap > 0);
    allElec.freqMap = (summedMap/numChannels);

    for q = 1:length(qualities)
        currQuality = qualities{q};
        binaryQualities.(currQuality) = (summedQualities.(currQuality) > 0);
        freqQualities.(currQuality) = (summedQualities.(currQuality) / numChannels);
    end

    allElec.binaryQualities = binaryQualities;
    allElec.freqQualities = freqQualities;
end