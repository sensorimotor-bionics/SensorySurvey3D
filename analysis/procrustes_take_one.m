
%% options
viewplot = false;
viewfinalplot = true;

% subject = 'BCI03';
% session = 235;
% electrodes = [2 12 14 22 3 41 45 54 9 4 48 10 38 50 36 26 18 6 43 8 39 16 37 34 15 24 27];

subject = 'BCI02';
session = 925;
electrodes = [3 10 63 34 4 7 21 57 17 56 13 53 26 30 52];

% session = 925;
% electrodes_3d = [3 10 63 34 4 7 21 57 17 56 13 53 26 30 52]; % sets 14 3 5 13 15 4 12 24 6 2 25 26 23 22 16
% electrodes_2d = [61 11 29 59 6 9 38 55 12 54]; % 925 ols data is 25 long, sets 2-26 (sets 7-11, 17-21) (skip OLS rows for the sets above!)
% 
% session = 926;
% electrodes_3d = [36]; % set 17
% electrodes_2d = [36 56 32 63 30 4 34 7 57 13 53 17 36]; % 926 ols data is 13 long, sets 4-16

% have both 2d and 3d for: 4 7 13 17 30 34 35 53 56 57 63
% OLSData_BCI02_00925
% OLSData_BCI02_00926

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
landmark_2D = import_json("2D_model_procrustes_keypoints_tight.json"); % REMOVE HARD-CODING OF DEETS
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

%% flatten aligned 3D mesh according to normal orientations
three_dim_triangulation = triangulation(three_dim_faces+1,three_dim_verts);
three_dim_normals = faceNormal(three_dim_triangulation);
P = incenter(three_dim_triangulation);

for n = 1:size(three_dim_normals,1)
    angles_list(n) = acosd(dot(three_dim_normals(n,:),[0 0 1])/(sqrt(dot(three_dim_normals(n,:),three_dim_normals(n,:)))*sqrt(dot([0 0 1],[0 0 1]))));
end
error_space = 0;

if viewplot
    figure
    hold on
    quiver3(P(angles_list<=90-error_space,1),P(angles_list<=90-error_space,2),P(angles_list<=90-error_space,3), ...
     three_dim_normals(angles_list<=90-error_space,1),three_dim_normals(angles_list<=90-error_space,2),three_dim_normals(angles_list<=90-error_space,3),0.5,'color','r');
    quiver3(P(angles_list>=90+error_space,1),P(angles_list>=90+error_space,2),P(angles_list>=90+error_space,3), ...
     three_dim_normals(angles_list>=90+error_space,1),three_dim_normals(angles_list>=90+error_space,2),three_dim_normals(angles_list>=90+error_space,3),0.5,'color','c');
end

is_palmar = angles_list>=90+error_space;
is_dorsal = angles_list<=90-error_space;

three_dim_verts_flattened = three_dim_verts;

for n = 1:size(three_dim_normals,1)
    this_face = three_dim_faces(n,:)+1;
    for v = 1:length(this_face)
        if is_palmar(n)
            three_dim_verts_flattened(this_face(v),3) = -0.1;
        else
            three_dim_verts_flattened(this_face(v),3) = 0.1;
        end
    end
end

if viewplot
    figure
    hold on
    plot3(three_dim_verts_flattened(:,1),three_dim_verts_flattened(:,2),three_dim_verts_flattened(:,3),'.')
end

%% view annotations on flattened 3D mesh
ref_img_path = fullfile(pwd(), 'ReferenceImages');
[palmar_mask, palmar_template, dorsal_mask, dorsal_template] = GetHandMasks();
[palmar_segments, dorsum_segments] = GetHandSegments();
orig_size = size(palmar_mask);

[palm_ref_img, ~, palm_ref_alpha] = imread(fullfile(ref_img_path, 'TopLayer-handpcontour.png'));
palm_ref_img = imresize(palm_ref_img, orig_size);
palm_ref_alpha = imresize(palm_ref_alpha, orig_size);

[dor_ref_img, ~, dor_ref_alpha] = imread(fullfile(ref_img_path, 'TopLayer-contour.png'));

translation_adjustment = [100,30];
scaling_factor = 1140/(max(all_2d(:,2))-min(all_2d(:,2)));

three_dim_verts_shifted = three_dim_verts_flattened;
three_dim_verts_shifted(:,1) = (three_dim_verts_flattened(:,1)-min(all_2d(:,1))).*scaling_factor+translation_adjustment(1);
three_dim_verts_shifted(:,2) = (three_dim_verts_flattened(:,2)-min(all_2d(:,2))).*scaling_factor+translation_adjustment(2);
three_dim_verts_shifted(:,3) = three_dim_verts_flattened(:,3).*scaling_factor;

two_dim_verts_shifted = two_dim_verts;
two_dim_verts_shifted(:,1) = (two_dim_verts(:,1)-min(all_2d(:,1))).*scaling_factor+translation_adjustment(1);
two_dim_verts_shifted(:,2) = (two_dim_verts(:,2)-min(all_2d(:,2))).*scaling_factor+translation_adjustment(2);
two_dim_verts_shifted(:,3) = two_dim_verts(:,3).*scaling_factor;

% disp_shape_single(two_dim_verts_shifted,two_dim_faces,[0 1 0],50,-50)
% subplot(1,2,1)
% hold on
% image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
% subplot(1,2,2)
% hold on
% image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
temp_background = zeros([orig_size 3]);

if viewfinalplot
    for ele = 1:length(documented_electrodes)
        this_ele = documented_electrodes{ele};
        foo = split(this_ele,'_');

        figure; set(gcf,'position',[0,0,1106,600])
        subplot(1,2,1); hold on
        imagesc(temp_background)
        axis tight; axis equal
        subplot(1,2,2); hold on
        imagesc(temp_background)
        axis tight; axis equal

        [~,~] = disp_shape_single(three_dim_verts_shifted,three_dim_faces,color_map.(this_ele),0,0); % +/- 0.1001*scaling_factor

        cdata = print('-RGBImage','-r300','-noui');
        d = cdata(:,1:size(cdata,2)/2,:);
        del_row = sum(d(:,:,1)~=0,2)==size(d,2);
        del_col = sum(d(:,:,1)~=0,1)==size(d,1);
        d(del_row,:,:) = [];
        d(:,del_col,:) = [];
        temp = double(d(:,:,1));
        dorsal{double(string(cell2mat(foo(2))))} = temp(1:orig_size(1),1:orig_size(2)); % enforce proper sizing
        
        p = cdata(:,size(cdata,2)/2+1:end,:);
        del_row = sum(p(:,:,1)~=0,2)==size(p,2);
        del_col = sum(p(:,:,1)~=0,1)==size(p,1);
        p(del_row,:,:) = [];
        p(:,del_col,:) = [];
        temp = double(p(:,:,1));
        palmar{double(string(cell2mat(foo(2))))} = temp(1:orig_size(1),1:orig_size(2)); % enforce proper sizing

        sgtitle(foo(2))
    end
end

% what proportion of annotated normals are beyond 30 deg of camera angle
% (invisible to camera or squashed in a 2D representation)?

%% throw away colors outside of the lines...

%% compare 2D and 3D heatmaps...
% also need morph between dorsum illustration and palmar illustration... won't be inherently aligned here
load("BCI02_ProcessedPFs_PalmarIdx.mat"); % ConsolidatedPFs
PFs_palmar = ConsolidatedPFs;
load("BCI02_ProcessedPFs_DorsumIdx.mat"); % ConsolidatedPFs
PFs_dorsal = ConsolidatedPFs;

for ele = 1:length(documented_electrodes)
    this_ele = documented_electrodes{ele};
    foo = split(this_ele,'_');
    this_ele = double(string(cell2mat(foo(2))));

    figure; set(gcf,'position',[0,0,2500,1500])
    h = subplot(2,2,1); % dorsal
    temp_dorsal_2D = flipud(PFs_dorsal(this_ele).PixelFreqMap);
    imagesc(temp_dorsal_2D)
    hold on
    image([0,orig_size(2)],[orig_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0])
    title('2D annotation - dorsal')
    
    h = subplot(2,2,2); % palmar
    temp_palmar_2D = flipud(fliplr(PFs_palmar(this_ele).PixelFreqMap));
    imagesc(temp_palmar_2D)
    hold on
    image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]); set(h,'CameraPosition',[0,0,-10*1200])
    title('2D annotation - palmar')
    
    h = subplot(2,2,3); % dorsal
    temp_dorsal_3D = flipud(dorsal{double(string(cell2mat(foo(2))))});
    imagesc(temp_dorsal_3D.* flipud(fliplr(palmar_mask)))
    hold on
    image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0])
    title('3D annotation - dorsal')

    h = subplot(2,2,4); % palmar
    temp_palmar_3D = flipud(fliplr(palmar{double(string(cell2mat(foo(2))))}));
    imagesc(temp_palmar_3D.* flipud(fliplr(palmar_mask)))
    hold on
    image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]); set(h,'CameraPosition',[0,0,-10*1200])
    title('3D annotation - palmar')

    % Jaccard index: area of overlap / area of union
    separator = 0.6;
    temp_palmar_2D = temp_palmar_2D./max(temp_palmar_2D);
    temp_palmar_2D(temp_palmar_2D>=separator) = 1;
    temp_palmar_2D(temp_palmar_2D<separator) = 0;
    summary_palmar = temp_palmar_2D+temp_palmar_3D.* flipud(fliplr(palmar_mask))./255;
    overlap_palmar = sum(summary_palmar==2,'all');
    union_palmar = sum(summary_palmar>0,'all');

    temp_dorsal_2D = temp_dorsal_2D./max(temp_dorsal_2D);
    temp_dorsal_2D(temp_dorsal_2D>=separator) = 1;
    temp_dorsal_2D(temp_dorsal_2D<separator) = 0;
    summary_dorsal = temp_dorsal_2D.* flipud(dorsal_mask)+temp_dorsal_3D.* flipud(fliplr(palmar_mask))./255;
    overlap_dorsal = sum(summary_dorsal==2,'all');
    union_dorsal = sum(summary_dorsal>0,'all');

    if union_palmar == 0
        union_palmar = 1;
    end

    if union_dorsal == 0
        union_dorsal = 1;
    end

    sgtitle([{['electrode ' cell2mat(foo(2))]} {['dorsum jaccard: ' char(string(overlap_dorsal/union_dorsal))]} {['palmar jaccard: ' char(string(overlap_palmar/union_palmar))]}])
    % saveas(gcf,['BCI02_comparative_annotation_electrode_' char(foo(2)) '.png'])
end

%% view annotations on morphed 3D mesh
for ele = 1:length(documented_electrodes)
    this_ele = documented_electrodes{ele};
    [~,~] = disp_shape_single(three_dim_verts,three_dim_faces,color_map.(this_ele),0,0);
    foo = split(this_ele,'_');
    sgtitle(foo(2))
    % saveas(gcf,['BCI02_3D_annotation_electrode_' char(foo(2)) '.png'])
end

%% helper functions
function [dorsal, palmar] = disp_shape_single(verts,faces,colors,front_dist,back_dist)
    % figure;
    % set(gcf,'position',[0,0,1500,500])
    for persp = 1:2
        h = subplot(1,2,persp);
        temp_verts = verts;

        if persp == 1
            temp_verts(:,3) = verts(:,3)+back_dist;
        elseif persp == 2
            temp_verts(:,3) = verts(:,3)+front_dist;
        end
        
        hp = patch('vertices',temp_verts,'faces',faces+1,'parent',h); hold(h,'on');
        hp.EdgeColor = 'none'; 
        hp.FaceColor = 'flat';
        hp.FaceVertexCData = colors;
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
            set(h,'CameraPosition',h.CameraPosition.*[1 1 -1])
            palmar = getframe;
        else
            dorsal = getframe;
        end
    end
end
