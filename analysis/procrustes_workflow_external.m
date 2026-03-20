conform_to_2D_illustration = false;
survey_data_file = "Survey3DData_Recent_External.mat";

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

load(survey_data_file,'Survey3DData') % import merged OLSData from multiple sessions
Survey3DData = launch_annotation_viewers('S113',Survey3DData,"hand_landmarks");
Survey3DData = launch_annotation_viewers('Pro1',Survey3DData,"hand_landmarks");

% NOTE: if not working with the default hand landmark set, replace
% "hand_landmarks" with a 4x3 matrix defining the xyz positions of the
% extremes of the long and short axis of your model

MorphedMeshes = morph_source_to_target(Survey3DData,conform_to_2D_illustration,primary_landmarks,accessory_landmarks,dependencies,anchor_landmark);

% now, need to output coverage transfer matrix
% for any annotation that you want to plot, gonna have to multiply
% projected field with coverage transfer matrix per row




% figure; set(gcf,'position',[0,0,1500,1000])
% shape_viewer(Survey3DData(1).Model.vertices,Survey3DData(1).Model.faces,Survey3DData(10).ColorMap,gca)
% saveas(gcf,['source_251022_before_morph.png'])

theta = 180;
Rx = [1 0 0; 0 cosd(theta) -sind(theta); 0 sind(theta) cosd(theta)];
Ry = [cosd(theta) 0 sind(theta); 0 1 0; -sind(theta) 0 cosd(theta)];
Rz = [cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1];
% foo = MorphedMeshes(1).ThreeDim.verts*Rx;

original_colormap = Survey3DData(10).ColorMap;
% multiply projected field with coverage transfer matrix per row
new_colormap = MorphedMeshes(1).ThreeDim.coverage_transfer_matrix.*repmat(original_colormap',[size(MorphedMeshes(1).ThreeDim.coverage_transfer_matrix,1),1]);
new_colormap = sum(new_colormap,2); % then, sum over columns to determine coverage
new_colormap = double(new_colormap>=1.5); % threshold at 50% coverage for a new map

figure; set(gcf,'position',[0,0,1500,1000])
% shape_viewer(MorphedMeshes(1).ThreeDim.verts,Survey3DData(1).Model.faces,Survey3DData(10).ColorMap,gca)
shape_viewer(MorphedMeshes(1).ThreeDim.morph_to_verts*Rx,MorphedMeshes(1).ThreeDim.morph_to_faces,new_colormap,gca)
% shape_viewer(foo,Survey3DData(1).Model.faces,Survey3DData(10).ColorMap,gca)
saveas(gcf,['source_251022_after_morph_15.png'])

% figure; set(gcf,'position',[0,0,1500,1000])
% shape_viewer(Survey3DData(20).Model.vertices,Survey3DData(20).Model.faces,Survey3DData(38).ColorMap,gca)
% saveas(gcf,['source_251013_before_morph.png'])

original_colormap = Survey3DData(38).ColorMap;
% multiply projected field with coverage transfer matrix per row
new_colormap = MorphedMeshes(2).ThreeDim.coverage_transfer_matrix.*repmat(original_colormap',[size(MorphedMeshes(2).ThreeDim.coverage_transfer_matrix,1),1]);
new_colormap = sum(new_colormap,2); % then, sum over columns to determine coverage
new_colormap = double(new_colormap>=1.5); % threshold at 50% coverage for a new map

% foo = MorphedMeshes(2).ThreeDim.verts*Rx;
figure; set(gcf,'position',[0,0,1500,1000])
% shape_viewer(MorphedMeshes(2).ThreeDim.verts,Survey3DData(20).Model.faces,Survey3DData(38).ColorMap,gca)
shape_viewer(MorphedMeshes(2).ThreeDim.morph_to_verts*Rx,MorphedMeshes(2).ThreeDim.morph_to_faces,new_colormap,gca);
% shape_viewer(foo,Survey3DData(20).Model.faces,Survey3DData(38).ColorMap,gca)
saveas(gcf,['source_251013_after_morph_15.png'])

% Survey3DData = flatten_3D_annotations('S113',Survey3DData,MorphedMeshes);
% Survey3DData = flatten_3D_annotations('Pro1',Survey3DData,MorphedMeshes);