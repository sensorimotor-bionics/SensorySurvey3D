function disp_shape_single(verts,faces,colors,front_dist,back_dist)
    for persp = 1:2
        h = subplot(1,2,persp);
        temp_verts = verts;

        if persp == 1
            temp_verts(:,3) = verts(:,3)+back_dist;
        elseif persp == 2
            temp_verts(:,3) = verts(:,3)+front_dist;
        end
        
        hp = patch('vertices',temp_verts,'faces',faces+1,'parent',h); hold(h,'on');
        hp.EdgeColor = 'none'; 
        hp.FaceColor = 'flat';
        hp.FaceVertexCData = colors;
        hp.FaceLighting = 'flat';
        material(hp,[0.5 0.5 0.0 20 0.5]);

        if sum(colors)==0
            colormap([0,0,0])
        else
            colormap('gray')
        end
    
        ch = get(h,'children');
        lightExists = sum(arrayfun(@(x) contains(class(ch(x)),'Light'),1:length(ch)));
        supported_positions = [1 1 1; 1 1 -1; 1 -1 1; 1 -1 -1; -1 1 1; -1 1 -1; -1 -1 1; -1 -1 -1];
        if ~lightExists
            for ii = 1:size(supported_positions,1)
                light('parent',h,'Position',supported_positions(ii,:)); 
            end
        end
        
        axis(h,'off'); axis(h,'equal');
        set(h,'Projection','orthographic')
        set(h,'CameraUpVector',[0 1 0])

        if persp == 2
            set(h,'CameraPosition',h.CameraPosition.*[1 1 -1])
        end
    end
end
