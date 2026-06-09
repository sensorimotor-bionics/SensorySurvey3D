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
input_directory = fullfile(ProjPath, 'SurveyRawDataDev3');

subject_list = {'BCI02', 'BCI03'};

conform_to_2D_illustration = false;

%% Load all Sensory Executive Data

for s = 1:length(subject_list)
    fprintf(' - Loading all Sensory Executive survey data from %s\n', subject_list{s});
    data{s} = load(fullfile(input_directory, sprintf('SurveyRawSEData_%s.mat', subject_list{s}))).survey_subj_data;
    fprintf(' - Done!\n')
end

%% Load in conversion matrix

conversionMatrix = sparse(load("chicago_utils\mesh_info\default_hand_r_vertical-default_hand_r_vertical_high_res.mat").coverage_transfer_matrix);

%% Test conversion

% testData = allData2(1).binaryMap;
% tic
% convertedData = double(sum(conversionMatrix.*sparse(repmat(testData',[size(conversionMatrix,1),1])),2)>=1.5);
% toc
% tic
% convertedData2 = double((conversionMatrix*testData)>=1.5);
% toc

%% Create Maps for plotting

allData = [data{:}];

allData2 = createMaps(allData);

modelIn = allData2(find(strcmp({allData2.ModelName},'default_hand_r_vertical.glb'),1)).Model;
modelOut = allData2(find(strcmp({allData2.ModelName},'default_hand_r_vertical_high_res.glb'),1)).Model;

allData3 = convertMaps(allData2,conversionMatrix,modelIn,modelOut);

%% Launch Annotation Viewers for each particpant

for s = 1:length(subject_list)
    launch_annotation_viewers(subject_list{s},allData3,"hand_landmarks");
end

