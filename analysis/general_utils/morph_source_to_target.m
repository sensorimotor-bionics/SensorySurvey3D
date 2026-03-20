function MorphedMeshes = morph_source_to_target(Survey3DDataRecord,conform_to_2D_illustration,primary_landmarks,accessory_landmarks,dependencies,anchor_landmark)
    %% identify your target mesh
    % identify mesh and landmark files for target 
    
    if conform_to_2D_illustration
        disp('Conforming to default 2D hand illustrations.')
        mesh_target = "2D_mesh_data.json";
        landmarks_target_palmar = "2D_model_procrustes_keypoints_palm_tight.json";
        landmarks_target_dorsum = "2D_model_procrustes_keypoints_dorsum_tight.json";
    else
        [file,location] = uigetfile('*.json','Select target mesh file','.\mesh_utils\');
        mesh_target = fullfile(location,file);
        [file,location] = uigetfile('*.json','Select target landmark file','.\mesh_utils\');
        landmarks_target = fullfile(location,file);
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
            [two_dim,three_dim] = generalized_mesh_transform(mesh_target,landmarks_target_palmar,mesh_source,landmarks_source,...
                primary_landmarks,accessory_landmarks,dependencies,anchor_landmark,"palmar");
            disp(' ')
            disp('Computing dorsal aspect.')
            [~,three_dim_dorsum] = generalized_mesh_transform(mesh_target,landmarks_target_dorsum,mesh_source,landmarks_source,...
                primary_landmarks,accessory_landmarks,dependencies,anchor_landmark,"dorsal");
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
            [two_dim,three_dim] = generalized_mesh_transform(mesh_target,landmarks_target,mesh_source,landmarks_source,...
                primary_landmarks,accessory_landmarks,dependencies,anchor_landmark,"unsided");
            three_dim_dorsum = [];
        end

        MorphedMeshes(m).TwoDim = two_dim;
        MorphedMeshes(m).ThreeDim = three_dim;
        MorphedMeshes(m).ThreeDimDorsum = three_dim_dorsum;
    end
end