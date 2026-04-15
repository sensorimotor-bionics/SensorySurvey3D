
%% enter annotation details
conform_to_2D_illustration = false;
survey_data_file = "Survey3DData_Recent_External.mat";

%% define your landmarks
% primary landmarks:
primary_landmarks = {"Tend","Tpip","Tmcp",...
    "Iend","Idip","Ipip","Imcp",...
    "Mend","Mdip","Mpip","Mmcp",...
    "Rend","Rdip","Rpip","Rmcp",...
    "Pend","Pdip","Ppip","Pmcp",...
    "MpP","MpD","EoW"};

% accessory landmarks (for width determination):
accessory_landmarks = {"EoW_p","EoW_t",...
        "Tpip_p","Tpip_t","Tmcp_p","Tmcp_t",...
        "Idip_p","Idip_t","Ipip_p","Ipip_t",...
        "Mdip_p","Mdip_t","Mpip_p","Mpip_t",...
        "Rdip_p","Rdip_t","Rpip_p","Rpip_t",...
        "Pdip_p","Pdip_t","Ppip_p","Ppip_t",...
        "Imcp_p","Imcp_t","Mmcp_p","Mmcp_t",...
        "Rmcp_p","Rmcp_t","Pmcp_p","Pmcp_t","MpP_p","MpP_t"};

% hierarchical dependency definitions:
dependencies = ["MpP","Tmcp";"MpD","Imcp";"EoW","Pmcp";...
    "Tmcp","Tpip";"Tpip","Tend";...
    "Imcp","Ipip";"Ipip","Idip";"Idip","Iend";...
    "Mmcp","Mpip";"Mpip","Mdip";"Mdip","Mend";...
    "Rmcp","Rpip";"Rpip","Rdip";"Rdip","Rend";...
    "Pmcp","Ppip";"Ppip","Pdip";"Pdip","Pend";...
    "EoW","MpP"];

anchor_landmark = "EoW";

%% load data, process models
% generate Survey3DData using general_data_extraction (external)
load(survey_data_file,'Survey3DData') % import merged OLSData from multiple sessions

Survey3DData = launch_annotation_viewers('S113',Survey3DData,"hand_landmarks");
Survey3DData = launch_annotation_viewers('Pro1',Survey3DData,"hand_landmarks");

% NOTE: if not working with the default hand landmark set, replace
% "hand_landmarks" with a 4x3 matrix defining the xyz positions of the
% extremes of the long and short axis of your model

%% 3D-to-3D morph example
% because we perform a 3D-to-3D morph here, MorphedMeshes will include a
% coverage transfer matrix, stored in MorphedMeshes as source.coverage_transfer_matrix

% when prompted for target files, we recommended to morph to the specs in mesh_utils/3D_intermediary_mesh
MorphedMeshes = morph_source_to_target(Survey3DData,conform_to_2D_illustration,primary_landmarks,accessory_landmarks,dependencies,anchor_landmark);

%% view 3D-to-3D projection example from S113
which_row = 10;
which_model = find(strcmp({MorphedMeshes.ModelName},Survey3DData(which_row).ModelName));
original_colormap = Survey3DData(which_row).ColorMap;

% let's look at row 10's source model prior to morphing
figure; set(gcf,'position',[0,0,1500,1000])
shape_viewer(MorphedMeshes(which_model).source.raw_verts_aligned,MorphedMeshes(which_model).source.faces,original_colormap,gca)
view(-90,90)
title('annotation on model before morph')

% for any annotation that you want to plot, have to multiply the projected 
% field with the coverage transfer matrix (per row)
new_colormap = MorphedMeshes(which_model).source.coverage_transfer_matrix.*repmat(original_colormap',[size(MorphedMeshes(which_model).source.coverage_transfer_matrix,1),1]);
new_colormap = sum(new_colormap,2); % then, sum over columns to determine coverage
new_colormap = double(new_colormap>=1.5); % threshold at 50% coverage for a new map

% this is row 10's 3D annotation projected onto the default hand model
figure; set(gcf,'position',[0,0,1500,1000])
shape_viewer(MorphedMeshes(which_model).source.morph_to_verts,MorphedMeshes(which_model).source.morph_to_faces,new_colormap,gca)
view(-90,90)
title('annotation on default after morph')

%% view 3D-to-3D projection example from Pro1
which_row = 38;
which_model = find(strcmp({MorphedMeshes.ModelName},Survey3DData(which_row).ModelName));
original_colormap = Survey3DData(which_row).ColorMap;

% let's look at row 38's source model prior to morphing
figure; set(gcf,'position',[0,0,1500,1000])
shape_viewer(MorphedMeshes(which_model).source.raw_verts_aligned,MorphedMeshes(which_model).source.faces,original_colormap,gca)
view(-90,90)
title('annotation on model before morph')

% multiply projected field with coverage transfer matrix per row
new_colormap = MorphedMeshes(which_model).source.coverage_transfer_matrix.*repmat(original_colormap',[size(MorphedMeshes(which_model).source.coverage_transfer_matrix,1),1]);
new_colormap = sum(new_colormap,2); % then, sum over columns to determine coverage
new_colormap = double(new_colormap>=1.5); % threshold at 50% coverage for a new map

% this is row 38's 3D annotation projected onto the default hand model
figure; set(gcf,'position',[0,0,1500,1000])
shape_viewer(MorphedMeshes(which_model).source.morph_to_verts,MorphedMeshes(which_model).source.morph_to_faces,new_colormap,gca)
view(-90,90)
title('annotation on default after morph')