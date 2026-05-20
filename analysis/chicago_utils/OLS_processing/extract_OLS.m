function extract_OLS(session_path,set_ids,output_directory,info)

    c_max = 4; % Just define the number of channels in a set (for padding purposes)

    log_sess = info{1};
    subid = info{2};
    subject_id = info{3};
    session_str = info{4};
    elec_log = info{5};

    % Get masks and segments
    % Create masks
    [palmar_mask, palmar_template, dorsal_mask, dorsal_template] = GetHandMasks();
    % Create segmented regions
    [palmar_segments, dorsum_segments] = GetHandSegments();
    % Label conversions from OLS to segments - these might not be correct
    PalmLabels = {'D1d-pr', 'P0-du', 'P4-mcp', 'P3-mcp', 'P2-mcp', ...
                  'D2p-u', 'D2p-r', 'D2m-r', 'D2m-u', 'D3m-u', 'D3m-r', ...
                  'D1d-pu', 'D4p-u', 'D4p-r', 'D4m-r', 'D4m-u', 'D5p-r', ...
                  'D5p-u', 'D5m-u', 'D5m-r', 'D1d-dr', 'P5-mcp', 'D1p-u', ...
                  'D2d-pu', 'D2d-pr', 'D2d-du', 'D3d-du','D3d-dr', ...
                  'D3d-pr', 'D4d-pu','D4d-pr', 'D4d-dr', 'D4d-du', 'D1p-r', ...
                  'D5d-pr', 'D5d-pu', 'D5d-dr', 'D1d-du', 'D2d-dr','D3d-pu', ...
                  'D3p-r', 'D3p-u', 'D5d-du', 'P0-pu', 'P0-pr', 'P0-dr', 'P0-dr', 'P0-d'};
    DorsumLabels = {'D5d-u', 'D5d-r', 'D5m','P-pr','D3m','D3d-u','D3d-r','D2p', ...
                    'D2d-u', 'D2d-r','D1d-u', 'D1d-r','D1p','D2m','D5p','P-du', ...
                    'P-pu','D4d-u', 'D4d-r','D4m','D4p','D3p', 'P-dr'};
    
    olsdata = LoadOLSData(session_path, 'SetFilter', set_ids);

    % Have to concatenate the SDO files for backwards compatibility
    try
        ols_sdo = cat(1, olsdata.SDO);
    catch
        error('Failed to concatenate sessions, this usually means other sets were included besides survey or parameter variation.')
    end

    % Filter out any surveys not done at 100 Hz, 60 uA
    ols_sdo = ols_sdo(([ols_sdo.amplitude] == 60) & ([ols_sdo.frequency] == 100));

    % Number of variable in the table (excluding channels)
    numVarTab = 12;
    % Number of cell columns in the table (must be put at the end so that
    % they get removed when doing unique)
    numVarCell = 3;

    % Iterate through each set and workout what type of survey was used
    % Assumes 4 channels, must update if this changes (c_max and column
    % titles)
    sdo_info = table('Size', [length(ols_sdo), numVarTab+c_max],...
        'VariableTypes', ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string", "string","cell", "cell", "cell"],...
        'VariableNames', ["Set", "Block", "Trial", "Rep", "NumSens", "Ch1", "Ch2", "Ch3", "Ch4", "Amp", "Freq", "SurveyType", "Date","Quality", "SkinDepth", "Comments"]);
    for j = 1:length(ols_sdo)
        if isempty(ols_sdo(j).channel)
            continue
        end

        % Determine survey type
        if strcmp(ols_sdo(j).trialType, 'ParameterVariationData') | strcmp(ols_sdo(j).trialType, 'Parameter Variation')
            sdo_info{j, "SurveyType"} = "HandMapV6";
        elseif strcmp(ols_sdo(j).trialType, 'SurveyData') % If the OLS GUI was used to record the survey
            if sum(ols_sdo(j).OLSFields.PalmLogical, 'all') + ...
               sum(ols_sdo(j).OLSFields.DorsumLogical, 'all') + ...
               sum(ols_sdo(j).OLSFields.ArmLogical, 'all') > 0
                sdo_info{j, "SurveyType"} = "OLS";
            elseif ~iscell(ols_sdo(j).Fields.PF.Palmar) || ...
                   ~iscell(ols_sdo(j).Fields.PF.Dorsum) || ...
                   ~iscell(ols_sdo(j).Fields.PF.Arm)
                sdo_info{j, "SurveyType"} = "HandMapV7";
             % This is added to cover the multi-percept case
            elseif any(~cellfun(@isempty,ols_sdo(j).Fields.PF.Palmar)) || ...
                   any(~cellfun(@isempty,ols_sdo(j).Fields.PF.Dorsum)) || ...
                   any(~cellfun(@isempty,ols_sdo(j).Fields.PF.Arm))
                sdo_info{j, "SurveyType"} = "HandMapV7";
            else
                sdo_info{j, "SurveyType"} = "NoReport";
            end
        else
            warning('Unhandled type: %s', ols_sdo(j).trialType)
        end

        sdo_info{j, "Set"} = ols_sdo(j).set;
        sdo_info{j, "Block"} = ols_sdo(j).block;
        sdo_info{j, "Trial"} = ols_sdo(j).trialID;
        sdo_info{j, "Rep"} = ols_sdo(j).rep;

        % need ols-coded electrode id for comparison
        %elec_ids(id) = elec_log.Electrode(elec_log.TrueNumber==elec_ids(id));

        channels = zeros(c_max,1);
        channels(1:length(ols_sdo(j).channel)) = ols_sdo(j).channel;
        % Converts the OLS numbering to the true electrode numbering
        sdo_info{j, "Ch1"} = elec_log.TrueNumber(elec_log.Electrode == channels(1));
        sdo_info{j, "Ch2"} = elec_log.TrueNumber(elec_log.Electrode == channels(2));
        sdo_info{j, "Ch3"} = elec_log.TrueNumber(elec_log.Electrode == channels(3));
        sdo_info{j, "Ch4"} = elec_log.TrueNumber(elec_log.Electrode == channels(4));

        sdo_info{j, "Amp"} = ols_sdo(j).amplitude;
        sdo_info{j, "Freq"} = ols_sdo(j).frequency;
        sdo_info{j, "Date"} = string(cellfun(@(c) datetime(c, 'InputFormat','dd-MMM-uuuu'), {ols_sdo(j).sessionInfo.date}),'uuuu-MM-dd');

        if ~(sdo_info{j, "SurveyType"} == "HandMapV6")

            sdo_info{j, "NumSens"} = ols_sdo(j).SensationID + 1;

            if ~isempty(ols_sdo(j).Comments)
                    sdo_info{j, "Comments"} = {ols_sdo(j).Comments};
            end
    
            if ~isempty(ols_sdo(j).Quality)
                    sdo_info{j, "Quality"} = {ols_sdo(j).Quality};
            end
    
            if ~isempty(ols_sdo(j).Location)
                    sdo_info{j, "SkinDepth"} = {ols_sdo(j).Location};
            end 
            
        else
            % For HandMapV6 the information the comments, quality, and skin
            % depth are available in the .yml files, but have not been
            % extracted systematically, so we will just extract the maps and
            % treat it as 1 non-descript sensation
            sdo_info{j, "NumSens"} = 1;
        end
    end
    
    SurveyData = struct(); ii = 1;


    % Parse the data based on survey type
    if any(strcmp(sdo_info.SurveyType, "HandMapV6"))
        temp_table = sdo_info(strcmp(sdo_info.SurveyType, "HandMapV6"), :);
        % Skips rep (at position 4) because HandMapV6 has an entry for
        % reach rep
        [unTemp unIdx ~] = unique(temp_table(:,[1:3 5:end-numVarCell]),'rows','stable');
        unique_table = temp_table(unIdx,:);
        % Find unique set:block:trial:channel (reps are used weirdly here)
        %unique_table = unique(temp_table(:, ["Set", "Block", "Trial", "NumSens", "Channel", "Date"]));
        for j = 1:height(unique_table)
            % Assign values to SurveyData
            SurveyData(ii).Subject = subject_id;
            SurveyData(ii).Date = unique_table{j,"Date"};
            SurveyData(ii).Session = log_sess;
            SurveyData(ii).Set = unique_table{j, "Set"};
            SurveyData(ii).Block = unique_table{j, "Block"};
            SurveyData(ii).Trial = unique_table{j, "Trial"};
            SurveyData(ii).Ch1 = unique_table{j, "Ch1"};
            SurveyData(ii).Ch2 = unique_table{j, "Ch2"};
            SurveyData(ii).Ch3 = unique_table{j, "Ch3"};
            SurveyData(ii).Ch4 = unique_table{j, "Ch4"};

            SurveyData(ii).NumSens = unique_table{j, "NumSens"};
            SurveyData(ii).Quality = unique_table{j, "Quality"}{:};
            SurveyData(ii).SkinDepth = unique_table{j, "SkinDepth"}{:};
            SurveyData(ii).Comments = unique_table{j, "Comments"}{:};

            SurveyData(ii).SurveyType = "HandMapV6";

            % Extract the palmar and dorsum image for that session and set
            resp_img_files = dir(fullfile(session_path, sprintf('*Resp.Set%04d.Trial%04d.*.png', unique_table.Set(j), unique_table.Trial(j))));
            resp_img_fnames = {resp_img_files.name};
            % Filter out hotspot and artifact images
            resp_img_fnames = resp_img_fnames(~cellfun(@(c) contains(c, 'Hotspot'), resp_img_fnames));
            resp_img_fnames = resp_img_fnames(~cellfun(@(c) contains(c, 'Artifact'), resp_img_fnames));

            % Get images
            image_cell = cell(size(resp_img_fnames));
            % Flag that indicates saved map
            saved_map = false;
            for k = 1:size(resp_img_fnames, 2)
                image_cell{k} = imread(fullfile(session_path, resp_img_fnames{k}));
            end
            palmer_idx = cellfun(@(c) contains(c, 'palmer'), resp_img_fnames);
            temp_palmer_pf = ExtractPFs(image_cell(palmer_idx), palmar_mask, palmar_segments);
            if size(temp_palmer_pf, 1) > 0
                % Actually checks that there is a drawn map (an empty image
                % will still be passed through HandMapV6)
                if any(~cellfun(@isempty,{temp_palmer_pf.PixelIdxList}))
                    SurveyData(ii).PalmarBoundary = {temp_palmer_pf.Boundary};
                    SurveyData(ii).PalmarIdx = {temp_palmer_pf.PixelIdxList};
                    SurveyData(ii).PalmarLoc = {temp_palmer_pf.BoundaryLocations};

                    saved_map = true;
                end
            end
            dorsum_idx = cellfun(@(c) contains(c, 'dorsum'), resp_img_fnames);
            temp_dorsum_pf = ExtractPFs(image_cell(dorsum_idx), dorsal_mask, dorsum_segments);
            if size(temp_dorsum_pf, 1) > 0
                % Actually checks that there is a drawn map (an empty image
                % will still be passed through HandMapV6)
                if any(~cellfun(@isempty,{temp_dorsum_pf.PixelIdxList}))
                    SurveyData(ii).DorsumBoundary = {temp_dorsum_pf.Boundary};
                    SurveyData(ii).DorsumIdx = {temp_dorsum_pf.PixelIdxList};
                    SurveyData(ii).DorsumLoc = {temp_dorsum_pf.BoundaryLocations};

                    saved_map = true;
                end
            end

            % If nothing is saved, this HandMapV6 entry should be marked as
            % NoReport
            if ~saved_map
                SurveyData(ii).SurveyType = "NoReport";

                % Empties
                SurveyData(ii).NumSens = [];
                SurveyData(ii).Quality = [];
                SurveyData(ii).SkinDepth = [];
                SurveyData(ii).Comments = [];
    
                SurveyData(ii).PalmarBoundary = [];
                SurveyData(ii).PalmarIdx = [];
                SurveyData(ii).PalmarLoc = [];
                SurveyData(ii).DorsumBoundary = [];
                SurveyData(ii).DorsumIdx = [];
                SurveyData(ii).DorsumLoc = [];
            end
 
            ii = ii + 1;

        end
    end

    if any(strcmp(sdo_info.SurveyType, "OLS"))
        temp_table = sdo_info(strcmp(sdo_info.SurveyType, "OLS"), :);
        [unTemp unIdx ~] = unique(temp_table(:,1:end-numVarCell),'rows','stable');
        unique_table = temp_table(unIdx,:);
        for j = 1:height(unique_table)
            j_idx = find(sdo_info.Set == unique_table{j, "Set"} & ...
                         sdo_info.Ch1 == unique_table{j, "Ch1"} & ...
                         sdo_info.Ch2 == unique_table{j, "Ch2"} & ...
                         sdo_info.Ch3 == unique_table{j, "Ch3"} & ...
                         sdo_info.Ch4 == unique_table{j, "Ch4"});
            % Assign values to SurveyData
            SurveyData(ii).Subject = subject_id;
            SurveyData(ii).Date = unique_table{j,"Date"};
            SurveyData(ii).Session = log_sess;
            SurveyData(ii).Set = unique_table{j, "Set"};
            SurveyData(ii).Block = unique_table{j, "Block"};
            SurveyData(ii).Trial = unique_table{j, "Trial"};
            SurveyData(ii).Ch1 = unique_table{j, "Ch1"};
            SurveyData(ii).Ch2 = unique_table{j, "Ch2"};
            SurveyData(ii).Ch3 = unique_table{j, "Ch3"};
            SurveyData(ii).Ch4 = unique_table{j, "Ch4"};

            SurveyData(ii).NumSens = unique_table{j, "NumSens"};
            SurveyData(ii).Quality = unique_table{j, "Quality"}{:};
            SurveyData(ii).SkinDepth = unique_table{j, "SkinDepth"}{:};
            SurveyData(ii).Comments = unique_table{j, "Comments"}{:};
            
            SurveyData(ii).SurveyType = "OLS";

            % Assign fields

            % Palmar label mapping (convert from OLS to correct): 
            palm_logical = ols_sdo(j_idx).OLSFields.PalmLogical;
            
            % Collects all the regions into one binary image
            j_mask = zeros(size(palmar_mask));
            orig_size = size(j_mask);
            segList = [];
            for pi = 1:size(palm_logical, 1)
                for pj = 1:size(palm_logical, 2)
                    if ~palm_logical(pi, pj) % Skip empty (not sure why this happens)
                        continue
                    end
                    % Get list of IDs
                    segIdx = ismember({palmar_segments.Tag}, PalmLabels{pi});
                    segTag = palmar_segments(segIdx).Tag;
                    % Assign values
                    j_mask(vertcat(palmar_segments(segIdx).PixelIdxList)) = true;
                end
            end
            % This will bridge adjacent segments (which have a 1 pixel
            % separation)
            j_mask = bwmorph(j_mask,'bridge');

            % Once all images have been processed, extract info
            pf_struct = regionprops(j_mask, 'Centroid', 'PixelIdxList', 'Area', 'Eccentricity', 'Orientation', 'FilledImage', 'BoundingBox');
            % Now iterate through regions to get more features that regionprops can't
            if isempty(pf_struct)
                [pf_struct(1).Boundary, pf_struct(1).CentroidLocation, pf_struct(1).BoundaryLocations] = deal([]);
            else
                for r = 1:length(pf_struct)
                    % Boundary
                    [B, ~, ~] = bwboundaries(pf_struct(r).FilledImage, 'noholes'); % Need to use BWBoundaries to extract boundary that's better than ConvexHull 
                    pf_struct(r).Boundary = [B{1}(:,2) + pf_struct(r).BoundingBox(1), B{1}(:,1) + pf_struct(r).BoundingBox(2)];
                    % Segment
                    overlapping_pixels = false(size(palmar_segments,1),1);
                    found_centroid = false;
                    for j = 1:size(palmar_segments,1)
                        % Any overlap
                        if any(ismember(pf_struct(r).PixelIdxList, palmar_segments(j).PixelIdxList))
                            overlapping_pixels(j) = true;
                        end
                    end
                    pf_struct(r).BoundaryLocations = {palmar_segments(overlapping_pixels).Tag};
                end
            end

            if size(pf_struct, 1) > 0
                % Actually checks that there is a drawn map
                if any(~cellfun(@isempty,{pf_struct.PixelIdxList}))
                    SurveyData(ii).PalmarBoundary = {pf_struct.Boundary};
                    SurveyData(ii).PalmarIdx = {pf_struct.PixelIdxList};
                    SurveyData(ii).PalmarLoc = {pf_struct.BoundaryLocations};
                end     
            end


            % Dorsum label mapping (convert from OLS to correct): 
            dorsum_logical = ols_sdo(j_idx).OLSFields.DorsumLogical;
            
            % Collects all the regions into one binary image
            j_mask = zeros(size(dorsal_mask));
            orig_size = size(j_mask);
            segList = [];
            for pi = 1:size(dorsum_logical, 1)
                for pj = 1:size(dorsum_logical, 2)
                    if ~dorsum_logical(pi, pj) % Skip empty (not sure why this happens)
                        continue
                    end
                    % Get list of IDs
                    segIdx = ismember({dorsum_segments.Tag}, DorsumLabels{pi});
                    segTag = dorsum_segments(segIdx).Tag;
                    % Assign values
                    j_mask(vertcat(dorsum_segments(segIdx).PixelIdxList)) = true;
                end
            end
            % This will bridge adjacent segments (which have a 1 pixel
            % separation)
            j_mask = bwmorph(j_mask,'bridge');


            % Once all images have been processed, extract info
            pf_struct = regionprops(j_mask, 'Centroid', 'PixelIdxList', 'Area', 'Eccentricity', 'Orientation', 'FilledImage', 'BoundingBox');
            % Now iterate through regions to get more features that regionprops can't
            if isempty(pf_struct)
                [pf_struct(1).Boundary, pf_struct(1).CentroidLocation, pf_struct(1).BoundaryLocations] = deal([]);
            else
                for r = 1:length(pf_struct)
                    % Boundary
                    [B, ~, ~] = bwboundaries(pf_struct(r).FilledImage, 'noholes'); % Need to use BWBoundaries to extract boundary that's better than ConvexHull 
                    pf_struct(r).Boundary = [B{1}(:,2) + pf_struct(r).BoundingBox(1), B{1}(:,1) + pf_struct(r).BoundingBox(2)];
                    % Segment
                    overlapping_pixels = false(size(dorsum_segments,1),1);
                    found_centroid = false;
                    for j = 1:size(dorsum_segments,1)
                        % Any overlap
                        if any(ismember(pf_struct(r).PixelIdxList, dorsum_segments(j).PixelIdxList))
                            overlapping_pixels(j) = true;
                        end
                    end
                    pf_struct(r).BoundaryLocations = {dorsum_segments(overlapping_pixels).Tag};
                end
            end

            if size(pf_struct, 1) > 0
                % Actually checks that there is a drawn map
                if any(~cellfun(@isempty,{pf_struct.PixelIdxList}))
                    SurveyData(ii).DorsumBoundary = {pf_struct.Boundary};
                    SurveyData(ii).DorsumIdx = {pf_struct.PixelIdxList};
                    SurveyData(ii).DorsumLoc = {pf_struct.BoundaryLocations};
                end     
            end

            % Ignoring Arm since we don't have stuff for that
            ii = ii + 1;
        end
    end

    if any(strcmp(sdo_info.SurveyType, "HandMapV7"))
        temp_table = sdo_info(strcmp(sdo_info.SurveyType, "HandMapV7"), :);
        [unTemp unIdx ~] = unique(temp_table(:,1:end-numVarCell),'rows','stable');
        unique_table = temp_table(unIdx,:);
        for j = 1:height(unique_table)
            % j_idx isn't needed because the information doesn't come from

            % Assign values to SurveyData
            SurveyData(ii).Subject = subject_id;
            SurveyData(ii).Date = unique_table{j,"Date"};
            SurveyData(ii).Session = log_sess;
            SurveyData(ii).Set = unique_table{j, "Set"};
            SurveyData(ii).Block = unique_table{j, "Block"};
            SurveyData(ii).Trial = unique_table{j, "Trial"};
            SurveyData(ii).Ch1 = unique_table{j, "Ch1"};
            SurveyData(ii).Ch2 = unique_table{j, "Ch2"};
            SurveyData(ii).Ch3 = unique_table{j, "Ch3"};
            SurveyData(ii).Ch4 = unique_table{j, "Ch4"};

            SurveyData(ii).NumSens = unique_table{j, "NumSens"};
            SurveyData(ii).Quality = unique_table{j, "Quality"}{:};
            SurveyData(ii).SkinDepth = unique_table{j, "SkinDepth"}{:};
            SurveyData(ii).Comments = unique_table{j, "Comments"}{:};

            SurveyData(ii).SurveyType = "HandMapV7";

            % Get images
            % Extract the palmar and dorsum image for that session and set
            resp_img_files = dir(fullfile(session_path, sprintf('*Resp.Set%04d.Trial%04d.*.png', ...
                unique_table.Set(j), unique_table.Trial(j))));
            resp_img_fnames = {resp_img_files.name};
            image_cell = cell(size(resp_img_fnames));
            for k = 1:size(resp_img_fnames, 2)
                image_cell{k} = imread(fullfile(session_path, resp_img_fnames{k}));
            end
            palmer_idx = cellfun(@(c) contains(c, 'palmer'), resp_img_fnames);
            temp_palmer_pf = ExtractPFs(image_cell(palmer_idx), palmar_mask, palmar_segments);
            if size(temp_palmer_pf, 1) > 0
                SurveyData(ii).PalmarBoundary = {temp_palmer_pf.Boundary};
                SurveyData(ii).PalmarIdx = {temp_palmer_pf.PixelIdxList};
                SurveyData(ii).PalmarLoc = {temp_palmer_pf.BoundaryLocations};
            end
            dorsum_idx = cellfun(@(c) contains(c, 'dorsum'), resp_img_fnames);
            temp_dorsum_pf = ExtractPFs(image_cell(dorsum_idx), dorsal_mask, dorsum_segments);
            if size(temp_dorsum_pf, 1) > 0
                SurveyData(ii).DorsumBoundary = {temp_dorsum_pf.Boundary};
                SurveyData(ii).DorsumIdx = {temp_dorsum_pf.PixelIdxList};
                SurveyData(ii).DorsumLoc = {temp_dorsum_pf.BoundaryLocations};
            end

            ii = ii + 1;
        end
    end

    if any(strcmp(sdo_info.SurveyType, "NoReport"))
        temp_table = sdo_info(strcmp(sdo_info.SurveyType, "NoReport"), :);
        [unTemp unIdx ~] = unique(temp_table(:,1:end-numVarCell),'rows','stable');
        unique_table = temp_table(unIdx,:);
        for j = 1:height(unique_table)
            % Assign values to SurveyData
            SurveyData(ii).Subject = subject_id;
            SurveyData(ii).Date = unique_table{j,"Date"};
            SurveyData(ii).Session = log_sess;
            SurveyData(ii).Set = unique_table{j, "Set"};
            SurveyData(ii).Block = unique_table{j, "Block"};
            SurveyData(ii).Trial = unique_table{j, "Trial"};
            SurveyData(ii).Ch1 = unique_table{j, "Ch1"};
            SurveyData(ii).Ch2 = unique_table{j, "Ch2"};
            SurveyData(ii).Ch3 = unique_table{j, "Ch3"};
            SurveyData(ii).Ch4 = unique_table{j, "Ch4"};
            SurveyData(ii).SurveyType = "NoReport";

            % Empties
            SurveyData(ii).NumSens = [];
            SurveyData(ii).Quality = [];
            SurveyData(ii).SkinDepth = [];
            SurveyData(ii).Comments = [];

            SurveyData(ii).PalmarBoundary = [];
            SurveyData(ii).PalmarIdx = [];
            SurveyData(ii).PalmarLoc = [];
            SurveyData(ii).DorsumBoundary = [];
            SurveyData(ii).DorsumIdx = [];
            SurveyData(ii).DorsumLoc = [];

            ii = ii + 1;
        end
    end

    if isempty(fieldnames(SurveyData))
        warning('%s has no sets that passed the filter.\n', session_str);
    elseif all([SurveyData.SurveyType]=="NoReport")
        warning('%s has no reported maps\n', session_str)
    end

    % Check if key subfolder exists, if not then make one
    if exist(fullfile(output_directory, subid), 'dir') == 0
        mkdir(fullfile(output_directory, subid))
    end

    save(fullfile(output_directory, subid, [session_str, '.mat']), "SurveyData")
    fprintf(' - Done!\n')
end