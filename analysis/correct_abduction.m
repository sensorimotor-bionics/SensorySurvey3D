function [three_dim_verts,all_3d] = correct_abduction(three_dim_verts,three_dim_faces,all_3d,all_2d,landmark_translator,dgt_grouper,dibs)
    ii = 1;    
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
            new_verts = (three_dim_verts(where_dibs,:)-offset_for_rot)*Rz+offset_for_rot-mcp_disc;
            three_dim_verts(where_dibs,:) = new_verts;
            all_3d(landmark_translator(dgt_grouper{dgt}(1:end-joint+1)),:) = (all_3d(landmark_translator(dgt_grouper{dgt}(1:end-joint+1)),:)-offset_for_rot)*Rz+offset_for_rot-mcp_disc;
        end
        mcp_disc = all_3d(landmark_translator(dgt_grouper{dgt}(1)),:)-all_2d(landmark_translator(dgt_grouper{dgt}(1)),:);
        mcp_disc(3) = 0;
        where_dibs = ismember(dibs,dgt_grouper{dgt}(1));
        three_dim_verts(where_dibs,:) = three_dim_verts(where_dibs,:)-mcp_disc;
        all_3d(landmark_translator(dgt_grouper{dgt}(1)),:) = all_3d(landmark_translator(dgt_grouper{dgt}(1)),:)-mcp_disc;

        % figure; set(gcf,'position',[0,0,1000,1000])
        % disp_shape_single(three_dim_verts,three_dim_faces)
        % axis equal
        % camorbit(-40,0,'data',[1 1 0])
        % drawnow  
        % refreshdata
        % frame = getframe(gcf);
        % img =  frame2im(frame);
        % [img,cmap] = rgb2ind(img,256);
        % if ii == 1
        %     imwrite(img,cmap,'animation.gif','gif','LoopCount',Inf,'DelayTime',.1);
        % else
        %     imwrite(img,cmap,'animation.gif','gif','WriteMode','append','DelayTime',.1);
        % end
        % ii = ii+1;
    end
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