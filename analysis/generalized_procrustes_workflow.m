
%% enter annotation details
subject = 'BCI02';
conform_to_2D_illustration = true;
survey_data_file = "Survey3DData_Recent_BCI.mat";

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

% alternatively, could use Survey3D to produce an annotation hotspot file
% with all of these landmarks pre-named
% would still have to provide the dependency tree, though

%% load data, process models, flatten maps
load(survey_data_file,'Survey3DData') % import merged OLSData from multiple sessions

% generate Survey3DData using general_data_extraction (external)
% or private_utils/BCI_data_extraction (internal)

% Survey3DData = launch_annotation_viewers(subject,Survey3DData);
Survey3DData = launch_annotation_viewers('BCI02',Survey3DData);
Survey3DData = launch_annotation_viewers('BCI03',Survey3DData);

MorphedMeshes = morph_source_to_target(Survey3DData,conform_to_2D_illustration,primary_landmarks,accessory_landmarks,dependencies,anchor_landmark);

Survey3DData = flatten_3D_annotations('BCI02',Survey3DData,MorphedMeshes);
Survey3DData = flatten_3D_annotations('BCI03',Survey3DData,MorphedMeshes);

%% BEYOND THIS POINT IS FOR PAPER ONLY, COMPARING TO OUR SPECIFIC 2D PF DATA
% extract 2D from saved file
load('Survey3D2DComp_Recent_BCI.mat','Survey3D2DComp');

% reconstruct pixel maps
for ddd = 1:length(Survey3DData)
    temp_palmar_2D = zeros(1200,1050);
    temp_dorsal_2D = zeros(1200,1050);
    
    if ~isempty(Survey3D2DComp(ddd).PalmarIdx_2D)
        all_cell_palmar = {cat(1,Survey3D2DComp(ddd).PalmarIdx_2D{:})};
        temp_palmar_2D(all_cell_palmar{1}) = 1;
        
        % figure
        % imshow(temp_palmar_2D)
        % title('PALMAR')
    end
    
    if ~isempty(Survey3D2DComp(ddd).DorsumIdx_2D)
        all_cell_dorsal = {cat(1,Survey3D2DComp(ddd).DorsumIdx_2D{:})};
        temp_dorsal_2D(all_cell_dorsal{1}) = 1;
        
        % figure
        % imshow(temp_dorsal_2D)
        % title('DORSAL')
    end

    Survey3DData(ddd).Palmar_2D = temp_palmar_2D;
    Survey3DData(ddd).Dorsal_2D = temp_dorsal_2D;

    Survey3DData(ddd).Palmar(Survey3DData(ddd).Palmar>0) = 1;
    Survey3DData(ddd).Dorsal(Survey3DData(ddd).Dorsal>0) = 1;
end
% save('survey3d_260126.mat','-v7.3','Survey3DData')

% jaccard computation
Survey3DData = compute_jaccard(Survey3DData);

% plot distribution of jaccard computation
% gotta do a column for what we're throwing out, tho? just chose max here
plot_jaccard_distribution(Survey3DData);

% show example images for 2D and 3D annotations for jaccard computation
plot_jaccard(Survey3DData,15);
plot_jaccard(Survey3DData,37);
plot_jaccard(Survey3DData,44);
plot_jaccard(Survey3DData,39);

% quantify oblique annotations for all subjects
% i.e. annotations which are invisible to camera or squashed in a 2D representation
Survey3DData = quantify_oblique_annotations(Survey3DData,MorphedMeshes);
plot_oblique_distribution(Survey3DData);
plot_obliqueness(Survey3DData,25);
plot_obliqueness(Survey3DData,30);
plot_obliqueness(Survey3DData,13);
