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

%% Create Maps for plotting

allData = [data{:}];

allData2 = createMaps(allData);



%% Launch Annotation Viewers for each particpant

allData = [data{:}];

for s = 1:length(subject_list)
    allData = launch_annotation_viewers(subject_list{s},allData,"hand_landmarks");
end

%allData = launch_annotation_viewers('BCI02',allData,"hand_landmarks");
%allData = launch_annotation_viewers('BCI03',allData,"hand_landmarks");

