function ConsAllElec = allElecDSMB(ConsElecData, subject, modelName)
% This function takes a set of consolidated electrode data and combines all
% the individual channels together into one map. The binary map represents
% where there was ever any activation. The frequency map represents the
% relative frequency of activation (meaning number of electrodes that have
% activated that have ever activated that spot. In the consolidation
% process process it will filter by participant (subject), and model
% (modelName).

    % Filter to consolidate the requested subject
    subjects = {ConsElecData.Subject};
    subjectIdx = find(strcmp(subjects,subject));
    ConsElecDataRecord = ConsElecData(subjectIdx);

    % Filter to use the requested model and No_Report
    models = {ConsElecDataRecord.ModelName};
    modelIdx = find(strcmp(models,modelName) | strcmp(models,"No_Report"));
    ConsElecDataRecord = ConsElecDataRecord(modelIdx);

    % Get example model information 
    exModelIdx = find(strcmp({ConsElecDataRecord.ModelName},modelName),1);
    exModel = ConsElecDataRecord(exModelIdx);
    model = exModel.Model;
    modelVertices = size(exModel.Model.vertices,1);
    qualities = fieldnames(exModel.PFQualities);

    chList = cell2mat([{ConsElecDataRecord.Ch1};{ConsElecDataRecord.Ch2};{ConsElecDataRecord.Ch3};{ConsElecDataRecord.Ch4}])';
    % Keep only channel groups that are single electrode
    chIdx = find(chList(:,2)==0);
    ConsElecDataRecord = ConsElecDataRecord(chIdx);

    chList = cell2mat([{ConsElecDataRecord.Ch1};{ConsElecDataRecord.Ch2};{ConsElecDataRecord.Ch3};{ConsElecDataRecord.Ch4}])';
    [u_channels dataIdx channelIdx] = unique(chList,'rows');
    numChannels = length(u_channels);

    ConsAllElec = struct();

    ConsAllElec.Subject = subject;
    ConsAllElec.Ch1 = 10000; % Signals that this is consolidation of all electrodes
    ConsAllElec.Ch2 = length(ConsElecDataRecord); % The number of individual electrodes tested
    ConsAllElec.Ch3 = sum([ConsElecDataRecord.AnyCoverage]); % The number of electrodes that result in any coverage
    ConsAllElec.Ch4 = 0;
    ConsAllElec.ElectrodeID = sprintf('e_%d_%d_%d_%d',ConsAllElec.Ch1,ConsAllElec.Ch2,ConsAllElec.Ch3,ConsAllElec.Ch4);

    summedMap = zeros(modelVertices,1);
    for q = 1:length(qualities)
        qualityStruct.(qualities{q}) = [];
        summedQualities.(qualities{q}) = zeros(modelVertices,1);
    end

    ConsAllElec.PFQualities = qualityStruct;
    ConsAllElec.Model = model;
    ConsAllElec.ModelName = modelName;

    for c = 1:numChannels
        electrodeIdx = find(channelIdx == c);
        electrodeData = ConsElecDataRecord(electrodeIdx);

        summedMap = summedMap + electrodeData.BinaryMap;
        for q = 1:length(qualities)
            currQuality = qualities{q};
            summedQualities.(currQuality) = summedQualities.(currQuality) + electrodeData.BinaryQualities.(currQuality);
        end
    end

    maxChActive= max(summedMap);

    ConsAllElec.BinaryMap = (summedMap > 0);
    ConsAllElec.FreqMap = (summedMap/maxChActive);
    %allElec.FreqMap = (summedMap/numChannels);

    for q = 1:length(qualities)
        currQuality = qualities{q};
        BinaryQualities.(currQuality) = (summedQualities.(currQuality) > 0);
        FreqQualities.(currQuality) = (summedQualities.(currQuality) / maxChActive);
        %FreqQualities.(currQuality) = (summedQualities.(currQuality) / numChannels);
    end

    ConsAllElec.BinaryQualities = BinaryQualities;
    ConsAllElec.FreqQualities = FreqQualities;
end