function [three_dim_verts,all_3d] = correct_medial_axis(three_dim_verts,three_dim_faces,all_3d,all_2d,landmark_translator,dgt_grouper,dibs)
    ii = 1;    
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