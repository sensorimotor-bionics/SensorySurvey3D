%% Survey extraction
% This code was initially modified from MC1_SurveyExtraction in MEU Survey
% (misc_analysis/MMI). This code can process multi-channel data, but the
% DSMB data should only be from single channel data.

% Version 1.0 12/04/2025 Initial Version

% Contact Mark Iskarous (miskarous@uchicago.edu) if you want to discuss the
% code

clear all;
close all;

% Where to store extracted files
input_directory = fullfile(ProjPath, 'SurveyRawDataDev4');

subject_list = {'BCI02', 'BCI03'};

conform_to_2D_illustration = false;

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

data2 = convertMaps(data,conversionMatrix,modelIn,modelOut);

%% Consolidate electrodes (with model and within date range)

% Earliest date to consolidate 'uuuu-MM-dd')
earliest = '2025-11-01';
earliest = datetime(earliest, 'Format', 'uuuu-MM-dd'); 
% Latest date to consolidate 'uuuu-MM-dd')
latest = '2026-07-01';
latest = datetime(latest, 'Format', 'uuuu-MM-dd'); 

consolidateModel = 'default_hand_r_vertical_high_res.glb';

for s = 1:length(subject_list)
    consElec{s} = consolidateElectrodes(data2,subject_list{s},consolidateModel,earliest,latest);
end

consElec = [consElec{:}];

%% Consolidate all individual electrodes together (with model)

consolidateModel = 'default_hand_r_vertical_high_res.glb';

for s = 1:length(subject_list)
    allConsElec(s) = allElecDSMB(consElec,subject_list{s},consolidateModel);
end

%% Launch Annotation Viewers for each particpant

type = 'ar';
mode = 'bin';

for s = 1:length(subject_list)
    launch_annotation_viewers(subject_list{s},allConsElec,"hand_landmarks",type,mode);
end

