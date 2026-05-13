function rselection(bg,eventData,three_dim,ax,Survey3DData,qualities,default_pos)
    ax.CameraPosition = default_pos;
    if isa(ax.Children(1),'matlab.graphics.primitive.Patch')
        delete(ax.Children(1))
    elseif isa(ax.Children(end),'matlab.graphics.primitive.Patch')
        delete(ax.Children(end))
    end

    this_row = find([bg.Buttons.Value]); % which rows correspond to selected electrode
    %appropriate_fields = [];

    appropriate_fields = zeros(size(Survey3DData(this_row).Model.vertices,1),1);
    for ns = 1:Survey3DData(this_row).NumSense
        currSens = Survey3DData(this_row).PFQualities(ns);
        currSens = rmfield(currSens,'No_report');
        if any(~structfun(@isempty,currSens))
            appropriate_fields = appropriate_fields + Survey3DData(this_row).PFBasics(ns).fields;
        end        
    end
    appropriate_fields(appropriate_fields>0) = 1; %for now, just binarily add up all the maps
    
    % for q = 1:length(qualities)
    %     which_occupied = ~cellfun(@isempty,{Survey3DData(this_row).(qualities{q})});
    %     if sum(which_occupied)
    %         appropriate_fields = cat(2,appropriate_fields,cell2mat(cellfun(@(x) x.fields,{Survey3DData(this_row).(qualities{q})},'UniformOutput',false)));
    %     end
    % end
    
    temp = nanmean(appropriate_fields,2);
    if max(temp)>0
        temp = temp./max(temp);
    end
    shape_viewer(three_dim.raw_verts,three_dim.faces,temp,ax)
end