function [target, source] = generalized_mesh_transform(...
    mesh_target, landmarks_target, mesh_source, landmarks_source,...
    primary_landmarks, accessory_landmarks, dependencies, anchor_landmark, which_side)

    %% options
    viewplot = false;
    viewfinalplot = false;    

    %% import target mesh
    if strcmp(which_side,'palmar')
        data = import_json('2D_data_palmar_dense.json',false);
    elseif strcmp(which_side,'dorsal')
        data = import_json('2D_data_dorsum_dense.json',false);
    else
        data = import_json(mesh_target,false);
    end

    target.verts = data.vertices;
    target.faces = data.faces;
    
    %% import source mesh
    data = import_json(mesh_source,false);
    source.raw_verts = data.vertices;
    source.verts = data.vertices;
    source.faces = data.faces;
    
    %% import landmarks
    landmark_superset = cat(2,primary_landmarks,accessory_landmarks);
    target.landmark_report = import_json(landmarks_target,true);
    source.landmark_report = import_json(landmarks_source,true);
    source.landmarks = import_model_landmarks(source.landmark_report,landmark_superset);

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

        k = 10;
        faces_pos_source = incenter(triangulation(source.faces+1,source.verts));
        faces_pos_target = incenter(triangulation(target.faces+1,target.verts));
        face_normals_target = faceNormal(triangulation(target.faces+1,target.verts));

        % make a kd tree out of source locations
        mdl_all = createns(faces_pos_source,'Distance','euclidean');

        % for each face in target, find k nearest faces in source
        [IdxNN_all,~] = knnsearch(mdl_all,faces_pos_target,'K',k);

        % have a matrix that is all target verts x all source verts
        % should begin as all zeros
        coverage_transfer_matrix = zeros(size(target.verts,1),size(source.verts,1));
        
        % parse the locations of the target face verts and source face verts for those k nearest faces
        for ii = 1:size(faces_pos_target,1)
            these_verts_target = target.verts(target.faces(ii,:)+1,:);
            this_normal_target = face_normals_target(ii,:);
            these_verts_source = [];

            for iii = 1:k
                % dim 1 is vertex of face, dim 2 is xyz location, dim 3 is proximity order
                these_verts_source = cat(3,these_verts_source,source.verts(source.faces(IdxNN_all(ii,iii),:)+1,:));
            end

            these_verts_source_rezeroed = these_verts_source - repmat(faces_pos_target(ii,:),[3,1,k]);
            these_verts_target_rezeroed = these_verts_target - repmat(faces_pos_target(ii,:),[3,1]); % zero to face loc for rot

            % shift target normal to unit vector along z
            [~,~,transform] = procrustes([0,0,0,;0,0,1],[0,0,0;this_normal_target],'reflection',false); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
            
            for idx = 1:3
                % rotate verts of target face by this transform
                these_verts_target_rezeroed(idx,:) = these_verts_target_rezeroed(idx,:)*transform.T;

                % rotate verts of source faces by this transform
                for iii = 1:k
                    these_verts_source_rezeroed(idx,:,iii) = these_verts_source_rezeroed(idx,:,iii)*transform.T;
                end
            end

            % zero z component of source verts, as that is our perspective view
            these_verts_source_rezeroed(:,3,:) = 0;

            % compute total area of target face
            target_area = polyarea(these_verts_target_rezeroed(:,1),these_verts_target_rezeroed(:,2));
            
            % compute area of overlap of each source face with target face
            for iii = 1:k
                poly1 = polyshape(these_verts_source_rezeroed(:,1,iii),these_verts_source_rezeroed(:,2,iii));
                poly2 = polyshape(these_verts_target_rezeroed(:,1),these_verts_target_rezeroed(:,2));
                polyout = intersect(poly1,poly2);
                if polyout.NumRegions==1
                    % if colormaps are face maps...
                    % coverage_transfer_matrix(ii,IdxNN_all(ii,iii)+1) = polyarea(polyout.Vertices(:,1),polyout.Vertices(:,2))/target_area; % at (target face, source face), place percentage coverage
                
                    % colormaps are vertex maps; each vertex in target face has to be mapped to source face vertices
                    coverage_transfer_matrix(target.faces(ii,:)+1,source.faces(IdxNN_all(ii,iii),:)+1) = polyarea(polyout.Vertices(:,1),polyout.Vertices(:,2))/target_area; % at (target face, source face), place percentage coverage
                end
            end
        end

        source.morph_to_verts = target.verts;
        source.morph_to_faces = target.faces;
        source.coverage_transfer_matrix = coverage_transfer_matrix;
    end

    %% assess target/source mesh alignment
    if viewfinalplot
        figure
        plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'.')
        hold on
        plot3(source.landmarks(:,1),source.landmarks(:,2),source.landmarks(:,3),'o')
        plot3(target.landmarks(:,1),target.landmarks(:,2),target.landmarks(:,3),'x')
        axis equal
        plot3(target.verts(:,1),target.verts(:,2),target.verts(:,3),'.')
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

    %% partition aligned source mesh according to normal orientations
    disp('> Partitioning into palmar and dorsal planar aspects using normals.')
    [source.oblique, source.is_palmar, source.is_dorsal, source.normals] = partition_by_normals_face(source, viewplot);
    [target.oblique, target.is_palmar, target.is_dorsal, target.normals] = partition_by_normals_face(target, viewplot);

    %% flatten aligned source mesh according to normal orientations
    if ~strcmp(which_side,"unsided")
        [target.verts_flat, source.verts_flat] = flatten_by_normals(target, source, landmark_superset, which_side);
    end
end