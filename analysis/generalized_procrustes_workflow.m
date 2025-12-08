
%% enter annotation details
subject = 'S113';
conform_to_2D_illustration = false;
use_default_hand_source = false;

%% define your landmarks
% primary landmarks:
primary_landmarks = {"Tend","Tpip","Tmcp",...
    "Iend","Idip","Ipip","Imcp",...
    "Mend","Mdip","Mpip","Mmcp",...
    "Rend","Rdip","Rpip","Rmcp",...
    "Pend","Pdip","Ppip","Pmcp",...
    "MpP","MpD","WuT","WuP", "EoW"};

% accessory landmarks (for width determination):
accessory_landmarks = {...
        "Tpip_p","Tpip_t","Tmcp_p","Tmcp_t",...
        "Idip_p","Idip_t","Ipip_p","Ipip_t",...
        "Mdip_p","Mdip_t","Mpip_p","Mpip_t",...
        "Rdip_p","Rdip_t","Rpip_p","Rpip_t",...
        "Pdip_p","Pdip_t","Ppip_p","Ppip_t"};

% hierarchical dependency definitions:
dependencies = ["Tmcp","Tpip";"Tpip","Tend";...
    "Imcp","Ipip";"Ipip","Idip";"Idip","Iend";...
    "Mmcp","Mpip";"Mpip","Mdip";"Mdip","Mend";...
    "Rmcp","Rpip";"Rpip","Rdip";"Rdip","Rend";...
    "Pmcp","Ppip";"Ppip","Pdip";"Pdip","Pend";...
    "EoW","MpD"];

anchor_landmark = "EoW";

% alternatively, could use Survey3D to produce an annotation hotspot file
% with all of these landmarks pre-named
% would still have to provide the dependency tree, though

%% identify your source mesh
% identify mesh and landmark files for source
disp(' ')

if use_default_hand_source
    disp('Using default 3D hand model.')
    mesh_source = 'Male_Hands_R_rm_5000_glb.json';
    landmarks_source = "3D_model_procrustes_keypoints.json";
else
    [file,location] = uigetfile('*.json','Select source mesh file','.\mesh_utils\');
    mesh_source = fullfile(location,file);
    [file,location] = uigetfile('*.json','Select source landmark file','.\mesh_utils\');
    landmarks_source = fullfile(location,file);
end

%% import 3D mesh and annotation colormaps

load("Survey3DData_Recent.mat") % import merged OLSData from multiple sessions
this_subject = find(strcmp({Survey3DData.Subject},subject)); % which rows correspond to this subject
Survey3DData = Survey3DData(this_subject); % exclude other subjects from dataset
documented_electrodes = {Survey3DData.ElectrodeID};
unique_documented_electrodes = unique(documented_electrodes);

% summarize annotation colormaps
all_fields = fieldnames(Survey3DData);
qualities = all_fields(find(strcmp(all_fields,'Model'))+1:end);
annotation_record = struct();
color_map = struct();

for ele = 1:length(unique_documented_electrodes)
    this_ele = unique_documented_electrodes{ele};
    color_map.(this_ele) = [];
end

for q = 1:length(qualities)
    annotation_record.(qualities{q}) = struct();
    for ele = 1:length(unique_documented_electrodes)
        this_ele = unique_documented_electrodes{ele};
        which_rows = find(strcmp(documented_electrodes,this_ele));
        annotation_record.(qualities{q}).(this_ele) = [];

        for ii = 1:length(which_rows)
            if ~isempty(Survey3DData(which_rows(ii)).(qualities{q}))
                annotation_record.(qualities{q}).(this_ele) = cat(2, annotation_record.(qualities{q}).(this_ele), Survey3DData(which_rows(ii)).(qualities{q}).fields);
            end
        end

        color_map.(this_ele) = cat(2, color_map.(this_ele), annotation_record.(qualities{q}).(this_ele));
    end
end

for ele = 1:length(unique_documented_electrodes)
    this_ele = unique_documented_electrodes{ele};
    which_map = nansum(color_map.(this_ele),2);
    if max(which_map,[],"all")>0
        which_map = which_map./max(which_map,[],"all");
    end
    color_map.(this_ele) = which_map;
end

%% annotation viewer
disp('Launching annotation viewer.')
disp(' ')
data = import_json(mesh_source);
three_dim.raw_verts = data.vertices;
three_dim.faces = data.faces;
annotation_viewer(Survey3DData,unique_documented_electrodes,qualities,three_dim)

%% annotation viewer by row
disp('Launching rowwise annotation viewer.')
disp(' ')
row_annotation_viewer(Survey3DData,qualities,three_dim)

%% identify your target mesh
% identify mesh and landmark files for target 
disp(' ')

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

%% transform source mesh to target mesh
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
    [two_dim,three_dim] = generalized_mesh_transform(mesh_target,landmarks_target,mesh_source,landmarks_source,...
        primary_landmarks,accessory_landmarks,dependencies,anchor_landmark,"unsided");
end

%% view annotations on flattened 3D mesh
disp(' ')
disp('Converting palmar and dorsal fits to heatmaps.')
[palmar_mask, ~] = get_hand_masks();
[palmar,dorsal] = convert_3D_to_heatmap(three_dim,three_dim_dorsum,documented_electrodes,color_map,size(palmar_mask));




%% BEYOND THIS POINT IS FOR PAPER ONLY, COMPARING TO OUR SPECIFIC PF DATA

%% compare 2D and 3D heatmaps...
load(['data/' subject '_ProcessedPFs_PalmarIdx.mat']); % ConsolidatedPFs
PFs_palmar = ConsolidatedPFs;
load(['data/' subject '_ProcessedPFs_DorsumIdx.mat']); % ConsolidatedPFs
PFs_dorsal = ConsolidatedPFs;

reference_image_path = fullfile(pwd(), 'reference images');
palmar_image = fullfile(reference_image_path, 'TopLayer-handpcontour.png');
dorsal_image = fullfile(reference_image_path, 'TopLayer-contour.png');
jaccard_record = compute_jaccard(subject,documented_electrodes,palmar,PFs_palmar,palmar_image,dorsal,PFs_dorsal,dorsal_image);

%% quantifying oblique annotations
% i.e. annotations which are invisible to camera or squashed in a 2D representation
[three_dim, oblique_proportion] = quantify_oblique_annotations(subject,three_dim,documented_electrodes,color_map);

%% view annotations on morphed 3D mesh
ref_img_path = fullfile(pwd(), 'reference images');
[palmar_mask, dorsal_mask] = get_hand_masks();
mask_size = size(palmar_mask);
temp_background = zeros([mask_size 3]);

[palm_ref_img, ~, palm_ref_alpha] = imread(fullfile(ref_img_path, 'TopLayer-handpcontour.png'));
palm_ref_img = imresize(palm_ref_img, mask_size);
palm_ref_alpha = imresize(palm_ref_alpha, mask_size);
[dor_ref_img, ~, dor_ref_alpha] = imread(fullfile(ref_img_path, 'TopLayer-contour.png'));

figure
disp_shape_single(two_dim.verts_flat,two_dim.faces,[0 1 0],50,-50)
subplot(1,2,1)
hold on
image([mask_size(2),0],[mask_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
subplot(1,2,2)
hold on
image([mask_size(2),0],[mask_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)

figure
disp_shape_single(three_dim.verts_flat,three_dim.faces,[0 1 0],130,-130)
subplot(1,2,2)
hold on
image([mask_size(2),0],[mask_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)








scaling_factor = 1140/(max(two_dim.landmarks(:,2))-min(two_dim.landmarks(:,2)));
translation_adjustment = [100,30];
two_dim_landmarks_shifted = two_dim.landmarks;
two_dim_landmarks_shifted(:,1) = (two_dim.landmarks(:,1)-min(two_dim.landmarks(:,1))).*scaling_factor+translation_adjustment(1);
two_dim_landmarks_shifted(:,2) = (two_dim.landmarks(:,2)-min(two_dim.landmarks(:,2))).*scaling_factor+translation_adjustment(2);
two_dim_landmarks_shifted(:,3) = two_dim.landmarks(:,3).*scaling_factor;
        
figure
hold on
image([mask_size(2),0],[mask_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
plot(two_dim_landmarks_shifted([1:21,24],1),two_dim_landmarks_shifted([1:21,24],2),'r.','MarkerSize',35,'LineWidth',3)
hold on
plot(two_dim_landmarks_shifted(25:2:end,1),two_dim_landmarks_shifted(25:2:end,2),'bx','MarkerSize',15,'LineWidth',3)
plot(two_dim_landmarks_shifted(26:2:end,1),two_dim_landmarks_shifted(26:2:end,2),'mx','MarkerSize',15,'LineWidth',3)
plot(two_dim_landmarks_shifted(22,1)+15,two_dim_landmarks_shifted(22,2),'r.','MarkerSize',35,'LineWidth',3)
plot(two_dim_landmarks_shifted(23,1)-15,two_dim_landmarks_shifted(23,2),'r.','MarkerSize',35,'LineWidth',3)
axis equal
h = gca;
axis(h,'off'); axis(h,'equal');
set(h,'Projection','perspective')
set(h,'CameraUpVector',[0 1 0])
set(h,'CameraPosition',h.CameraPosition.*[1 1 -1]);

figure
hold on
% shape_viewer(three_dim.verts,three_dim.faces,[0.5 0.5 0.5],gca)
shape_viewer(three_dim.verts,three_dim.faces,[1 1 1],gca)
alpha(0.8)
hold on
plot3(three_dim.landmarks(1:24,1),three_dim.landmarks(1:24,2),three_dim.landmarks(1:24,3),'r.','MarkerSize',35,'LineWidth',3)
plot3(three_dim.landmarks(25:2:end,1),three_dim.landmarks(25:2:end,2),three_dim.landmarks(25:2:end,3),'bx','MarkerSize',15,'LineWidth',3)
plot3(three_dim.landmarks(26:2:end,1),three_dim.landmarks(26:2:end,2),three_dim.landmarks(26:2:end,3),'mx','MarkerSize',15,'LineWidth',3)

% foo = import_model_landmarks(three_dim.landmark_report,primary_landmarks);