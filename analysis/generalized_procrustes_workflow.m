
%% enter annotation details
which_test = 2;

switch which_test
    case 1
        subject = 'BCI03'; session = 235;
        electrodes = [2 12 14 22 3 41 45 54 9 4 48 10 38 50 36 26 18 6 43 8 39 16 37 34 15 24 27];
        data_path_format = "Z:\\SessionData\\%s\\OpenLoopStim\\%s.data.00%d\\BCI*.json";
    case 2
        subject = 'BCI02'; session = [908 925 926];
        electrodes = [7 29 53 54 ...
                    3 10 63 34 4 7 21 57 17 56 13 53 26 30 52 ...
                    36];
        data_path_format = "Z:\\SessionData\\%s\\OpenLoopStim\\%s.data.00%d\\BCI*.json";
    case 3
        % may need to update extract_colormaps with sprintf inputs if different from above
        subject = 'S113'; session = "2025-11-10";
        electrodes = [1 1 1 1 1 1 1 1 1 9 9 9 9 9 9 9 9 9 9];
        data_path_format = ".\\mesh_utils\\participant_251013\\Survey3D_%s_%s_*.json";
end

conform_to_2D_illustration = true;
use_default_hand_source = true;

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
    "Pmcp","Ppip";"Ppip","Pdip";"Pdip","Pend"];
    % "WuP","EoW";"WuT","EoW"];

anchor_landmark = "EoW";

% alternatively, could use Survey3D to produce an annotation hotspot file
% with all of these landmarks pre-named

% would still have to provide the dependency tree, though

%% identify your source and target meshes
% identify mesh and landmark files for source
disp(' ')

if use_default_hand_source
    disp('Using default 3D hand model.')
    mesh_source = 'Male_Hands_R_rm_5000_glb.json';
    landmarks_source = "3D_model_procrustes_keypoints.json";
else
    % landmarks_source = "participant_251013_procrustes_keypoints.json";
    [file,location] = uigetfile('*.json','Select source mesh file','.\mesh_utils\');
    mesh_source = fullfile(location,file);
    [file,location] = uigetfile('*.json','Select source landmark file','.\mesh_utils\');
    landmarks_source = fullfile(location,file);
end

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

%% import 3D mesh and annotation colormaps
% parse jsons from session to determine colormaps
spec = '';
for ii = 1:length(session)
    spec = [spec char(string(session(ii))) ' '];
end

fprintf('Extracting colormaps from .json files for subject %s in session(s) %s.\n',subject,spec)
[annotation_record, this_model, model_name] =  extract_colormaps(subject,session,electrodes,data_path_format);
documented_electrodes = fieldnames(annotation_record.(this_model).electrodes);

% summarize annotation colormaps
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
image([orig_size(2),0],[mask_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
subplot(1,2,2)
hold on
image([orig_size(2),0],[mask_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)

figure
disp_shape_single(three_dim.verts_flat,three_dim.faces,[0 1 0],130,-130)
subplot(1,2,2)
hold on
image([orig_size(2),0],[mask_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
