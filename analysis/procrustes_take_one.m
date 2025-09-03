
%% options
viewplot = false;
viewfinalplot = true;

subject = 'BCI03';
session = [235];
electrodes = [2 12 14 22 3 41 45 54 9 4 48 10 38 50 36 26 18 6 43 8 39 16 37 34 15 24 27];

% for ee = 1:length(electrodes)
%     figure
%     h = heatmap(ConsolidatedPFs(electrodes(ee)).PixelFreqMap);
%     h.GridVisible = 'off';
%     sgtitle(string(electrodes(ee)))
% end

%% import 2D mesh
data = import_json("2D_mesh_data.json");
two_dim_verts = data.vertices;
two_dim_faces = data.faces;
region_data = import_json("2D_region_definitions.json");

%% import 3D mesh and annotation colormaps
% parse jsons from session to determine colormaps
[annotation_record, this_model, model_name] =  extract_colormaps(subject,session,electrodes);
documented_electrodes = fieldnames(annotation_record.(this_model).electrodes);

data = import_json([model_name '.json']);
three_dim_verts = data.vertices;
three_dim_faces = data.faces;

%% summarize annotation colormaps
for ele = 1:length(documented_electrodes)
    this_ele = documented_electrodes{ele};

    if size(annotation_record.(this_model).electrodes.(this_ele).fields,2)>1
        which_map = sum(annotation_record.(this_model).electrodes.(this_ele).fields,2);
        which_map(which_map>1) = 1;
    else
        which_map = annotation_record.(this_model).electrodes.(this_ele).fields;
    end
    color_map.(this_ele) = [which_map,0.5*ones(size(which_map)),0.2*ones(size(which_map))];
end

%% import landmarks
landmarks = {"Tend","Tpip","Tmcp",...
    "Iend","Idip","Ipip","Imcp",...
    "Mend","Mdip","Mpip","Mmcp",...
    "Rend","Rdip","Rpip","Rmcp",...
    "Pend","Pdip","Ppip","Pmcp",...
    "MpP","MpD","WuT","WuP", "EoW"};
landmark_2D = import_json("2D_model_procrustes_keypoints.json"); % REMOVE HARD-CODING OF DEETS
landmark_3D = import_json("3D_model_procrustes_keypoints.json");

all_3d = plot_model_landmarks('3D Model Landmarks',landmark_3D,viewplot); % plot 3D model landmarks
all_2d = plot_model_landmarks('2D Model Landmarks',landmark_2D,viewplot); % plot 2D model landmarks

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
[three_dim_verts,all_3d] = correct_flexion(three_dim_verts,all_3d,landmark_translator,dgt_grouper,dibs,viewplot);

%% iteratively adjust medial axis segment lengths
[three_dim_verts,all_3d] = correct_medial_axis(three_dim_verts,all_3d,all_2d,landmark_translator,dgt_grouper,dibs);

%% fixing finger abduction joint by joint
[three_dim_verts,all_3d] = correct_abduction(three_dim_verts,all_3d,all_2d,landmark_translator,dgt_grouper,dibs);

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

%% view annotations on morphed 3D mesh
for ele = 1:length(documented_electrodes)
    this_ele = documented_electrodes{ele};
    disp_shape_single(three_dim_verts,three_dim_faces,color_map.(this_ele))
    foo = split(this_ele,'_');
    sgtitle(foo(2))
end

%% helper functions
function disp_shape_single(verts,faces,colors)
    figure;
    for persp = 1:2
        h = subplot(1,2,persp);
        % h = gca;
        hp = patch('vertices',verts,'faces',faces+1,'parent',h); hold(h,'on');
        hp.EdgeColor = 'none'; 
        hp.FaceColor = 'flat';
        hp.FaceVertexCData = colors;
        % hp.FaceVertexAlphaData = 1;
        % hp.FaceAlpha = 'none';
        hp.FaceLighting = 'flat';
        material(hp,[0.5 0.5 0.0 20 0.5]);
    
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

        if persp == 2
            set(h,'CameraPosition',[0,0,-10])
        end
    end
end