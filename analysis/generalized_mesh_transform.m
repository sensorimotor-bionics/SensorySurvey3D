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

    % data = import_json(mesh_target,false);
    % target2.verts = data.vertices;
    % figure
    % plot3(target2.verts(:,1),target2.verts(:,2),target2.verts(:,3),"r*")
    % axis equal
    % hold on
    % plot3(target.verts(:,1),target.verts(:,2),target.verts(:,3),"b.")
    
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

    % if strcmp(which_side,"unsided")
    %     [apply_transform_reference_target, dibs_target] = determine_dibs(target, primary_landmarks, landmark_superset, dependencies);
    % end

    % find the long axis of the model--do pca on the xyz coords and re-plot
    [~,score] = pca([target.verts;target.landmarks],'Rows','all');
    target.landmarks = score(size(target.verts,1)+1:end,:);
    target.verts = score(1:size(target.verts,1),:);

    %% build proximity maps of mesh to keypoints
    disp('> Building proximity maps of source mesh to procrustes keypoints.')
    [apply_transform_reference, dibs_source] = determine_dibs(source, primary_landmarks, landmark_superset, dependencies);

    %% initial procrustes alignment
    disp('> Performing initial procrustes alignment.')
    [~,source.landmarks,transform] = procrustes(target.landmarks,source.landmarks); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
    source.verts = transform.b*source.verts*transform.T+transform.c(1,:);

    % [source_is_oblique, source_is_palmar, ~, source_normals] = partition_by_normals_vertex(source, viewplot);
    % 
    % if strcmp(which_side,'unsided')
    %     [target_is_oblique, target_is_palmar, ~, target_normals] = partition_by_normals_vertex(target, viewplot);
    % else
    %     target_is_palmar = target.verts(:,3)<-0.05;
    % end

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

    % figure; set(gcf,'position',[0,0,1500,1000])
    % plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'k.','MarkerSize',12)
    % axis(gca,'equal')
    % axis(gca,'off')
    % view(20,50)
    % saveas(gcf,['source_before_procrustes.png'])
    % 
    % figure; set(gcf,'position',[0,0,1500,1000])
    % plot3(target.verts(:,1),target.verts(:,2),target.verts(:,3),'k.','MarkerSize',12)
    % axis(gca,'equal')
    % axis(gca,'off')
    % view(20,50)
    % saveas(gcf,['target_before_procrustes.png'])

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
        % abbr_all = source.verts;

        faces_pos_source = incenter(triangulation(source.faces+1,source.verts));
        face_normals_source = faceNormal(triangulation(source.faces+1,source.verts));
        faces_pos_target = incenter(triangulation(target.faces+1,target.verts));
        face_normals_target = faceNormal(triangulation(target.faces+1,target.verts));

        % make a kd tree out of source locations
        mdl_all = createns(faces_pos_source,'Distance','euclidean');

        % for each face in target, find k nearest faces in source
        [IdxNN_all,D_all] = knnsearch(mdl_all,faces_pos_target,'K',k);

        % have a matrix that is all target faces x all source faces
        % should begin as all zeros
        % at (target face, source face), place percentage coverage
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

             % zero z component of source verts, as that is my perspective view
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

        % now, need to output coverage transfer matrix
        % could store as sparse matrix if necessary?
        % for any annotation that you want to plot, gonna have to multiply
        % projected field with coverage transfer matrix per row
        % then, sum over rows to determine coverage
        % threshold at 50% for a new map

        % 
        % % 
        % % temp_face_pos = nan([size(faces_pos_source,1),3,k]);
        % % temp_norms = nan([size(faces_pos_source,1),3,k]);
        % % 
        % % temp_face_v1 = nan([size(faces_pos_source,1),3,k]);
        % % temp_face_v2 = nan([size(faces_pos_source,1),3,k]);
        % % temp_face_v3 = nan([size(faces_pos_source,1),3,k]);
        % % 
        % % for ii = 1:k
        % %     temp_face_pos(:,:,ii) = faces_pos_target(IdxNN_all(:,ii),:); % positions of nearest vertices in target
        % % 
        % %     temp_norms(:,:,ii) = face_normals_target(IdxNN_all(:,ii),:); % positions of nearest vertices in target
        % % 
        % %     temp_face_v1(:,:,ii) = target.verts(target.faces(IdxNN_all(:,ii),1)+1,:);
        % %     temp_face_v2(:,:,ii) = target.verts(target.faces(IdxNN_all(:,ii),2)+1,:);
        % %     temp_face_v3(:,:,ii) = target.verts(target.faces(IdxNN_all(:,ii),3)+1,:);
        % % end
        % % 
        % % temp_faces_final = nan(size(temp_face_pos,1),3);
        % % temp_face_v1_final = nan(size(temp_face_pos,1),3);
        % % temp_face_v2_final = nan(size(temp_face_pos,1),3);
        % % temp_face_v3_final = nan(size(temp_face_pos,1),3);
        % % 
        % % for iii = 1:size(temp_face_pos,1)
        % %     dots = nan(k,1);
        % %     for ii = 1:k
        % %         dots(ii) = dot(face_normals_source(iii,:),temp_norms(iii,:,ii));
        % %     end
        % %     temp_faces_final(iii,:) = temp_face_pos(iii,:,find(dots==max(dots),1,'first'));
        % % 
        % %     temp_face_v1_final(iii,:) = temp_face_v1(iii,:,find(dots==max(dots),1,'first'));
        % %     temp_face_v2_final(iii,:) = temp_face_v2(iii,:,find(dots==max(dots),1,'first'));
        % %     temp_face_v3_final(iii,:) = temp_face_v3(iii,:,find(dots==max(dots),1,'first'));
        % % end
        % % 
        % % face_shifts = temp_faces_final-faces_pos_source;
        % % 
        % % % for each face in this, need to shift all three vertices appropriately
        % % 
        % % for f = 1:size(face_shifts,1)
        % %     for v = 1:3
        % %         % right now, shifting by face pos
        % %         % abbr_all(source.faces(f,v)+1,:) = abbr_all(source.faces(f,v)+1,:)+face_shifts(f,:);
        % % 
        % %         if v==1
        % %             abbr_all(source.faces(f,v)+1,:) = temp_face_v1_final(f,:);
        % %         elseif v==2
        % %             abbr_all(source.faces(f,v)+1,:) = temp_face_v2_final(f,:);
        % %         elseif v==3
        % %             abbr_all(source.faces(f,v)+1,:) = temp_face_v3_final(f,:);
        % %         end
        % % 
        % %         % also shift individual vertices 
        % %     end
        % % end
        % % 
        % % 
        % % % for each face, I've documented verts 1, 2, and 3
        % % % I don't think the order super matters?
        % % % need to reconstitute...
        % % 
        % % % counter rotates faces to match normals
        % % 
        % % % could procrustes each face into place
        % % % would need to hierarchically reassign v1/v2/v3 IDs based on proximity
        % % % each vertex moves to the spot of its closest match within the 3...
        % % 
        % % foo = abbr_all;
        % % 
        % % iii = 2;
        % % 
        % % figure
        % % hold on
        % % plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'.')
        % % axis equal
        % % plot3(target.verts(:,1),target.verts(:,2),target.verts(:,3),'.')
        % % plot3(squeeze(temp_face_pos(iii,1,:)),squeeze(temp_face_pos(iii,2,:)),squeeze(temp_face_pos(iii,3,:)),'bx')
        % % plot3(source.verts(iii,1),source.verts(iii,2),source.verts(iii,3),'rx')
        % % plot3(foo(iii,1),foo(iii,2),foo(iii,3),'gx')
        % 
        % % visualizations for paper
        % % figure
        % % shape_viewer(source.verts,source.faces,[1,0,0],gca)
        % 
        % figure; set(gcf,'position',[0,0,1500,1000])
        % plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'k.','MarkerSize',12)
        % axis(gca,'equal')
        % axis(gca,'off')
        % view(20,50)
        % saveas(gcf,['source_after_procrustes.png'])
        % 
        % k = 1;
        % temp_verts = nan([size(source.verts),k]);
        % temp_norms = nan([size(source.verts),k]);
        % temp_D = nan([size(source.verts,1),k]);
        % % temp_D_angle = nan([size(source.verts,1),k]);
        % % all_dibs = unique(dibs_source);
        % 
        % for d = 1:size(apply_transform_reference_target,2)
        % % for d = 1:length(all_dibs)
        % 
        %     % this_region_source = dibs_source == all_dibs(d);
        %     % this_region_target = dibs_target == all_dibs(d);
        %     this_region_source = apply_transform_reference(:,d)>0;
        %     this_region_target = apply_transform_reference_target(:,d)>0;
        % 
        %     abbr_palm = target.verts((target_is_palmar|target_is_oblique)&this_region_target,:);
        %     abbr_dorsum = target.verts((~target_is_palmar|target_is_oblique)&this_region_target,:);
        % 
        %     abbr_palm_norm = target_normals((target_is_palmar|target_is_oblique)&this_region_target,:);
        %     abbr_dorsum_norm = target_normals((~target_is_palmar|target_is_oblique)&this_region_target,:);
        % 
        %     mdl_palm = createns(abbr_palm,'Distance','euclidean');
        %     mdl_dorsum = createns(abbr_dorsum,'Distance','euclidean');
        % 
        %     % NSMethod must be "exhaustive"
        %     % "Distance" must be a function
        % 
        %     % temp_verts = nan([size(source.verts),k]);
        % 
        %     % for ii = 1:length(source_is_palmar)
        %     %     this_vert = source.verts(ii,:);
        %     %     this_normal = source_normals(ii,:);
        %     % 
        %     %     if source_is_palmar(ii) % check in palmar group
        %     %         try
        %     %             mdl_palm = createns(abbr_palm-this_vert,'NSMethod','exhaustive','Distance',@dotprod);
        %     %             [IdxNN_palm,~] = knnsearch(mdl_palm,this_normal,'K',k);
        %     % 
        %     %             % figure
        %     %             % hold on
        %     %             % plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'.')
        %     %             % axis equal
        %     %             % plot3(target.verts(:,1),target.verts(:,2),target.verts(:,3),'.')
        %     %             % plot3(abbr_palm(IdxNN_palm,1),abbr_palm(IdxNN_palm,2),abbr_palm(IdxNN_palm,3),'bx')
        %     %             % plot3(source.verts(end,1),source.verts(end,2),source.verts(end,3),'rx')
        %     % 
        %     %             % smallest distance of these
        %     %             % target.verts
        %     % 
        %     %             foo = vecnorm((abbr_palm(IdxNN_palm,:)-this_vert)')';
        %     %             IdxNN_palm = IdxNN_palm(find(foo==min(foo),1,'first'));
        %     %             temp_verts(ii,:) = abbr_palm(IdxNN_palm,:);
        %     %         catch
        %     %         end
        %     %     else % check in dorsal group
        %     %         try
        %     %             mdl_dorsum = createns(abbr_dorsum-this_vert,'NSMethod','exhaustive','Distance',@dotprod);
        %     %             [IdxNN_dorsum,~] = knnsearch(mdl_dorsum,this_normal,'K',k);
        %     % 
        %     %             foo = vecnorm((abbr_dorsum(IdxNN_dorsum,:)-this_vert)')';
        %     %             IdxNN_dorsum = IdxNN_dorsum(find(foo==min(foo),1,'first'));
        %     %             temp_verts(ii,:) = abbr_dorsum(IdxNN_dorsum,:);
        %     %         catch
        %     %         end
        %     %     end
        %     % end
        %     % 
        %     % foo = temp_verts;
        % 
        %     [IdxNN_palm,D_palm] = knnsearch(mdl_palm,[source.verts(source_is_palmar&this_region_source,:)],'K',k);
        %     [IdxNN_dorsum,D_dorsum] = knnsearch(mdl_dorsum,[source.verts(~source_is_palmar&this_region_source,:)],'K',k);
        % 
        %     for ii = 1:k
        %         try
        %             temp_verts(source_is_palmar&this_region_source,:,ii) = abbr_palm(IdxNN_palm(:,ii),:); % positions of nearest vertices in target
        %             temp_norms(source_is_palmar&this_region_source,:,ii) = abbr_palm_norm(IdxNN_palm(:,ii),:); % normals of the target for nearest vertices
        %             temp_D(source_is_palmar&this_region_source,ii) = D_palm(:,ii); % distances between source vertex and nearest target vertices
        %         catch
        %         end
        %         try
        %             temp_verts(~source_is_palmar&this_region_source,:,ii) = abbr_dorsum(IdxNN_dorsum(:,ii),:);
        %             temp_norms(~source_is_palmar&this_region_source,:,ii) = abbr_dorsum_norm(IdxNN_dorsum(:,ii),:);
        %             temp_D(~source_is_palmar&this_region_source,ii) = D_dorsum(:,ii);
        %         catch
        %         end
        %     end
        % end
        % 
        % % for ii = 1:k
        % %     temp_D_angle(:,ii) = acosd(dot(source_normals,temp_norms(:,:,ii),2)./(vecnorm(source_normals')'.*vecnorm(temp_norms(:,:,ii)')')); % source_normals vs temp_norms % angles between source normal and nearest target normals
        % % end
        % 
        % all_dists = sum(temp_D,2);
        % foo = sum(temp_verts.*repmat(permute(temp_D,[1,3,2]),[1,3,1])./repmat(all_dists,[1,3,k]),3);
        % 
        % % of the closest ones, which have the most similar normal?
        % % find_min = temp_D_angle==repmat(min(temp_D_angle,[],2),[1,k]);
        % % foo = zeros(size(find_min,1),3);
        % % 
        % % for ii = 1:size(find_min,1)
        % %     foo(ii,:) = temp_verts(ii,:,find(find_min(ii,:),1,'first'));
        % % end
        % 
        % source.verts = foo;
        % 
        % figure; set(gcf,'position',[0,0,1500,1000])
        % plot3(source.verts(:,1),source.verts(:,2),source.verts(:,3),'k.','MarkerSize',12)
        % axis(gca,'equal')
        % axis(gca,'off')
        % view(20,50)
        % saveas(gcf,['source_after_snapto.png'])
        % 
        % % figure
        % % plot3(foo(:,1),foo(:,2),foo(:,3),'.')
        % % axis equal
        % % 
        % % figure
        % % shape_viewer(foo,source.faces,[1,0,0],gca)
        % 
        % % figure
        % % shape_viewer(source.verts,source.faces,[1,0,0],gca)
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

    % figure
    % plot3(temp_verts(:,1),temp_verts(:,2),temp_verts(:,3),'.')
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

function D2 = dotprod(XI,XJ)
    for ii = 1:size(XJ,1)
        D2(ii) = acosd(dot(XI,XJ(ii,:))./(norm(XI).*norm(XJ(ii,:)))); %
        % angles between source normal and vectors to targets

        % D2(ii) = norm(XJ(ii,:))./abs(dot(XI,XJ(ii,:)))+norm(XJ(ii,:));
        % loofah(ii) = dot(XI,XJ(ii,:));
        % D2(ii) = abs(dot(XI,XJ(ii,:)));

        % distance between plus the ratio of distance to dot product
        % 
        if D2(ii) > 90
            D2(ii) = 180-D2(ii);
        end
    end
    D2 = D2';
end