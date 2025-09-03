function [three_dim_verts,all_3d] = correct_flexion(three_dim_verts,all_3d,landmark_translator,dgt_grouper,dibs,viewplot)
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
end