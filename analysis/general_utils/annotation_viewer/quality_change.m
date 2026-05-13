function quality_change(qcbx,eventData,three_dim,ax,cbx,Survey3DData,bg)
    cla(ax)

    % check the relevant qualities
    this_electrode = find(strcmp({Survey3DData.ElectrodeID},bg.Buttons(find([bg.Buttons.Value])).Text)); % which rows correspond to selected electrode
    appropriate_fields = [];
    nodes = eventData.LeafCheckedNodes;

    if ~isempty(nodes)
        qualities = {nodes.Text};
    
        for q = 1:length(qualities)
            qualityPresent = false;
            combFields = zeros(size(Survey3DData(this_electrode(1)).Model.vertices,1),1);
            for ii = 1:length(this_electrode)
                for ns = 1:Survey3DData(this_electrode(ii)).NumSense
                    occupied = ~isempty(Survey3DData(this_electrode(ii)).PFQualities(ns).(qualities{q}));
                    if (occupied)
                        qualityPresent = true;
                        combFields = combFields + Survey3DData(this_electrode(ii)).PFBasics(ns).fields;
                    end
                end
                combFields(combFields>0) = 1; %for now, just binarily add up all the maps
                if (qualityPresent)
                    % check box and consider these fields in the overall display
                    %qcbx.CheckedNodes = cat(1,qcbx.CheckedNodes,qcbx.Children(1).Children(q));
                    appropriate_fields = cat(2,appropriate_fields,combFields);
                end
            end
            % which_occupied = ~cellfun(@isempty,{Survey3DData(this_electrode).(qualities{q})});
            % if sum(which_occupied)
            %     % consider these fields in the overall display
            %     appropriate_fields = cat(2,appropriate_fields,cell2mat(cellfun(@(x) x.fields,{Survey3DData(this_electrode(which_occupied)).(qualities{q})},'UniformOutput',false)));
            % end
        end
    
        temp = nanmean(appropriate_fields,2);
        if max(temp)>0
            temp = temp./max(temp);
        end

        shape_viewer(three_dim.raw_verts,three_dim.faces,temp,ax)
    else
        shape_viewer(three_dim.raw_verts,three_dim.faces,0,ax)
    end
end