function [two_dim, three_dim] = transform_mesh(mesh_2D,landmarks_2D,mesh_3D,landmarks_3D,which_side)

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
    
    %% import landmarks
    landmarks = {"Tend","Tpip","Tmcp",...
        "Iend","Idip","Ipip","Imcp",...
        "Mend","Mdip","Mpip","Mmcp",...
        "Rend","Rdip","Rpip","Rmcp",...
        "Pend","Pdip","Ppip","Pmcp",...
        "MpP","MpD","WuT","WuP", "EoW"};
    landmark_2D = import_json(landmarks_2D); % REMOVE HARD-CODING OF DEETS
    landmark_3D = import_json(landmarks_3D);
    
    all_3d = plot_model_landmarks('3D Model Landmarks',landmark_3D,viewplot); % plot 3D model landmarks
    all_2d = plot_model_landmarks('2D Model Landmarks',landmark_2D,viewplot); % plot 2D model landmarks

    % figure
    % disp_shape_single(three_dim_verts,three_dim_faces)
    % hold on
    % plot3(all_3d(:,1),all_3d(:,2),all_3d(:,3),'^','MarkerSize',15,'LineWidth',2)
    % 
    % for ii = 1:36
    %     camorbit(10,0,'data',[1 1 0])
    %     drawnow
    %     % pause(0.2)
    % 
    %     frame = getframe(gcf);
    %     img =  frame2im(frame);
    %     [img,cmap] = rgb2ind(img,256);
    %     if ii == 1
    %         imwrite(img,cmap,'animation.gif','gif','LoopCount',Inf,'DelayTime',.1);
    %     else
    %         imwrite(img,cmap,'animation.gif','gif','WriteMode','append','DelayTime',.1);
    %     end
    % end
    
    %% 3D mesh dibs assignment
    dibs = nan(size(three_dim_verts,1),1);
    dibs_valence = nan(size(three_dim_verts,1),1);
    
    % new landmarks:
    axial_landmarks = [1 2; 2 3;...
        4 5; 5 6; 6 7;...
        8 9; 9 10; 10 11;...
        12 13; 13 14; 14 15;...
        16 17; 17 18; 18 19;...
        20 23; 20 22;...
        22 24; 23 24;...
        21 23; 21 22];
    
    expanded_landmarks = [];
    expanded_values = [];
    valence_values = [];
    
    % use medial axis to assign dibs
    for l = 1:size(axial_landmarks,1)
        point1 = landmark_3D.(landmarks{axial_landmarks(l,1)});
        point2 = landmark_3D.(landmarks{axial_landmarks(l,2)});
        x=linspace(point1(1),point2(1),10);
        y=linspace(point1(2),point2(2),10);
        z=linspace(point1(3),point2(3),10);
        expanded_landmarks = cat(1,expanded_landmarks,[x;y;z]');
        expanded_values = cat(1,expanded_values,axial_landmarks(l,2).*ones(10,1));
        valence_values = cat(1,valence_values,ones(10,1));
    end
    
    for v = 1:size(three_dim_verts,1)
        this_vert = three_dim_verts(v,:);
        distance_record = nan(length(expanded_landmarks),1);
    
        for l = 1:length(expanded_landmarks)
            this_landmark = expanded_landmarks(l,:);
            distance_record(l) = pdist([this_vert;this_landmark],'euclidean');
        end
    
        dibs(v) = expanded_values(find(distance_record == min(distance_record),1,'first'));
        dibs_valence(v) = valence_values(find(distance_record == min(distance_record),1,'first'));
    end
    
    %% view 3D mesh dibs assignment
    if viewplot
        figure
        hold on
        axis equal
        for l = 1:length(landmarks)
            plot3(three_dim_verts(dibs==l,1),three_dim_verts(dibs==l,2),three_dim_verts(dibs==l,3),'.')
        end
    end
    
    %% 2D vs 3D procrustes alignment
    [~,Z,transform] = procrustes(all_2d,all_3d); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
    three_dim_verts = transform.b*three_dim_verts*transform.T+transform.c(1,:);
    
    % iterative adjustment landmark order, for reference
    % landmarks = {"Tend","Tpip","Tmcp",...
    %     "Iend","Idip","Ipip","Imcp",...
    %     "Mend","Mdip","Mpip","Mmcp",...
    %     "Rend","Rdip","Rpip","Rmcp",...
    %     "Pend","Pdip","Ppip","Pmcp",...
    %     "MpP","MpD","WuT","WuP", "EoW"};
    
    landmark_translator = [15,1,2,16,3,4,5,17,6,7,8,18,9,10,11,19,12,13,14,20,21,22,23,24];
    dgt_grouper = {1:3,4:7,8:11,12:15,16:19};
    all_3d = Z;
    
    %% fixing finger flexion by joint
    [three_dim_verts,all_3d] = correct_flexion(three_dim_verts,three_dim_faces,all_3d,landmark_translator,dgt_grouper,dibs,viewplot);
    
    %% iteratively adjust medial axis segment lengths
    [three_dim_verts,all_3d] = correct_medial_axis(three_dim_verts,three_dim_faces,all_3d,all_2d,landmark_translator,dgt_grouper,dibs);
    
    %% fixing finger abduction joint by joint
    [three_dim_verts,all_3d] = correct_abduction(three_dim_verts,three_dim_faces,all_3d,all_2d,landmark_translator,dgt_grouper,dibs);
    
    %% assess 2D/3D mesh alignment
    if viewfinalplot
        figure
        hold on
        plot3(three_dim_verts(:,1),three_dim_verts(:,2),three_dim_verts(:,3),'.')
        plot3(all_3d(:,1),all_3d(:,2),all_3d(:,3),'*')
        plot3(two_dim_verts(:,1),two_dim_verts(:,2),two_dim_verts(:,3),'o','MarkerSize',10)
        plot3(all_2d(:,1),all_2d(:,2),all_2d(:,3),'^')
        axis equal
    end
    
    %% flatten aligned 3D mesh according to normal orientations
    three_dim_triangulation = triangulation(three_dim_faces+1,three_dim_verts);
    three_dim_normals = faceNormal(three_dim_triangulation);
    P = incenter(three_dim_triangulation);
    
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
        quiver3(P(is_dorsal,1),P(is_dorsal,2),P(is_dorsal,3), ...
         three_dim_normals(is_dorsal,1),three_dim_normals(is_dorsal,2),three_dim_normals(is_dorsal,3),0.5,'color','r');
        quiver3(P(is_palmar,1),P(is_palmar,2),P(is_palmar,3), ...
         three_dim_normals(is_palmar,1),three_dim_normals(is_palmar,2),three_dim_normals(is_palmar,3),0.5,'color','c');
        quiver3(P(is_oblique,1),P(is_oblique,2),P(is_oblique,3), ...
         three_dim_normals(is_oblique,1),three_dim_normals(is_oblique,2),three_dim_normals(is_oblique,3),0.5,'color','k','LineWidth',1);
        h = gca; axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]);
    end

    %%
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
    
    if viewplot
        figure
        hold on
        plot3(three_dim_verts_flattened(:,1),three_dim_verts_flattened(:,2),three_dim_verts_flattened(:,3),'.')
    end

    if strcmp(which_side,"palmar")
        translation_adjustment = [100,30];
    elseif strcmp(which_side,"dorsal")
        translation_adjustment = [160,25];
    else
        translation_adjustment = [0,0];
    end
    scaling_factor = 1140/(max(all_2d(:,2))-min(all_2d(:,2)));

    % all_2d_shifted = all_2d;
    % all_2d_shifted(:,1) = (all_2d(:,1)-min(all_2d(:,1))).*scaling_factor+translation_adjustment(1);
    % all_2d_shifted(:,2) = (all_2d(:,2)-min(all_2d(:,2))).*scaling_factor+translation_adjustment(2);
    % all_2d_shifted(:,3) = all_2d(:,3).*scaling_factor;

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

function disp_shape_single(verts,faces)
    h = gca;
    temp_verts = verts;
    
    hp = patch('vertices',temp_verts,'faces',faces+1,'parent',h); hold(h,'on');
    hp.EdgeColor = [0 0.5 0]; 
    hp.FaceColor = [0 1 0];
    hp.FaceAlpha = 0.5;
    hp.FaceLighting = 'flat';
    material(hp,[0 .5 .0 20 .5]);

    ch = get(h,'children');
    lightExists = sum(arrayfun(@(x) contains(class(ch(x)),'Light'),1:length(ch)));
    supported_positions = [1 1 1; 1 1 -1; 1 -1 1; 1 -1 -1; -1 1 1; -1 1 -1; -1 -1 1; -1 -1 -1];
    if ~lightExists
        for ii = 1:size(supported_positions,1)
            light('parent',h,'Position',supported_positions(ii,:)); 
        end
    end
    
    axis(h,'off'); axis(h,'equal');
    set(h,'Projection','perspective')
    set(h,'CameraUpVector',[0 1 0])
end