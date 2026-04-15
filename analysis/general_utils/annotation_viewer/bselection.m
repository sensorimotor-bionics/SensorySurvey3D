function bselection(bg,eventData,three_dim,ax,cbx,Survey3DData,qualities,qcbx,default_pos)
    ax.CameraPosition = default_pos;
    if isa(ax.Children(1),'matlab.graphics.primitive.Patch')
        delete(ax.Children(1))
    elseif isa(ax.Children(end),'matlab.graphics.primitive.Patch')
        delete(ax.Children(end))
    end

    % check the relevant qualities
    this_electrode = find(strcmp({Survey3DData.ElectrodeID},bg.Buttons(find([bg.Buttons.Value])).Text)); % which rows correspond to selected electrode
    appropriate_fields = [];
    qcbx.CheckedNodes = [];

    for q = 1:length(qualities)
        which_occupied = ~cellfun(@isempty,{Survey3DData(this_electrode).(qualities{q})});
        if sum(which_occupied)
            % check box and consider these fields in the overall display
            qcbx.CheckedNodes = cat(1,qcbx.CheckedNodes,qcbx.Children(1).Children(q));
            appropriate_fields = cat(2,appropriate_fields,cell2mat(cellfun(@(x) x.fields,{Survey3DData(this_electrode(which_occupied)).(qualities{q})},'UniformOutput',false)));
        end
    end

    temp = nanmean(appropriate_fields,2);
    if max(temp)>0
        temp = temp./max(temp);
    end
    shape_viewer(three_dim.raw_verts,three_dim.faces,temp,ax)

    % if cbx.Value == 1
    %     [x,y,z] = sphere;
    %     fvc = surf2patch(x,y,z);
    %     RGB = orderedcolors("glow");
    %     RGB = RGB([1,2,4,6:end],:);
    %     % hotspots = annotation_record.(bg.Buttons(find([bg.Buttons.Value])).Text).hotspots;
    %     % for ii = 1:size(hotspots,1)
    %     %     hp = patch('vertices',fvc.vertices./250+hotspots(ii,:),'faces',fvc.faces,'parent',ax,'FaceVertexCData',RGB(ii,:),'FaceColor','flat','EdgeColor','none');
    %     %     material(hp,'dull')
    %     % end
    % end
end