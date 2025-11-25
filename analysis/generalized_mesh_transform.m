function [two_dim, three_dim] = generalized_mesh_transform(mesh_2D, landmarks_2D, mesh_3D, landmarks_3D, primary_landmarks, accessory_landmarks, dependencies, anchor_landmark, which_side)

    %% options
    viewplot = true;
    viewfinalplot = true;    

    %% import 2D mesh
    data = import_json(mesh_2D);
    two_dim.verts = data.vertices;
    two_dim.faces = data.faces;
    % region_data = import_json("2D_region_definitions.json");
    
    %% import 3D mesh
    data = import_json(mesh_3D);
    three_dim.raw_verts = data.vertices;
    three_dim.verts = data.vertices;
    three_dim.faces = data.faces;
    
    %% import landmarks
    landmark_superset = cat(2,primary_landmarks,accessory_landmarks);
    two_dim.landmark_report = import_json(landmarks_2D);
    three_dim.landmark_report = import_json(landmarks_3D);
    three_dim.landmarks = import_model_landmarks(three_dim.landmark_report,primary_landmarks);
    two_dim.landmarks = import_model_landmarks(two_dim.landmark_report,landmark_superset);

    % convert landmarks from strings to indices:
    dependencies_temp = nan(size(dependencies));
    for l = 1:length(primary_landmarks)
        dependencies_temp(dependencies==primary_landmarks{l}) = l;

        if strcmp(anchor_landmark,primary_landmarks{l})
            anchor_landmark = l;
        end
    end
    dependencies = dependencies_temp;
        
    %% build proximity maps of mesh to keypoints
    disp('> Building proximity maps of source mesh to procrustes keypoints.')
    [apply_transform_reference, ~] = determine_dibs(three_dim, primary_landmarks, landmark_superset, dependencies);

    %% initial procrustes alignment
    disp('> Performing initial procrustes alignment.')
    [~,three_dim.landmarks,transform] = procrustes(two_dim.landmarks(1:length(primary_landmarks),:),three_dim.landmarks(1:length(primary_landmarks),:)); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
    three_dim.verts = transform.b*three_dim.verts*transform.T+transform.c(1,:);

    %% auto width detection
    disp('> Performing auto width detection.')
    [width_landmarks, ~] = auto_width_detection(three_dim, primary_landmarks, accessory_landmarks, dependencies, transform);

    %% iterative procrustes
    disp('> Executing iterative procrustes according to user-specified dependency tree.')
    % for any set of n keypoints, find procrustes transforms to align those keypoints
    % overlying mesh should be morphed based on proximity to present keypoints of interest
    which_dims = [1 2 3];
    three_dim_verts_moved = zeros(size(three_dim.verts));
    
    % first shift to match xyz positions of anchor landmark
    overall_shift = three_dim.landmarks(anchor_landmark,:)-two_dim.landmarks(anchor_landmark,:);
    three_dim.landmarks = [three_dim.landmarks;width_landmarks];
    three_dim.landmarks = three_dim.landmarks-overall_shift;
    three_dim.verts = three_dim.verts-overall_shift;

    % iterate through list of dependencies and make adjustments
    for combo = 1:size(dependencies,1)
        keypoint_combinations = dependencies(combo,:);
        all_representations = find(contains([landmark_superset{:}],[primary_landmarks{keypoint_combinations}]));
        all_representations(ismember(all_representations,keypoint_combinations)) = [];
        keypoint_combinations = [keypoint_combinations all_representations];

        [~,Z,transform] = procrustes(two_dim.landmarks(keypoint_combinations,which_dims),three_dim.landmarks(keypoint_combinations,which_dims),'reflection',false); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
        these_representations = find(contains([landmark_superset{:}],[primary_landmarks{keypoint_combinations(1)} primary_landmarks{keypoint_combinations(contains([landmark_superset{keypoint_combinations}],"end"))}]));
        three_dim.landmarks(these_representations,which_dims) = Z(ismember(keypoint_combinations,these_representations),:);
        three_dim_verts_moved(:,which_dims) = transform.b*three_dim.verts(:,which_dims)*transform.T+transform.c(1,:);
        apply_transform = sum(apply_transform_reference(:,these_representations),2);

        % peep which vertices are transformed in this iteration:
        % figure
        % for ii = 1:size(three_dim.verts,1)
        %     plot3(three_dim.verts(ii,1),three_dim.verts(ii,2),three_dim.verts(ii,3),'.','Color',[0 0 apply_transform(ii)])
        %     hold on
        % end
        % axis equal

        three_dim_verts_temp = three_dim.verts;
        three_dim_verts_temp(:,which_dims) = three_dim_verts_moved(:,which_dims).*apply_transform + three_dim.verts(:,which_dims).*(1-apply_transform);

        % peep the planned transformation in this iteration:
        % figure
        % plot3(three_dim.verts(:,1),three_dim.verts(:,2),three_dim.verts(:,3),'.')
        % hold on
        % plot3(three_dim_verts_temp(:,1),three_dim_verts_temp(:,2),three_dim_verts_temp(:,3),'*')
        % plot3(three_dim.landmarks(:,1),three_dim.landmarks(:,2),three_dim.landmarks(:,3),'o')
        % plot3(two_dim.landmarks(:,1),two_dim.landmarks(:,2),two_dim.landmarks(:,3),'x')
        % axis equal

        three_dim.verts = three_dim_verts_temp;
    end

    %% assess 2D/3D mesh alignment
    if viewfinalplot
        figure
        plot3(three_dim.verts(:,1),three_dim.verts(:,2),three_dim.verts(:,3),'.')
        hold on
        plot3(three_dim.landmarks(:,1),three_dim.landmarks(:,2),three_dim.landmarks(:,3),'o')
        plot3(two_dim.landmarks(:,1),two_dim.landmarks(:,2),two_dim.landmarks(:,3),'x')
        axis equal
    end

    %% partition aligned 3D mesh according to normal orientations
    disp('> Partitioning into palmar and dorsal planar aspects using normals.')
    [three_dim.oblique, three_dim.is_palmar, three_dim.is_dorsal, three_dim.normals] = partition_by_normals(three_dim, viewplot);

    %% flatten aligned 3D mesh according to normal orientations
    [two_dim.verts_flat, three_dim.verts_flat] = flatten_by_normals(two_dim, three_dim, which_side);
end