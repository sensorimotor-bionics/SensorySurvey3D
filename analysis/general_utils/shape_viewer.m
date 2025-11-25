function shape_viewer(verts,faces,colors,who)
    h = who;
    hp = patch('vertices',verts,'faces',faces+1,'parent',h);
    hp.EdgeColor = 'none';
    hp.FaceVertexCData = colors;
    hp.FaceColor = 'flat';
    material(hp,[0.5 0.5 0.0 20 0.5]);

    ch = get(h,'children');
    lightExists = sum(arrayfun(@(x) contains(class(ch(x)),'Light'),1:length(ch)));
    supported_positions = [1 1 1;1 -1 1;-1 1 1;-1 -1 1];
    if ~lightExists
        for ii = 1:size(supported_positions,1)
            light('parent',h,'Position',supported_positions(ii,:)); 
        end
    end

    axis(h,'off'); axis(h,'equal');
    set(h,'Projection','perspective')
    set(h,'CameraUpVector',[0 1 0])
end
