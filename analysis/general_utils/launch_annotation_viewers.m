function launch_annotation_viewers(subject,Survey3DDataAll,axis_alignment,type,mode)
% This function will launch the annotation viewers for the provided data
% (Survey3DDataAll). The annotation viewer shows the data for each
% electrode (or set of electrodes). It also allows you to toggle on/off
% different qualities. The row annotation viewer plots each survey (one
% set) separately. Type is used to select which of these viewers the user
% requests ('a' for annotation, 'r' for row annotation, 'ar' for both).
% Mode is what type of plot is used ('bin' for binary or 'freq' for
% frequency). It will check that the data provided matches the requested
% viewer (for example consolidated electrode data can't be used in the row
% annotation viewer, and frequency information is only provided by
% consolidated electrode data). The data is filtered by subject.

    rowAnnValid = true;

    if contains(type,'r')
        if ~isfield(Survey3DDataAll,'Session')
            warning('The survey data provided looks like it has been consolidated, so the rowwise annotation viewer will not be launched');
            rowAnnValid = false;
        end
    end
    if contains(mode,'freq')
        if ~isfield(Survey3DDataAll,'FreqMap')
            warning('The survey data provided looks like it has not been consolidated, so frequency maps are not available and the annotation viewers will not be launched.');
            return;
        end
    end

    %% import 3D mesh and annotation colormaps
    Survey3DDataRef = Survey3DDataAll;
    this_subject = find(strcmp({Survey3DDataAll.Subject},subject)); % which rows correspond to this subject
    which_models = {Survey3DDataAll.ModelName};
    which_models = unique(which_models(this_subject));
    qualities = fieldnames(Survey3DDataAll(1).PFQualities);
    
    for m = 1:length(which_models)
        if which_models{m} == "No_Report"
            continue
        end
        mesh_source = [which_models{m} '.json'];
        landmarks_source = [which_models{m} '_procrustes_keypoints.json'];
        Survey3DData = Survey3DDataRef(this_subject); % exclude other subjects from dataset
        this_model = find(strcmp({Survey3DData.ModelName},which_models{m})); % which rows correspond to this model
        empty_model = find(strcmp({Survey3DData.ModelName},"No_Report")); % which rows correspond to this empty data (which can be used for any model)
        this_data = [this_model empty_model];
        Survey3DData = Survey3DData(this_data);
        documented_electrodes = {Survey3DData.ElectrodeID};
        unique_documented_electrodes = unique(documented_electrodes);

        elec_split = squeeze(split(unique_documented_electrodes,'_'));
        % Make sure that the dimension is right (if there is only one
        % unique electrode
        if length(unique_documented_electrodes) == 1
            elec_split = elec_split';
        end
        elec_list = cellfun(@str2num,elec_split(:,2:end));
        [~, sort_idx] = sortrows(elec_list);
        sorted_elec = unique_documented_electrodes(:,sort_idx);

        %% annotation viewer (simple viewer without alignment and procrustes)
        
        data = Survey3DData(1).Model;
        three_dim.raw_verts = data.vertices;
        three_dim.faces = data.faces;

        if contains(type,'a')
            disp(['Launching annotation viewer for model ' mesh_source '.'])
            annotation_viewer(Survey3DData,sorted_elec,qualities,three_dim,subject,mesh_source,mode)
        end

        if contains(type,'r') & rowAnnValid
            disp(['Launching rowwise annotation viewer for model ' mesh_source '.'])
            row_annotation_viewer(Survey3DData,qualities,three_dim,subject,mesh_source)
        end

        %% annotation viewer (use for alignment and procrustes)
        % disp(['Launching annotation viewer for model ' mesh_source '.'])
        % data = Survey3DData(1).Model;
        % three_dim.raw_verts = data.vertices;
        % three_dim.faces = data.faces;
        % 
        % try
        %     three_dim.landmark_report = import_json(landmarks_source,true);
        % catch
        %     if contains(landmarks_source,'_gltf')
        %         foo = split(landmarks_source,'_gltf');
        %         landmarks_source = ['Survey3DLandmarks_' foo{1} '.gltf' foo{2}];
        %     elseif contains(landmarks_source,'_glb')
        %         foo = split(landmarks_source,'_glb');
        %         landmarks_source = ['Survey3DLandmarks_' foo{1} '.glb' foo{2}];
        %     end
        % 
        %     if ~contains(landmarks_source,'Survey3DLandmarks')
        %         landmarks_source = ['Survey3DLandmarks_' landmarks_source];
        %     end
        %     three_dim.landmark_report = import_json(landmarks_source,true);
        % end
        % 
        % % align short and long axes of model to some space
        % if strcmp(axis_alignment,"hand_landmarks")
        %     axis_alignment_mod = [three_dim.landmark_report.EoW'; three_dim.landmark_report.Mend'; three_dim.landmark_report.Pend'; three_dim.landmark_report.Tend'];
        % else
        %     axis_alignment_mod = axis_alignment;
        % end
        % 
        % [~,~,transform] = procrustes([0 0 0; 0 1 0; 0 0 -1; 0 0 1],axis_alignment_mod,'reflection',false); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
        % three_dim.raw_verts = transform.b*three_dim.raw_verts*transform.T+transform.c(1,:);
        % 
        % annotation_viewer(Survey3DData,unique_documented_electrodes,qualities,three_dim,subject,mesh_source)
        % 
        % % annotation viewer by row
        % disp(['Launching rowwise annotation viewer for model ' mesh_source '.'])
        % row_annotation_viewer(Survey3DData,qualities,three_dim,subject,mesh_source)
    end
end