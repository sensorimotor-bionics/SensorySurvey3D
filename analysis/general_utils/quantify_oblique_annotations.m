function [three_dim, oblique_proportion] = quantify_oblique_annotations(subject,three_dim,documented_electrodes,color_map)
    % first, calculate the area of each face
    for f = 1:size(three_dim.faces)
        verts = three_dim.verts(three_dim.faces(f,:)+1,:);
        % magnitude of cross product is the positive area of the parallelogram having A and B as sides
        A = verts(2,:)-verts(1,:);
        B = verts(3,:)-verts(1,:);
        three_dim.face_area(f) = norm(cross(A,B))/2;
    end
    
    oblique_proportion = nan(64,1);
    
    for ele = 1:length(documented_electrodes)
        this_ele = documented_electrodes{ele};
        foo = split(this_ele,'_');
    
        this_map = color_map.(this_ele);
        annotated_faces = sum(ismember(three_dim.faces,find(this_map>0)),2)==3;
    
        % sum areas of oblique faces which are annotated
        oblique_area = sum(three_dim.face_area(annotated_faces&three_dim.oblique));
        % sum areas of camera-facing faces which are annotated
        non_oblique_area = sum(three_dim.face_area(annotated_faces&~three_dim.oblique));
        % calculate proportion of annotated area that is oblique
        oblique_proportion(double(string(cell2mat(foo(2))))) = oblique_area/(oblique_area+non_oblique_area);
    end
    
    figure;
    histogram(oblique_proportion(~isnan(oblique_proportion)),0:.2:1)
    xlabel('proportion of annotation occluded')
    ylabel('number of electrodes')
    title('3D annotation visibility')
    saveas(gcf,[subject '_annotation_visibility.svg'])
    
    for ele = 1:length(documented_electrodes)
        try
            this_ele = documented_electrodes{ele};
            foo = split(this_ele,'_');
        
            figure; set(gcf,'position',[0,0,1109,600])
            subplot(1,2,1); hold on
            axis tight; axis equal
            subplot(1,2,2); hold on
            axis tight; axis equal
        
            disp_shape_single(three_dim.verts_flat,three_dim.faces,color_map.(this_ele),0,0);
        
            sgtitle([foo(2) ['proportion occluded: ' char(string(round(oblique_proportion(double(string(foo(2)))),2)))]])
            saveas(gcf,[subject '_occlusion_electrode_' char(foo(2)) '.png'])
        catch
        end
        close all
    end
end