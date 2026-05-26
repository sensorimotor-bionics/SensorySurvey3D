function rselection(bg,eventData,three_dim,ax,Survey3DData,qualities,default_pos)
    ax.CameraPosition = default_pos;
    if isa(ax.Children(1),'matlab.graphics.primitive.Patch')
        delete(ax.Children(1))
    elseif isa(ax.Children(end),'matlab.graphics.primitive.Patch')
        delete(ax.Children(end))
    end

    this_row = find([bg.Buttons.Value]); % which rows correspond to selected electrode

    combFields = zeros(size(Survey3DData(1).Model.vertices,1),1);
    if ~ischar(Survey3DData(this_row).binaryMap)
        combFields = Survey3DData(this_row).binaryMap;
    end
    shape_viewer(three_dim.raw_verts,three_dim.faces,combFields,ax)

end