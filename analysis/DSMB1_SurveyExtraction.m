%% Survey extraction
% This code extracts 2D survey data from OLS (extract_OLS) and 3D survey
% data from Sensory Executive (extract_SE). It locates the data in the Data
% Server and saves the extracted information in output_directory. Log_path
% refers to an spreadsheet which outlines which participants, sessions, and
% sets should be extracted. This code supports multi-electrode surveys.
% A file is generated for each session that was extracted (organized by
% participant). All the survey data is appended together separated into
% files by participant and format (OLS vs SE).
% The log file is intended to capture all meaningful survey data
% collected over time. The later processing stages can then filter (by
% date, participant, number of channels, etc...). 

% Version 1.0 06/16/2026 Initial Version

% Contact Mark Iskarous (miskarous@uchicago.edu) if you want to discuss the
% code

clear all;
close all;

addpath(genpath(pwd()))

% Location of the log file that indicates which sessions and sets to use
log_path = fullfile(pwd(), "SurveyLog_DSMB_chicago.xlsx");
% The location that data is stored in
DataDir = cc.load_config.system().backup_path;
% Where to store extracted files
output_directory = fullfile(ProjPath, 'SurveyRawData_2607');

data_log = readtable(log_path,'Format','auto'); % must use readcell to allow for multiple sets
elec_log = readtable("ElectrodeCharacteristics.xlsx",'Format','auto'); % must use readcell to allow for multiple sets

% Overwrite extraction
overwrite_extraction = false;

%% Iterate through the log and process each session:set

for i = 1:size(data_log.Session, 1) % Each session
    % Generate session path
    subject_id = data_log.Subject{i};
    if isempty(subject_id)
        continue
    end
    
    % Catch the heinousness that is Home/Lab >:( 
    if endsWith(subject_id, 'Home')
        subid = subject_id(1:end-4);
    elseif endsWith(subject_id, 'Lab')
        subid = subject_id(1:end-3);
    else
        subid = subject_id;
    end

    log_sess = data_log.Session{i};
    % Determine if the session is from OLS (just a session number) or
    % SensoryExecutive (a timestamp)
    if contains(log_sess,'_')
        session_str = sprintf('%s.data.%s', subject_id, data_log.Session{i});
        session_path = fullfile(DataDir, subid, 'SensoryExecutive', session_str);
        sess_SE = true;
    else
        session_str = sprintf('%s.data.%05d', subject_id, str2num(data_log.Session{i}));
        session_path = fullfile(DataDir, subid, 'OpenLoopStim', session_str);
        sess_SE = false;
    end

    fprintf(' - Processing %s\n', session_str)

    % Check if we've already processed the file
    if exist(fullfile(output_directory, subid, [session_str, '.mat']), 'file') == 2 && ~overwrite_extraction
        fprintf(' - Skipping %s (already processed) \n', session_str)
        continue
    end

    % Parse the SetIDs
    if isa(data_log.Sets{i}, 'double')
        set_ids = data_log.Sets{i};
    elseif isa(data_log.Sets{i}, 'char')
        set_ids = str2num(data_log.Sets{i}); %#ok<ST2NM> 
    end

    % Bundle information needed for extraction function
    info{1} = log_sess;
    info{2} = subid;
    info{3} = subject_id;
    info{4} = session_str;
    info{5} = elec_log;

    if sess_SE
        extract_SE(session_path,set_ids,output_directory,info);
    else
        extract_OLS(session_path,set_ids,output_directory,info);
    end

end

%% Combine all survey data for each participant

subject_list = {'BCI02', 'BCI03'};

req_fn_OLS = GetSurveyOLSStructFields();
req_fn_SE = GetSurveySEStructFields();

for s = 1:length(subject_list)
    fprintf(' - Combining all OLS survey data from %s together\n', subject_list{s});
    flist_OLS = dir(fullfile(output_directory, subject_list{s}, '*.data.0*.mat'));
    survey_subj_data = cell(size(flist_OLS));
    for f = 1:length(flist_OLS)
        temp = load(fullfile(flist_OLS(f).folder, flist_OLS(f).name)).SurveyData;
        if isempty(fieldnames(temp))
            continue
        end

        % Check fieldnames
        fn_idx = find(~contains(req_fn_OLS, fieldnames(temp)));
        if ~isempty(fn_idx)
            for fi = 1:length(fn_idx)
                temp(1).(req_fn_OLS{fn_idx(fi)}) = [];
            end
        end
        survey_subj_data{f} = temp;
    end
    survey_subj_data = cat(2, survey_subj_data{:});
    % Save
    save(fullfile(output_directory, sprintf('SurveyRawOLSData_%s.mat', subject_list{s})), "survey_subj_data",'-v7.3')
    fprintf(' - Done!\n')

    fprintf(' - Combining all Sensory Executive survey data from %s together\n', subject_list{s});
    flist_SE = dir(fullfile(output_directory, subject_list{s}, '*.data.*_*.mat'));
    survey_subj_data = cell(size(flist_SE));
    for f = 1:length(flist_SE)
        temp = load(fullfile(flist_SE(f).folder, flist_SE(f).name)).SurveyData;
        if isempty(fieldnames(temp))
            continue
        end

        % Check fieldnames
        fn_idx = find(~contains(req_fn_SE, fieldnames(temp)));
        if ~isempty(fn_idx)
            for fi = 1:length(fn_idx)
                temp(1).(req_fn_SE{fn_idx(fi)}) = [];
            end
        end
        survey_subj_data{f} = temp;
    end
    survey_subj_data = cat(2, survey_subj_data{:});
    % Save
    save(fullfile(output_directory, sprintf('SurveyRawSEData_%s.mat', subject_list{s})), "survey_subj_data",'-v7.3')
    fprintf(' - Done!\n')
end
