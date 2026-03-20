function show_hotspots(cbx,eventData,three_dim,color_map,annotation_record,ax,bg)
    annotation_map = color_map.(bg.Buttons(find([bg.Buttons.Value])).Text);
    cla(ax)
    shape_viewer(three_dim.raw_verts,three_dim.faces,annotation_map,ax)

    if cbx.Value == 1
        [x,y,z] = sphere;
        fvc = surf2patch(x,y,z);
        RGB = orderedcolors("glow");
        RGB = RGB([1,2,4,6:end],:);
        % hotspots = annotation_record.(bg.Buttons(find([bg.Buttons.Value])).Text).hotspots;
        % for ii = 1:size(hotspots,1)
        %     hp = patch('vertices',fvc.vertices./250+hotspots(ii,:),'faces',fvc.faces,'parent',ax,'FaceVertexCData',RGB(ii,:),'FaceColor','flat','EdgeColor','none');
        %     material(hp,'dull')
        % end
    end
end