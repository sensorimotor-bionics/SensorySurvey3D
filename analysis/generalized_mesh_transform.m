function [two_dim, three_dim] = generalized_mesh_transform(mesh_2D,landmarks_2D,mesh_3D,landmarks_3D,which_side)

    %% options
    viewplot = false;
    viewfinalplot = true;    

    %% import 2D mesh
    data = import_json(mesh_2D);
    two_dim_verts = data.vertices;
    two_dim_faces = data.faces;
    region_data = import_json("2D_region_definitions.json");
    
    %% import 3D mesh
    data = import_json(mesh_3D);
    three_dim_verts = data.vertices;
    three_dim_faces = data.faces;
    three_dim.raw_verts = three_dim_verts;
    
    %% import landmarks
    % primary landmarks:
    landmarks = {"Tend","Tpip","Tmcp",...
        "Iend","Idip","Ipip","Imcp",...
        "Mend","Mdip","Mpip","Mmcp",...
        "Rend","Rdip","Rpip","Rmcp",...
        "Pend","Pdip","Ppip","Pmcp",...
        "MpP","MpD","WuT","WuP", "EoW"};

    % accessory landmarks (for width determination):
    accessory_landmarks = {...
            "TpipL","TpipR","TmcpL","TmcpR",...
            "IdipL","IdipR","IpipL","IpipR",...
            "MdipL","MdipR","MpipL","MpipR",...
            "RdipL","RdipR","RpipL","RpipR",...
            "PdipL","PdipR","PpipL","PpipR"};

    all_landmarks = cat(2,landmarks,accessory_landmarks);
    landmark_2D = import_json(landmarks_2D);
    landmark_3D = import_json(landmarks_3D);
    all_3d = import_model_landmarks(landmark_3D,landmarks);
    all_2d = import_model_landmarks(landmark_2D,all_landmarks);
    
    % hierarchical dependency definitions:
    dependencies = ["Tmcp","Tpip";"Tpip","Tend";...
        "Imcp","Ipip";"Ipip","Idip";"Idip","Iend";...
        "Mmcp","Mpip";"Mpip","Mdip";"Mdip","Mend";...
        "Rmcp","Rpip";"Rpip","Rdip";"Rdip","Rend";...
        "Pmcp","Ppip";"Ppip","Pdip";"Pdip","Pend";...
        "WuP","EoW";"WuT","EoW"];
    anchor_landmark = "EoW";

    % convert landmarks from strings to indices:
    dependencies_temp = nan(size(dependencies));
    for l = 1:length(landmarks)
        dependencies_temp(dependencies==landmarks{l}) = l;

        if strcmp(anchor_landmark,landmarks{l})
            anchor_landmark = l;
        end
    end
    dependencies = dependencies_temp;
        
    %% build proximity maps of mesh to keypoints
    dibs = nan(size(three_dim_verts,1),1);
    expanded_landmarks = [];
    expanded_values = [];
    valence_values = [];
    
    % use medial axis to assign dibs
    for l = 1:size(dependencies,1)
        point1 = landmark_3D.(landmarks{dependencies(l,1)});
        point2 = landmark_3D.(landmarks{dependencies(l,2)});
        x=linspace(point1(1),point2(1),10);
        y=linspace(point1(2),point2(2),10);
        z=linspace(point1(3),point2(3),10);
        expanded_landmarks = cat(1,expanded_landmarks,[x;y;z]');
        expanded_values = cat(1,expanded_values,dependencies(l,1).*ones(10,1));
        valence_values = cat(1,valence_values,ones(10,1));
    end

    % proximity to each keypoint on the overlying mesh, then normalize (0 to 1)
    distance_record = nan(size(three_dim_verts,1),length(expanded_landmarks));
    
    for v = 1:size(three_dim_verts,1)
        this_vert = three_dim_verts(v,:);
        
        for l = 1:length(expanded_landmarks)
            this_landmark = expanded_landmarks(l,:);
            distance_record(v,l) = pdist([this_vert;this_landmark],'euclidean');
        end
    
        dibs(v) = expanded_values(find(distance_record(v,:) == min(distance_record(v,:)),1,'first'));
    end

    dibs_valence = distance_record-min(distance_record,[],1);
    dibs_valence = dibs_valence./repmat(max(dibs_valence,[],1),[size(three_dim_verts,1),1]);
    dibs_valence = 1-dibs_valence;
    % dibs_valence = dibs_valence.^4; % if you want to define some sort of falloff...

    apply_transform_reference = nan(size(three_dim_verts,1),length(all_landmarks));
    for l = 1:length(all_landmarks)
        try
            apply_transform_reference(:,l) = max(dibs_valence(:,expanded_values==l),[],2);
        catch
            apply_transform_reference(:,l) = zeros(size(three_dim_verts,1),1);
        end
    end

    % winner takes all
    apply_transform = zeros(size(apply_transform_reference));
    winner_takes_all = apply_transform_reference==repmat(max(apply_transform_reference,[],2),[1,size(apply_transform_reference,2)]);
    apply_transform(winner_takes_all) = apply_transform_reference(winner_takes_all);
    apply_transform_reference = apply_transform./sum(apply_transform,2);

    %% initial procrustes alignment
    [~,all_3d,transform] = procrustes(all_2d(1:length(landmarks),:),all_3d(1:length(landmarks),:)); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
    three_dim_verts = transform.b*three_dim_verts*transform.T+transform.c(1,:);

    %% auto width detection
    accessory_width = nan(length(accessory_landmarks),3);
    for l = 1:size(dependencies,1)
        if ~strcmp(landmarks{dependencies(l,1)},"end")
            point1 = landmark_3D.(landmarks{dependencies(l,1)});
            point2 = landmark_3D.(landmarks{dependencies(l,2)});
            point1 = transform.b*point1'*transform.T+transform.c(1,:);
            point2 = transform.b*point2'*transform.T+transform.c(1,:);
            m = (point2(2)-point1(2))/(point2(1)-point1(1)); % line passes through a point and has a slope equal to -1/(slope)
            b = point1(2) - (-1/m)*point1(1); % solve y = mx+b for b, use new slope and b 
            perp_l = point1;
            perp_l(1) = perp_l(1)+.03;
            perp_l(2) = (-1/m)*perp_l(1)+b;
            perp_r = point1;
            perp_r(1) = perp_r(1)-.03;
            perp_r(2) = (-1/m)*perp_r(1)+b;
            try
                if strcmp(which_side,"dorsal") % come back and fix this later...
                    accessory_width(strcmp([accessory_landmarks{:}],strcat(landmarks{dependencies(l,1)},"L")),:) = perp_r;
                    accessory_width(strcmp([accessory_landmarks{:}],strcat(landmarks{dependencies(l,1)},"R")),:) = perp_l;
                elseif strcmp(which_side,"palmar")
                    accessory_width(strcmp([accessory_landmarks{:}],strcat(landmarks{dependencies(l,1)},"L")),:) = perp_l;
                    accessory_width(strcmp([accessory_landmarks{:}],strcat(landmarks{dependencies(l,1)},"R")),:) = perp_r;
                end
            catch
            end
        end
    end

    width_distance_record = nan(size(three_dim_verts,1),size(accessory_width,1));
    for v = 1:size(three_dim_verts,1)
        this_vert = three_dim_verts(v,:);
        for l = 1:size(accessory_width,1)
            this_landmark = accessory_width(l,:);
            width_distance_record(v,l) = pdist([this_vert;this_landmark],'euclidean');
        end
    end

    width_landmarks = nan(size(accessory_width,1),3);
    for l = 1:size(accessory_width,1)
        try
            width_landmarks(l,:) = three_dim_verts(find(width_distance_record(:,l)==min(width_distance_record(:,l)),1,'first'),:);
        catch
            width_landmarks(l,:) = nan(1,3);
        end
    end

    %% iterative procrustes
    % for any set of n keypoints, find procrustes transforms to align those keypoints
    % overlying mesh should be morphed based on proximity to present keypoints of interest
    which_dims = [1 2 3];
    three_dim_verts_moved = zeros(size(three_dim_verts));
    
    % first shift to match xyz positions of anchor landmark
    overall_shift = all_3d(anchor_landmark,:)-all_2d(anchor_landmark,:);
    all_3d = [all_3d;width_landmarks];
    all_3d = all_3d-overall_shift;
    three_dim_verts = three_dim_verts-overall_shift;

    % iterate through list of dependencies and make adjustments
    for combo = 1:size(dependencies,1)-2
        keypoint_combinations = dependencies(combo,:);
        all_representations = find(contains([all_landmarks{:}],[landmarks{keypoint_combinations}]));
        all_representations(ismember(all_representations,keypoint_combinations)) = [];
        keypoint_combinations = [keypoint_combinations all_representations];

        [~,Z,transform] = procrustes(all_2d(keypoint_combinations,which_dims),all_3d(keypoint_combinations,which_dims),'reflection',false); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
        these_representations = find(contains([all_landmarks{:}],[landmarks{keypoint_combinations(1)} landmarks{keypoint_combinations(contains([all_landmarks{keypoint_combinations}],"end"))}]));
        all_3d(these_representations,which_dims) = Z(ismember(keypoint_combinations,these_representations),:);
        three_dim_verts_moved(:,which_dims) = transform.b*three_dim_verts(:,which_dims)*transform.T+transform.c(1,:);
        apply_transform = sum(apply_transform_reference(:,these_representations),2);

        % peep which vertices are transformed in this iteration:
        % figure
        % for ii = 1:size(three_dim_verts,1)
        %     plot3(three_dim_verts(ii,1),three_dim_verts(ii,2),three_dim_verts(ii,3),'.','Color',[0 0 apply_transform(ii)])
        %     hold on
        % end
        % axis equal

        three_dim_verts_temp = three_dim_verts;
        three_dim_verts_temp(:,which_dims) = three_dim_verts_moved(:,which_dims).*apply_transform + three_dim_verts(:,which_dims).*(1-apply_transform);

        % peep the planned transformation in this iteration:
        % figure
        % plot3(three_dim_verts(:,1),three_dim_verts(:,2),three_dim_verts(:,3),'.')
        % hold on
        % plot3(three_dim_verts_temp(:,1),three_dim_verts_temp(:,2),three_dim_verts_temp(:,3),'*')
        % plot3(all_3d(:,1),all_3d(:,2),all_3d(:,3),'o')
        % plot3(all_2d(:,1),all_2d(:,2),all_2d(:,3),'x')
        % axis equal

        three_dim_verts = three_dim_verts_temp;
    end

    %% assess 2D/3D mesh alignment
    if viewfinalplot
        figure
        plot3(three_dim_verts(:,1),three_dim_verts(:,2),three_dim_verts(:,3),'.')
        hold on
        plot3(all_3d(:,1),all_3d(:,2),all_3d(:,3),'o')
        plot3(all_2d(:,1),all_2d(:,2),all_2d(:,3),'x')
        axis equal
    end

     %% partition aligned 3D mesh according to normal orientations
    three_dim_triangulation = triangulation(three_dim_faces+1,three_dim_verts);
    three_dim_normals = faceNormal(three_dim_triangulation);
    
    angles_list = nan(size(three_dim_normals,1),1);
    for n = 1:size(three_dim_normals,1)
        angles_list(n) = acosd(dot(three_dim_normals(n,:),[0 0 1])/(sqrt(dot(three_dim_normals(n,:),three_dim_normals(n,:)))*sqrt(dot([0 0 1],[0 0 1]))));
    end
    error_space = 0;
    is_palmar = angles_list>=90+error_space;
    is_dorsal = angles_list<=90-error_space;
    is_oblique = angles_list>60&angles_list<120;
    
    if viewplot
        figure
        hold on
        P = incenter(three_dim_triangulation);
        quiver3(P(is_dorsal,1),P(is_dorsal,2),P(is_dorsal,3), ...
         three_dim_normals(is_dorsal,1),three_dim_normals(is_dorsal,2),three_dim_normals(is_dorsal,3),0.5,'color','r');
        quiver3(P(is_palmar,1),P(is_palmar,2),P(is_palmar,3)-.1, ...
         three_dim_normals(is_palmar,1),three_dim_normals(is_palmar,2),three_dim_normals(is_palmar,3)-.1,0.5,'color','c');
        quiver3(P(is_oblique,1),P(is_oblique,2),P(is_oblique,3), ...
         three_dim_normals(is_oblique,1),three_dim_normals(is_oblique,2),three_dim_normals(is_oblique,3),0.5,'color','k','LineWidth',1);
        h = gca; axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]);
    end

    %% flatten aligned 3D mesh according to normal orientations
    three_dim_verts_flattened = three_dim_verts;
    
    for n = 1:size(three_dim_normals,1)
        this_face = three_dim_faces(n,:)+1;
        for v = 1:length(this_face)
            if is_palmar(n)
                three_dim_verts_flattened(this_face(v),3) = -0.1;
            elseif is_dorsal(n)
                three_dim_verts_flattened(this_face(v),3) = 0.1;
            else
                three_dim_verts_flattened(this_face(v),3) = 0;
            end
        end
    end

    if strcmp(which_side,"palmar")
        translation_adjustment = [100,30];
    elseif strcmp(which_side,"dorsal")
        translation_adjustment = [160,25];
    else
        translation_adjustment = [0,0];
    end
    scaling_factor = 1140/(max(all_2d(:,2))-min(all_2d(:,2)));

    three_dim_verts_shifted = three_dim_verts_flattened;
    three_dim_verts_shifted(:,1) = (three_dim_verts_flattened(:,1)-min(all_2d(:,1))).*scaling_factor+translation_adjustment(1);
    three_dim_verts_shifted(:,2) = (three_dim_verts_flattened(:,2)-min(all_2d(:,2))).*scaling_factor+translation_adjustment(2);
    three_dim_verts_shifted(:,3) = three_dim_verts_flattened(:,3).*scaling_factor;
    
    two_dim_verts_shifted = two_dim_verts;
    two_dim_verts_shifted(:,1) = (two_dim_verts(:,1)-min(all_2d(:,1))).*scaling_factor+translation_adjustment(1);
    two_dim_verts_shifted(:,2) = (two_dim_verts(:,2)-min(all_2d(:,2))).*scaling_factor+translation_adjustment(2);
    two_dim_verts_shifted(:,3) = two_dim_verts(:,3).*scaling_factor;

    three_dim.faces = three_dim_faces;
    three_dim.verts = three_dim_verts;
    three_dim.oblique = is_oblique;
    three_dim.verts_flat = three_dim_verts_shifted;
    two_dim.faces = two_dim_faces;
    two_dim.verts = two_dim_verts;
    two_dim.verts_flat = two_dim_verts_shifted;
end