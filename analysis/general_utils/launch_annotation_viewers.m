function Survey3DDataRecord = launch_annotation_viewers(subject,Survey3DData,axis_alignment)

    %% import 3D mesh and annotation colormaps
    Survey3DDataRecord = Survey3DData;
    idx_record = 1:length(Survey3DDataRecord);
    this_subject = find(strcmp({Survey3DData.Subject},subject)); % which rows correspond to this subject
    which_models = {Survey3DData.ModelName};
    which_models = unique(which_models(this_subject));
    
    for m = 1:length(which_models)
        mesh_source = [which_models{m} '.json'];
        landmarks_source = [which_models{m} '_procrustes_keypoints.json'];
        Survey3DData = Survey3DDataRecord(this_subject); % exclude other subjects from dataset
        this_model = find(strcmp({Survey3DData.ModelName},which_models{m})); % which rows correspond to this model
        Survey3DData = Survey3DData(this_model); % exclude other subjects from dataset
        documented_electrodes = {Survey3DData.ElectrodeID};
        unique_documented_electrodes = unique(documented_electrodes);
    
        these_idxs = idx_record(this_subject);
        these_idxs = these_idxs(this_model);
        
        % summarize annotation colormaps
        all_fields = fieldnames(Survey3DData);
        qualities = all_fields(find(strcmp(all_fields,'ModelName'))+1:end);
        annotation_record = struct();
        color_map = struct();
        
        for ele = 1:length(unique_documented_electrodes)
            this_ele = unique_documented_electrodes{ele};
            color_map.(this_ele) = [];
        end
        
        for q = 1:length(qualities)
            annotation_record.(qualities{q}) = struct();
            for ele = 1:length(unique_documented_electrodes)
                this_ele = unique_documented_electrodes{ele};
                which_rows = find(strcmp(documented_electrodes,this_ele));
                annotation_record.(qualities{q}).(this_ele) = [];
        
                for ii = 1:length(which_rows)
                    if ~isempty(Survey3DData(which_rows(ii)).(qualities{q}))
                        annotation_record.(qualities{q}).(this_ele) = cat(2, annotation_record.(qualities{q}).(this_ele), Survey3DData(which_rows(ii)).(qualities{q}).fields);
                    end
                end
        
                color_map.(this_ele) = cat(2, color_map.(this_ele), annotation_record.(qualities{q}).(this_ele));
            end
        end
        
        for ele = 1:length(unique_documented_electrodes)
            this_ele = unique_documented_electrodes{ele};
            which_map = nansum(color_map.(this_ele),2);
            which_map(which_map>0) = 1; % binary selected or not, regardless of sensation type 
            if max(which_map,[],"all")>0
                which_map = which_map./max(which_map,[],"all");
            end
    
            which_rows = find(strcmp(documented_electrodes,this_ele));
            for ii = 1:length(which_rows)
                Survey3DDataRecord(these_idxs(which_rows(ii))).ColorMap = which_map;
            end
        end
        
        %% annotation viewer
        disp(['Launching annotation viewer for model ' mesh_source '.'])
        data = import_json(mesh_source,false);
        three_dim.raw_verts = data.vertices;
        three_dim.faces = data.faces;
        
        try
            three_dim.landmark_report = import_json(landmarks_source,true);
        catch
            if contains(landmarks_source,'_gltf')
                foo = split(landmarks_source,'_gltf');
                landmarks_source = ['Survey3DLandmarks_' foo{1} '.gltf' foo{2}];
            elseif contains(landmarks_source,'_glb')
                foo = split(landmarks_source,'_glb');
                landmarks_source = ['Survey3DLandmarks_' foo{1} '.glb' foo{2}];
            end
    
            if ~contains(landmarks_source,'Survey3DLandmarks')
                landmarks_source = ['Survey3DLandmarks_' landmarks_source];
            end
            three_dim.landmark_report = import_json(landmarks_source,true);
        end

        % align short and long axes of model to some space
        if strcmp(axis_alignment,"hand_landmarks")
            axis_alignment_mod = [three_dim.landmark_report.EoW'; three_dim.landmark_report.Mend'; three_dim.landmark_report.Pend'; three_dim.landmark_report.Tend'];
        else
            axis_alignment_mod = axis_alignment;
        end

        [~,~,transform] = procrustes([0 0 0; 0 1 0; 0 0 -1; 0 0 1],axis_alignment_mod,'reflection',false); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
        three_dim.raw_verts = transform.b*three_dim.raw_verts*transform.T+transform.c(1,:);

        annotation_viewer(Survey3DData,unique_documented_electrodes,qualities,three_dim,subject,mesh_source)
       
        %% annotation viewer by row
        disp(['Launching rowwise annotation viewer for model ' mesh_source '.'])
        row_annotation_viewer(Survey3DData,qualities,three_dim,subject,mesh_source)
    end
end