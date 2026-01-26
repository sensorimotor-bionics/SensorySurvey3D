function [target, source] = generalized_mesh_transform(...
    mesh_target, landmarks_target, mesh_source, landmarks_source,...
    primary_landmarks, accessory_landmarks, dependencies, anchor_landmark, which_side)

    %% options
    viewplot = false;
    viewfinalplot = false;    

    %% import target mesh
    if strcmp(which_side,'palmar')
        data = import_json('2D_data_palmar_dense.json');
    elseif strcmp(which_side,'dorsal')
        data = import_json('2D_data_dorsum_dense.json');
    else
        data = import_json(mesh_target);
    end

    target.verts = data.vertices;
    target.faces = data.faces;

    % data = import_json(mesh_target);
    % target2.verts = data.vertices;
    % figure
    % plot3(target2.verts(:,1),target2.verts(:,2),target2.verts(:,3),"r*")
    % axis equal
    % hold on
    % plot3(target.verts(:,1),target.verts(:,2),target.verts(:,3),"b.")
    
    %% import source mesh
    data = import_json(mesh_source);
    source.raw_verts = data.vertices;
    source.verts = data.vertices;
    source.faces = data.faces;
    
    %% import landmarks
    landmark_superset = cat(2,primary_landmarks,accessory_landmarks);
    target.landmark_report = import_json(landmarks_target);
    source.landmark_report = import_json(landmarks_source);
    source.landmarks = import_model_landmarks(source.landmark_report,landmark_superset);

    % figure
    % plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'.')
    % hold on
    % plot3(source.landmarks(:,1),source.landmarks(:,2),source.landmarks(:,3),'o')
    % axis equal

    % theta = 135;
    % Rx = [1 0 0; 0 cosd(theta) -sind(theta); 0 sind(theta) cosd(theta)];
    % Ry = [cosd(theta) 0 sind(theta); 0 1 0; -sind(theta) 0 cosd(theta)];
    % Rz = [cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1];
    % 
    % foo = source.landmarks*Rz;
    % 
    % figure
    % plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'.')
    % hold on
    % plot3(foo(:,1),foo(:,2),foo(:,3),'o')
    % axis equal

    % convert landmarks from strings to indices:
    dependencies_temp = nan(size(dependencies));
    for l = 1:length(primary_landmarks)
        dependencies_temp(dependencies==primary_landmarks{l}) = l;

        if strcmp(anchor_landmark,primary_landmarks{l})
            anchor_landmark = l;
        end
    end
    dependencies = dependencies_temp;
    target.landmarks = import_model_landmarks(target.landmark_report,landmark_superset);

    % find the long axis of the model--do pca on the xyz coords and re-plot
    [~,score] = pca([target.verts;target.landmarks],'Rows','all');
    target.landmarks = score(size(target.verts,1)+1:end,:);
    target.verts = score(1:size(target.verts,1),:);

    %% build proximity maps of mesh to keypoints
    disp('> Building proximity maps of source mesh to procrustes keypoints.')
    [apply_transform_reference, ~] = determine_dibs(source, primary_landmarks, landmark_superset, dependencies);

    %% initial procrustes alignment
    disp('> Performing initial procrustes alignment.')
    [~,source.landmarks,transform] = procrustes(target.landmarks,source.landmarks); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
    source.verts = transform.b*source.verts*transform.T+transform.c(1,:);

    [~, three_is_palmar, ~, ~] = partition_by_normals_vertex(source, viewplot);

    if strcmp(which_side,'unsided')
        [~, two_is_palmar, ~, ~] = partition_by_normals_vertex(target, viewplot);
    else
        two_is_palmar = target.verts(:,3)<-0.05;
    end

    %% iterative procrustes
    disp('> Executing iterative procrustes according to user-specified dependency tree.')
    % for any set of n keypoints, find procrustes transforms to align those keypoints
    % overlying mesh should be morphed based on proximity to present keypoints of interest
    which_dims = [1 2 3];
    source_verts_moved = zeros(size(source.verts));
    
    % first shift to match xyz positions of anchor landmark
    % overall_shift = source.landmarks(anchor_landmark,:)-target.landmarks(anchor_landmark,:);
    % source.landmarks = source.landmarks-overall_shift;
    % source.verts = source.verts-overall_shift;
    % store_verts = source.verts;
    % 
    % source.verts = store_verts;
    % which_dims = [1 2 3];

    % iterate through list of dependencies and make adjustments
    for combo = 1:size(dependencies,1)
        keypoint_combinations = dependencies(combo,:);
        all_representations = find(contains([landmark_superset{:}],[primary_landmarks{keypoint_combinations}]));
        all_representations(ismember(all_representations,keypoint_combinations)) = [];
        keypoint_combinations = [keypoint_combinations all_representations];

        [~,Z,transform] = procrustes(target.landmarks(keypoint_combinations,which_dims),source.landmarks(keypoint_combinations,which_dims),'reflection',false); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
        these_representations = find(contains([landmark_superset{:}],[primary_landmarks{keypoint_combinations(1)} primary_landmarks{keypoint_combinations(contains([landmark_superset{keypoint_combinations}],"end"))}]));
        source.landmarks(these_representations,which_dims) = Z(ismember(keypoint_combinations,these_representations),:);
        source_verts_moved(:,which_dims) = transform.b*source.verts(:,which_dims)*transform.T+transform.c(1,:);
        apply_transform = sum(apply_transform_reference(:,these_representations),2);

        % peep which vertices are transformed in this iteration:
        % figure; set(gcf,'position',[0,0,1109,600])
        % for ii = 1:size(source.verts,1)
        %     plot3(source.verts(ii,1),source.verts(ii,2),source.verts(ii,3),'.','Color',[apply_transform(ii) 0 0],'MarkerSize',50)
        %     hold on
        % end
        % view(0,-90)
        % axis(gca,'equal')
        % axis(gca,'off')
        % saveas(gcf,['combo_' char(string(combo)) '_dibs.png'])

        source_verts_temp = source.verts;
        source_verts_temp(:,which_dims) = source_verts_moved(:,which_dims).*apply_transform + source.verts(:,which_dims).*(1-apply_transform);

        % peep the planned transformation in this iteration:
        % figure; set(gcf,'position',[0,0,1500,1000])
        % plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'r.','MarkerSize',12)
        % hold on
        % plot3(source_verts_temp(:,1),source_verts_temp(:,2),source_verts_temp(:,3),'k.','MarkerSize',12)
        % % plot3(source.landmarks(:,1),source.landmarks(:,2),source.landmarks(:,3),'o')
        % % plot3(target.landmarks(:,1),target.landmarks(:,2),target.landmarks(:,3),'x')
        % axis(gca,'equal')
        % axis(gca,'off')
        % view(20,50)
        % saveas(gcf,['combo_' char(string(combo)) '_transformation.png'])

        source.verts = source_verts_temp;
    end

    %% snap-to for 3D-to-3D alignment
    if strcmp(which_side,"unsided")
        disp('> Implementing snap-to.')

        k = 2;
        abbr_palm = target.verts(two_is_palmar,:);
        abbr_dorsum = target.verts(~two_is_palmar,:);
    
        mdl_palm = createns(abbr_palm,'Distance','euclidean');
        mdl_dorsum = createns(abbr_dorsum,'Distance','euclidean');
    
        [IdxNN_palm,D_palm] = knnsearch(mdl_palm,source.verts(three_is_palmar,:),'K',k);
        [IdxNN_dorsum,D_dorsum] = knnsearch(mdl_dorsum,source.verts(~three_is_palmar,:),'K',k);
    
        temp_verts = nan([size(source.verts),k]);
        temp_D = nan([size(source.verts,1),k]);
    
        for ii = 1:k
            temp_verts(three_is_palmar,:,ii) = abbr_palm(IdxNN_palm(:,ii),:);
            temp_verts(~three_is_palmar,:,ii) = abbr_dorsum(IdxNN_dorsum(:,ii),:);
    
            temp_D(three_is_palmar,ii) = D_palm(:,ii);
            temp_D(~three_is_palmar,ii) = D_dorsum(:,ii);
        end
    
        all_dists = sum(temp_D,2);
        foo = sum(temp_verts.*repmat(permute(temp_D,[1,3,2]),[1,3,1])./repmat(all_dists,[1,3,k]),3);
        source.verts = foo;
    
        % figure
        % plot3(target.verts(two_is_palmar,1),target.verts(two_is_palmar,2),target.verts(two_is_palmar,3),'.')
        % hold on
        % plot3(target.verts(~two_is_palmar,1),target.verts(~two_is_palmar,2),target.verts(~two_is_palmar,3),'.')
        % axis equal
        % 
        % figure
        % plot3(source.verts(three_is_palmar,1),source.verts(three_is_palmar,2),source.verts(three_is_palmar,3),'.')
        % hold on
        % plot3(source.verts(~three_is_palmar,1),source.verts(~three_is_palmar,2),source.verts(~three_is_palmar,3),'.')
        % axis equal
        % 
        % figure
        % plot3(foo(:,1),foo(:,2),foo(:,3),'.')
        % axis equal
        % 
        % figure
        % shape_viewer(foo,source.faces,[1,0,0],gca)
    end

    %% assess target/source mesh alignment
    if viewfinalplot
        figure
        plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'.')
        hold on
        plot3(source.landmarks(:,1),source.landmarks(:,2),source.landmarks(:,3),'o')
        plot3(target.landmarks(:,1),target.landmarks(:,2),target.landmarks(:,3),'x')
        axis equal
    end

    % figure
    % plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'.')
    % hold on
    % plot3(source.landmarks(:,1),source.landmarks(:,2),source.landmarks(:,3),'o')
    % axis equal
    % 
    % figure
    % plot3(target.verts(:,1),target.verts(:,2),target.verts(:,3),'.')
    % hold on
    % plot3(target.landmarks(:,1),target.landmarks(:,2),target.landmarks(:,3),'o')
    % axis equal

    % figure
    % plot3(temp_verts(:,1),temp_verts(:,2),temp_verts(:,3),'.')
    % axis equal

    %% partition aligned source mesh according to normal orientations
    disp('> Partitioning into palmar and dorsal planar aspects using normals.')
    [source.oblique, source.is_palmar, source.is_dorsal, source.normals] = partition_by_normals_face(source, viewplot);
    % [target.oblique, target.is_palmar, target.is_dorsal, target.normals] = partition_by_normals_face(target, viewplot);

    %% flatten aligned source mesh according to normal orientations
    [target.verts_flat, source.verts_flat] = flatten_by_normals(target, source, landmark_superset, which_side);
end