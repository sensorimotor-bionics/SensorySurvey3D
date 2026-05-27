function quality_change(qcbx,eventData,three_dim,ax,cbx,Survey3DData,bg)
    cla(ax)

    % check the relevant qualities
    bText = bg.Buttons(find([bg.Buttons.Value])).Text;
    eText = getEText(bText);
    this_electrode = find(strcmp({Survey3DData.ElectrodeID},eText)); % which rows correspond to selected electrode
    nodes = eventData.LeafCheckedNodes;

    if ~isempty(nodes)
        qualities = {nodes.Text};

        combFields = zeros(size(Survey3DData(1).Model.vertices,1),1);
        for d = 1:length(this_electrode)
            if ischar(Survey3DData(this_electrode(d)).binaryMap)
                continue
            end
            for q = 1:length(qualities)
                combFields = combFields + Survey3DData(this_electrode(d)).binaryQualities.(qualities{q});
            end
        end
        combFields(combFields>0) = 1; %for now, just binarily add up all the maps
    
        shape_viewer(three_dim.raw_verts,three_dim.faces,combFields,ax)
    else
        shape_viewer(three_dim.raw_verts,three_dim.faces,0,ax)
    end
end