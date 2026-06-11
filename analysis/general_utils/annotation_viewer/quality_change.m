function quality_change(qcbx,eventData,three_dim,ax,cbx,Survey3DData,bg,mode)
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
                if mode == "bin"
                    combFields = combFields + Survey3DData(this_electrode(d)).binaryQualities.(qualities{q});
                elseif mode == "freq"
                    combFields = combFields + Survey3DData(this_electrode(d)).freqQualities.(qualities{q});
                end
            end
        end
        if mode == "bin"
            combFields(combFields>0) = 1; %for now, just binarily add up all the maps
        end
    
        shape_viewer(three_dim.raw_verts,three_dim.faces,combFields,ax)
    else
        shape_viewer(three_dim.raw_verts,three_dim.faces,0,ax)
    end
end