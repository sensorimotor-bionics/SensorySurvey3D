function bselection(bg,eventData,three_dim,ax,cbx,Survey3DData,qualities,qcbx,default_pos,mode)
    ax.CameraPosition = default_pos;
    if isa(ax.Children(1),'matlab.graphics.primitive.Patch')
        delete(ax.Children(1))
    elseif isa(ax.Children(end),'matlab.graphics.primitive.Patch')
        delete(ax.Children(end))
    end

    % check the relevant qualities
    bText = bg.Buttons(find([bg.Buttons.Value])).Text;
    eText = getEText(bText);
    this_electrode = find(strcmp({Survey3DData.ElectrodeID},eText)); % which rows correspond to selected electrode
    qcbx.CheckedNodes = [];

    combFields = zeros(size(Survey3DData(1).Model.vertices,1),1);
    for d = 1:length(this_electrode)
        if ischar(Survey3DData(this_electrode(d)).BinaryMap)
            continue
        end
        if mode == "bin"
            combFields = combFields + Survey3DData(this_electrode(d)).BinaryMap;
        elseif mode == "freq"
            combFields = combFields + Survey3DData(this_electrode(d)).FreqMap;
        end
        for q = 1:length(qualities)-1
            if (sum(Survey3DData(this_electrode(d)).BinaryQualities.(qualities{q}),"all") > 0)
                qcbx.CheckedNodes = cat(1,qcbx.CheckedNodes,qcbx.Children(1).Children(q));
            end
        end
    end
    if sum(combFields,'all') == 0
        qcbx.CheckedNodes = cat(1,qcbx.CheckedNodes,qcbx.Children(1).Children(length(qualities)));
    end
    if mode == "bin"
        combFields(combFields>0) = 1; %for now, just binarily add up all the maps
    end

    shape_viewer(three_dim.raw_verts,three_dim.faces,combFields,ax)

end