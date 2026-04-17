%%% Preprocessing pipeline
% Declare paths to data folders and .CSV with requested sessions/sets
output_directory = "External";
csv_path = "ExperimentLogExample.xlsx";
DataDir = "./mesh_utils";
data_log = readtable(csv_path,'Format','auto'); % must use readcell to allow for multiple sets
unique_keys = unique(data_log.ExperimentKey);
unique_keys = unique_keys(cellfun(@length, unique_keys) > 0);
data_added = false(length(unique_keys),1);

overwrite = true;
for k = 1:length(unique_keys)
    fprintf('Key %d of %d: %s\n', k, length(unique_keys), unique_keys{k})
    % Check if key subfolder exists, if not then make one
    if exist(fullfile(output_directory, unique_keys(k)), 'dir') == 0
        mkdir(fullfile(output_directory, unique_keys(k)))
    end

    % Get matching experiments
    k_idx = find(strcmp(data_log.ExperimentKey, unique_keys(k)));
    for i = 1:length(k_idx)
        output_fname = sprintf('OLSData.%s.%s.mat', data_log.Subject{k_idx(i)}, data_log.Session{k_idx(i)});
        % Check if existing path exists
        if exist(fullfile(output_directory, unique_keys(k), output_fname), 'file') == 2 && ~overwrite
            continue
        end

        % Use first 5 characters to avoid home/lab issues
        subject_folder_name = data_log.Subject{k_idx(i)};
        session_path = fullfile(DataDir, subject_folder_name, sprintf('%s.data.%s', data_log.Subject{k_idx(i)},...
            string(data_log.Session{k_idx(i)})));

        % Parse the SetIDs
        if isa(data_log.Sets{k_idx(i)}, 'double')
            set_ids = data_log.Sets{k_idx(i)};
        elseif isa(data_log.Sets{k_idx(i)}, 'char')
            set_ids = str2num(data_log.Sets{k_idx(i)}); %#ok<ST2NM> 
        end

        % Parse the Electrode IDs
        elec_ids = str2num(data_log.Electrodes{k_idx(i)});

        %%% Optional experimental log columns -- edit as necessary
        ppw = str2num(data_log.PPW{k_idx(i)});
        pw = str2num(data_log.PW{k_idx(i)});
        probe_date = data_log.Date(k_idx(i));
        %%%

        % Load the struct
        fprintf(' - Loading session %s_data_%s\n', data_log.Subject{k_idx(i)}, data_log.Session{k_idx(i)})
        OLSData = struct();

        % Add annotations to struct
        current_paths = dir([char(session_path),'\',unique_keys{k},'*.json']);

        for s = 1:length(current_paths)
            OLSData(s).Subject = data_log.Subject{k_idx(i)};
            OLSData(s).Session = data_log.Session{k_idx(i)};
            OLSData(s).Set = set_ids(s);
            OLSData(s).Channel = elec_ids(s);

            %%% Optional experimental log columns -- edit as necessary
            OLSData(s).Date = probe_date;
            OLSData(s).PPW = ppw(s);
            OLSData(s).PW = pw(s);
            %%%
            
            OLSData(s).Base = current_paths(s).folder;
            OLSData(s).Annotation = current_paths(s).name;
            OLSData = extract_colormaps(OLSData,s);
        end

        save(fullfile(output_directory, unique_keys(k), output_fname), "OLSData")
        fprintf(' - Exporting %s: %s\n', unique_keys{k}, output_fname)
        % Tag for consolidation
        data_added(k) = true;
    end
end
%%
% Combine data files for each key
for k = 1:length(unique_keys)
    if ~data_added(k) % Only proceed if data was added to that experiment
        continue
    end
    fprintf('Updating experiment %s data file\n', unique_keys{k})
    fprintf(' - Loading\n')

    k_idx = find(strcmp(data_log.ExperimentKey, unique_keys(k)));
    data_struct = struct('Subject', [], ...
        'Session', [], ...
        'Set', [], ...
        'DataType', [], ...
        'SDO', [], ...
        'Channel', [], ...
        'Amplitude', [], ...
        'Frequency', [], ...
        'TestLogComments', [], ...
        'Paradigm', []);

    ii = 1;
    for f = 1:length(k_idx)
        expected_fname = sprintf('OLSData.%s.%s.mat', data_log.Subject{k_idx(f)}, data_log.Session{k_idx(f)});
        if isfile(fullfile(output_directory, unique_keys{k}, expected_fname))
            temp = load(fullfile(output_directory, unique_keys{k}, expected_fname));
            for i = 1:length(temp.OLSData)
                fnames = fieldnames(temp.OLSData(i)); % Manually add fields in case not all are present
                for j = 1:length(fnames)
                    data_struct(ii).(fnames{j}) = temp.OLSData(i).(fnames{j});
                end
                ii = ii + 1;
            end
        end
    end

    % Rename data struct to experiment key - using eval should be safe this way
    eval(sprintf('%sData = data_struct;', unique_keys{k}))
    fprintf(' - Saving\n')
    eval(sprintf('save(fullfile(output_directory, unique_keys{k}, "%sData_Recent.mat"), "%sData", "-v7.3")', unique_keys{k},...
        unique_keys{k}))
end
disp('Data extraction complete')
