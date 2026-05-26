function launch_annotation_viewers(subject,Survey3DDataAll,axis_alignment)

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

        %% annotation viewer (simple viewer without alignment and procrustes)
        
        data = Survey3DData(1).Model;
        three_dim.raw_verts = data.vertices;
        three_dim.faces = data.faces;

        disp(['Launching annotation viewer for model ' mesh_source '.'])
        annotation_viewer(Survey3DData,unique_documented_electrodes,qualities,three_dim,subject,mesh_source)

        disp(['Launching rowwise annotation viewer for model ' mesh_source '.'])
        row_annotation_viewer(Survey3DData,qualities,three_dim,subject,mesh_source)

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