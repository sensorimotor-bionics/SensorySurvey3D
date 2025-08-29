%% options
viewplot = false;
viewfinalplot = true;

%% import 2D and 3D meshes 
val = importjson("2D_mesh_data.json");
two_dim_verts = val.vertices;
two_dim_faces = val.faces;
region_data = importjson("2D_region_definitions.json");

val = importjson("Male_Hands_R_rm_5000_glb.json");
three_dim_verts = val.vertices;
three_dim_faces = val.faces;

%% import model landmarks
landmarks = {"Tend","Tpip","Tmcp",...
    "Iend","Idip","Ipip","Imcp",...
    "Mend","Mdip","Mpip","Mmcp",...
    "Rend","Rdip","Rpip","Rmcp",...
    "Pend","Pdip","Ppip","Pmcp",...
    "MpP","MpD","WuT","WuP", "EoW"};
landmark_2D = importjson("2D_model_procrustes_keypoints.json");
landmark_3D = importjson("3D_model_procrustes_keypoints.json");

%% plotting 3d model landmarks
all_3d = plotmodellandmarks('3D Model Landmarks',landmark_3D,viewplot);

%% plotting 2d model landmarks
all_2d = plotmodellandmarks('2D Model Landmarks',landmark_2D,viewplot);

%% 3d mesh dibs assignment
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

if viewplot
    figure
    hold on
    axis equal
    for l = 1:length(landmarks)
        plot3(three_dim_verts(dibs==l,1),three_dim_verts(dibs==l,2),three_dim_verts(dibs==l,3),'.')
    end
end

%% 2D vs 3D skeletal plotting and alignment tests:

% initial procrustin'
% Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
[d,Z,transform] = procrustes(all_2d,all_3d);

if viewplot
    figure
    hold on
    plot3(all_2d(:,1),all_2d(:,2),all_2d(:,3),'r.','MarkerSize',30)
    axis equal
    plot3(Z(:,1),Z(:,2),Z(:,3),'b.','MarkerSize',30)
    axis equal
end

% start with ordinary procrustes transformation calculation, then overlay the two whole meshes
three_dim_verts = transform.b*three_dim_verts*transform.T+transform.c(1,:);

if viewplot
    figure
    hold on
    plot3(three_dim_verts(:,1),three_dim_verts(:,2),three_dim_verts(:,3),'.')
    plot3(two_dim_verts(:,1),two_dim_verts(:,2),two_dim_verts(:,3),'.','MarkerSize',30)
    axis equal
end

% iterative procrustin' landmark order, for reference
% landmarks = {"Tend","Tpip","Tmcp",...
%     "Iend","Idip","Ipip","Imcp",...
%     "Mend","Mdip","Mpip","Mmcp",...
%     "Rend","Rdip","Rpip","Rmcp",...
%     "Pend","Pdip","Ppip","Pmcp",...
%     "MpP","MpD","WuT","WuP", "EoW"};

landmark_translator = [15,1,2,16,3,4,5,17,6,7,8,18,9,10,11,19,12,13,14,20,21,22,23,24];
dgt_grouper = {1:3,4:7,8:11,12:15,16:19};
all_3d = Z;

%% fixing finger flexion by joint:

for dgt = 1:5
    % progressing from mcp > pip, pip > dip, dip > end, straighten fingers, rotating all else out from the joint
    % 1. rotate mcp and up--dibs(1:end)--about mcp
    % 2. rotate pip and up--dibs(1:end-1)--about pip
    % 3. rotate dip and end--dibs(1:end-2)--about dip

    for joint = 1:length(dgt_grouper{dgt})-1
        offset_for_rot = all_3d(landmark_translator(dgt_grouper{dgt}(end-joint+1)),:);

        % find the vector of this joint in the 3d model
        % ignoring x, find vector from e.g. mcp to pip
        joint_3d = diff(all_3d(landmark_translator([dgt_grouper{dgt}(end-joint+1),dgt_grouper{dgt}(end-joint)]),:));
        no_flexion = joint_3d;

        % find angle between that vector and a vector with no z component
        no_flexion(3) = 0;

        if joint_3d(3)<0
            ang = -acosd(dot(joint_3d(2:3),no_flexion(2:3))/(sqrt(dot(joint_3d(2:3),joint_3d(2:3)))*sqrt(dot(no_flexion(2:3),no_flexion(2:3)))));
        else
            ang = acosd(dot(joint_3d(2:3),no_flexion(2:3))/(sqrt(dot(joint_3d(2:3),joint_3d(2:3)))*sqrt(dot(no_flexion(2:3),no_flexion(2:3)))));
        end

        Rx = [1 0 0; 0 cosd(ang) -sind(ang); 0 sind(ang) cosd(ang)];
        where_dibs = ismember(dibs,dgt_grouper{dgt}(1:end-joint+1));
        how_much_dibs = dibs_valence(where_dibs);
        new_verts = (three_dim_verts(where_dibs,:)-offset_for_rot)*Rx+offset_for_rot;
        three_dim_verts(where_dibs,:) = new_verts;
        all_3d(landmark_translator(dgt_grouper{dgt}(1:end-joint)),:) = (all_3d(landmark_translator(dgt_grouper{dgt}(1:end-joint)),:)-offset_for_rot)*Rx+offset_for_rot;
    end
end

if viewplot
    figure
    hold on
    plot3(three_dim_verts(:,1),three_dim_verts(:,2),three_dim_verts(:,3),'.')
    plot3(all_3d(:,1),all_3d(:,2),all_3d(:,3),'*')
    % plot3(two_dim_verts(:,1),two_dim_verts(:,2),two_dim_verts(:,3),'.','MarkerSize',30)
    axis equal
end

%% iteratively adjust medial axis segment lengths:

for dgt = 1:5
    for joint = 1:length(dgt_grouper{dgt})-1
        offset_for_proj = all_3d(landmark_translator(dgt_grouper{dgt}(end-joint+1)),:);

        joint_3d = diff(all_3d(landmark_translator([dgt_grouper{dgt}(end-joint+1),dgt_grouper{dgt}(end-joint)]),:)); % vector from anchor to next landmark, 3D
        joint_2d = diff(all_2d(landmark_translator([dgt_grouper{dgt}(end-joint+1),dgt_grouper{dgt}(end-joint)]),:)); % vector from anchor to next landmark, 2D
        joint_length_2d = sqrt(sum(joint_2d.^2));
        joint_length_3d = sqrt(sum(joint_3d.^2));
        discrepancy = joint_length_2d/joint_length_3d;

        % shifting all other 3d mesh points depends upon the position of each point along the joint_3d axis
        % only consider points within this segment, don't bother to fix the others at the moment...
        
        % identify vertices for scaling
        where_dibs = ismember(dibs,dgt_grouper{dgt}(end-joint+1));
        idx_dibs = find(where_dibs);
        scaling_verts = three_dim_verts(where_dibs,:);

        for this_vert = 1:size(scaling_verts,1)
            % compute projection
            % how do we handle a projection which projects behind? for now, ignore
            projection = dot(scaling_verts(this_vert,:)-offset_for_proj,joint_3d)/norm(joint_3d)^2*joint_3d;
            projection_length = sqrt(sum(projection.^2));

            ang = acosd(dot(joint_3d,projection)/(sqrt(dot(joint_3d,joint_3d))*sqrt(dot(projection,projection))));
            if abs(abs(ang)-180)>abs(ang) % aligned
                new_position = discrepancy*joint_length_3d*(projection_length/joint_length_3d)*joint_3d/norm(joint_3d);

                % update the vertex with scaling
                % remember, must scale outward from the anchor landmark
                three_dim_verts(idx_dibs(this_vert),:) = (new_position-projection)+scaling_verts(this_vert,:);
            end
        end

        % will also need to adjust landmarks as we scale
        all_3d(landmark_translator(dgt_grouper{dgt}(end-joint)),:) = discrepancy*joint_length_3d*joint_3d/norm(joint_3d)+offset_for_proj;
        where_dibs = ismember(dibs,dgt_grouper{dgt}(1:end-joint));
        discrepancy_vector = (joint_length_3d-joint_length_2d)*joint_3d/norm(joint_3d);
        three_dim_verts(where_dibs,:) = three_dim_verts(where_dibs,:)-discrepancy_vector;
        all_3d(landmark_translator(dgt_grouper{dgt}(1:end-joint-1)),:) = all_3d(landmark_translator(dgt_grouper{dgt}(1:end-joint-1)),:)-discrepancy_vector;
    end
end

%% fixing finger abduction joint by joint:

for dgt = 1:5
    for joint = 1:length(dgt_grouper{dgt})-1
        % match mcp
        mcp_disc = all_3d(landmark_translator(dgt_grouper{dgt}(end-joint+1)),:)-all_2d(landmark_translator(dgt_grouper{dgt}(end-joint+1)),:);
        mcp_disc(3) = 0;
        offset_for_rot = all_3d(landmark_translator(dgt_grouper{dgt}(end-joint+1)),:);

        % find the vector from between joints for each model
        mcp_end_3d = diff(all_3d(landmark_translator([dgt_grouper{dgt}(end-joint+1),dgt_grouper{dgt}(end-joint)]),:));
        mcp_end_2d = diff(all_2d(landmark_translator([dgt_grouper{dgt}(end-joint+1),dgt_grouper{dgt}(end-joint)]),:));

        % ignoring "z", calculate the angle of adduction/abduction
        if mcp_end_3d(1)>mcp_end_2d(1)
            ang = -acosd(dot(mcp_end_3d(1:2),mcp_end_2d(1:2))/(sqrt(dot(mcp_end_3d(1:2),mcp_end_3d(1:2)))*sqrt(dot(mcp_end_2d(1:2),mcp_end_2d(1:2)))));
        else
            ang = acosd(dot(mcp_end_3d(1:2),mcp_end_2d(1:2))/(sqrt(dot(mcp_end_3d(1:2),mcp_end_3d(1:2)))*sqrt(dot(mcp_end_2d(1:2),mcp_end_2d(1:2)))));
        end

        % determine the rotation matrix for that angle
        Rz = [cosd(ang) -sind(ang) 0; sind(ang) cosd(ang) 0; 0 0 1];
        where_dibs = ismember(dibs,dgt_grouper{dgt}(1:end-joint+1));
        how_much_dibs = dibs_valence(where_dibs);
        new_verts = (three_dim_verts(where_dibs,:)-offset_for_rot)*Rz+offset_for_rot-mcp_disc;
        three_dim_verts(where_dibs,:) = new_verts;
        all_3d(landmark_translator(dgt_grouper{dgt}(1:end-joint+1)),:) = (all_3d(landmark_translator(dgt_grouper{dgt}(1:end-joint+1)),:)-offset_for_rot)*Rz+offset_for_rot-mcp_disc;
    end
    mcp_disc = all_3d(landmark_translator(dgt_grouper{dgt}(1)),:)-all_2d(landmark_translator(dgt_grouper{dgt}(1)),:);
    mcp_disc(3) = 0;
    where_dibs = ismember(dibs,dgt_grouper{dgt}(1));
    three_dim_verts(where_dibs,:) = three_dim_verts(where_dibs,:)-mcp_disc;
    all_3d(landmark_translator(dgt_grouper{dgt}(1)),:) = all_3d(landmark_translator(dgt_grouper{dgt}(1)),:)-mcp_disc;
end

if viewfinalplot
    figure
    hold on
    plot3(three_dim_verts(:,1),three_dim_verts(:,2),three_dim_verts(:,3),'.')
    plot3(all_3d(:,1),all_3d(:,2),all_3d(:,3),'*')
    plot3(two_dim_verts(:,1),two_dim_verts(:,2),two_dim_verts(:,3),'o','MarkerSize',10)
    plot3(all_2d(:,1),all_2d(:,2),all_2d(:,3),'^')
    axis equal
end