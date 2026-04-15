function MorphedMeshes = morph_source_to_target(Survey3DDataRecord,conform_to_2D_illustration,primary_landmarks,accessory_landmarks,dependencies,anchor_landmark)
    %% identify your target mesh
    % identify mesh and landmark files for target 
    
    if conform_to_2D_illustration
        disp(' ')
        disp('Conforming to default 2D hand illustrations.')
        mesh_target = "2D_mesh_data.json";
        landmarks_target_palmar = "2D_model_procrustes_keypoints_palm_tight.json";
        landmarks_target_dorsum = "2D_model_procrustes_keypoints_dorsum_tight.json";
    else
        [file,location] = uigetfile('*.json','Select target mesh file','.\mesh_utils\');
        mesh_target = fullfile(location,file);
        [file,location] = uigetfile('*.json','Select target landmark file','.\mesh_utils\');
        landmarks_target = fullfile(location,file);

        % define primary and short axes of target model
        landmark_report = import_json(landmarks_target,true);
        try
            axis_alignment = [landmark_report.EoW'; landmark_report.Mend'; landmark_report.Pend'; landmark_report.Tend'];
            axis_alignment = "hand_landmarks";
        catch
            disp(' ')
            disp('In order to perform a simple perspective adjustment, we need to know a bit more about your model.')
            bottom_most = input("> Enter bottom-most landmark name: ","s");
            top_most = input("> Enter top-most landmark name: ","s");
            left_most = input("> Enter left-most landmark name: ","s");
            right_most = input("> Enter right-most landmark name: ","s");
            axis_alignment = [landmark_report.(bottom_most)'; landmark_report.(top_most)'; landmark_report.(left_most)'; landmark_report.(right_most)'];
        end
    end

    % identify the source mesh(es)
    which_models = {Survey3DDataRecord.ModelName};
    which_models = unique(which_models);
    MorphedMeshes = struct();

    for m = 1:length(which_models)
        mesh_source = [which_models{m} '.json'];
        landmarks_source = [which_models{m} '_procrustes_keypoints.json'];
        MorphedMeshes(m).ModelName = which_models{m};
        
        %% transform source mesh to target mesh
        disp(' ')
        disp('Fitting source mesh to target mesh.')
        disp(' ')
        if conform_to_2D_illustration
            % need to complete separate processing of the dorsum image as dorsum and palm 2D illustrations are not symmetric
            disp('Computing palmar aspect.')
            [target,source] = generalized_mesh_transform(mesh_target,landmarks_target_palmar,mesh_source,landmarks_source,...
                primary_landmarks,accessory_landmarks,dependencies,anchor_landmark,"palmar","hand_landmarks");
            disp(' ')
            disp('Computing dorsal aspect.')
            [~,sourceDorsum] = generalized_mesh_transform(mesh_target,landmarks_target_dorsum,mesh_source,landmarks_source,...
                primary_landmarks,accessory_landmarks,dependencies,anchor_landmark,"dorsal","hand_landmarks");
        else
            % dorsum and palm illustrations are symmetric or morphing one 3D mesh to another 3D mesh
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

            [target,source] = generalized_mesh_transform(mesh_target,landmarks_target,mesh_source,landmarks_source,...
                primary_landmarks,accessory_landmarks,dependencies,anchor_landmark,"unsided",axis_alignment);
            sourceDorsum = [];
        end

        MorphedMeshes(m).target = target;
        MorphedMeshes(m).source = source;
        MorphedMeshes(m).sourceDorsum = sourceDorsum;
    end
end