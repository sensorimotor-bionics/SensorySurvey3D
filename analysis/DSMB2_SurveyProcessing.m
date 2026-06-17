%% Survey processing
% This code loads in the raw SE 3D Survey data and then processes it. An
% example of mesh conversion is shown (you will need to provide your
% conversion matrix). Then the data is consolidated by electrode (within a
% provided date range) and all electrodes are further consolidated
% together. Those consolidations are then saved in output_directory. The
% annotation viewers can be launched for the raw or consolidated data.

% Version 1.0 06/17/2025 Initial Version

% Contact Mark Iskarous (miskarous@uchicago.edu) if you want to discuss the
% code

clear all;
close all;

% Where to get extracted files
input_directory = fullfile(ProjPath, 'SurveyRawData_2607');
% Where to store processed files
output_directory = fullfile(ProjPath,'SurveyProcessedData_2607');

subject_list = {'BCI02', 'BCI03'};

%% Load all Sensory Executive Data

for s = 1:length(subject_list)
    fprintf(' - Loading all Sensory Executive survey data from %s\n', subject_list{s});
    data{s} = load(fullfile(input_directory, sprintf('SurveyRawSEData_%s.mat', subject_list{s}))).survey_subj_data;
    fprintf(' - Done!\n')
end

data = [data{:}];

%% Mesh conversion (optional): Load in conversion matrix (can take a few minutes)

conversionMatrix = sparse(load("chicago_utils\mesh_info\default_hand_r_vertical-default_hand_r_vertical_high_res.mat").coverage_transfer_matrix);

%% Mesh conversion (optional)

modelIn = data(find(strcmp({data.ModelName},'default_hand_r_vertical.glb'),1)).Model;
modelOut = data(find(strcmp({data.ModelName},'default_hand_r_vertical_high_res.glb'),1)).Model;

data = convertMaps(data,conversionMatrix,modelIn,modelOut);

%% Consolidate electrodes (with model and within date range)

% Earliest date to consolidate 'uuuu-MM-dd')
earliest = '2025-11-01';
earliest = datetime(earliest, 'Format', 'uuuu-MM-dd'); 
% Latest date to consolidate 'uuuu-MM-dd')
latest = '2026-07-01';
latest = datetime(latest, 'Format', 'uuuu-MM-dd'); 

consolidateModel = 'default_hand_r_vertical_high_res.glb';

for s = 1:length(subject_list)
    consElec{s} = consolidateElectrodes(data,subject_list{s},consolidateModel,earliest,latest);
end

consElec = [consElec{:}];

%% Consolidate all individual electrodes together (with model)

consolidateModel = 'default_hand_r_vertical_high_res.glb';

for s = 1:length(subject_list)
    allConsElec(s) = allElecDSMB(consElec,subject_list{s},consolidateModel);
end

%% Save processed data

for s = 1:length(subject_list)
    fprintf(' - Saving processed SE survey data from %s\n', subject_list{s});

    % Filter to consolidate the requested subject
    subjects = {consElec.Subject};
    subjectIdx = find(strcmp(subjects,subject_list{s}));
    ConsolidatedElectrodes = consElec(subjectIdx);

    % Filter to consolidate the requested subject
    subjects = {allConsElec.Subject};
    subjectIdx = find(strcmp(subjects,subject_list{s}));
    AllElectrodesCombined = allConsElec(subjectIdx);

    % Check if key subfolder exists, if not then make one
    if exist(fullfile(output_directory), 'dir') == 0
        mkdir(fullfile(output_directory))
    end

    % Save
    save(fullfile(output_directory, sprintf('SurveyProcessedSEData_%s_%s_%s.mat', subject_list{s},string(earliest),string(latest))),"ConsolidatedElectrodes","AllElectrodesCombined",'-v7.3')
    fprintf(' - Done!\n')
end

%% Launch Annotation Viewers for each particpant

type = 'ar';
mode = 'freq';

for s = 1:length(subject_list)
    launch_annotation_viewers(subject_list{s},consElec,"hand_landmarks",type,mode);
end