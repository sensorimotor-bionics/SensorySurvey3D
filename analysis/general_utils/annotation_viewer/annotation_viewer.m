function annotation_viewer(Survey3DData,unique_documented_electrodes,qualities,three_dim,subject,mesh_source)
    % a maximum of 30 entries per column, for cleanliness
    if size(unique_documented_electrodes,2) > 30
        num_per_column = 30;
        num_columns = ceil(size(unique_documented_electrodes,2)/30);
    else
        num_per_column = size(unique_documented_electrodes,2);
        num_columns = 1;
    end

    fig = uifigure('Name','Annotation Viewer','Position',[0 0 660+(num_columns-1)*100 max([num_per_column*23,400])]);
    p = uipanel(fig,'Position',[10 10 400 max([num_per_column*22,380])]);
    ax = uiaxes(p,'Position',[10 10 380 max([num_per_column*21,360])]);
    title(ax,[subject ' ' mesh_source ' Annotations'], 'Interpreter', 'none')
    camorbit(ax,180,0,'data',[1 0 0]);
    camorbit(ax,45,0,'data',[0 1 0]);
    ax.NextPlot = 'add';
    default_pos = ax.CameraPosition;

    uitextarea(fig,'Position',[420 max([num_per_column*21,360])+10 230+(num_columns-1)*100 20],'Value','Parsed Electrode Details',...
        'FontWeight','bold','HorizontalAlignment','center','FontColor',[0 0.5 0.1]);
    cbx = [];
    bg = uibuttongroup(fig,'Position',[420 10 70+(num_columns-1)*100 max([num_per_column*21,360])]);

    electrode_counter = 1;
    for col = 1:num_columns
        if num_columns == 1
            for ii = 1:size(unique_documented_electrodes,2)
                uiradiobutton(bg,'Position',[10+(col-1)*100 (num_per_column-ii)*20+10 91 15],'Text',unique_documented_electrodes{electrode_counter});
                electrode_counter = electrode_counter+1;
            end
        elseif col == num_columns
            num_remaining = mod(size(unique_documented_electrodes,2),30);

            if num_remaining == 0
                for ii = 1:30
                    uiradiobutton(bg,'Position',[10+(col-1)*100 (num_per_column-ii)*20+10 91 15],'Text',unique_documented_electrodes{electrode_counter});
                    electrode_counter = electrode_counter+1;
                end
            else
                for ii = 1:num_remaining
                    uiradiobutton(bg,'Position',[10+(col-1)*100 (num_per_column-ii)*20+10 91 15],'Text',unique_documented_electrodes{electrode_counter});
                    electrode_counter = electrode_counter+1;
                end
            end
        else
            for ii = 1:30
                uiradiobutton(bg,'Position',[10+(col-1)*100 (num_per_column-ii)*20+10 91 15],'Text',unique_documented_electrodes{electrode_counter});
                electrode_counter = electrode_counter+1;
            end
        end
    end
    
    qcbx = uitree(fig,'checkbox','Position',[500+(num_columns-1)*100 10 150 max([num_per_column*21,360])]);
    qcbx.CheckedNodesChangedFcn = {@quality_change,three_dim,ax,cbx,Survey3DData,bg};
    parent = uitreenode(qcbx,'Text','Qualities');
    for q = 1:length(qualities)
        uitreenode(parent,'Text',qualities{q});
    end
    expand(qcbx)
    
    bg.SelectionChangedFcn = {@bselection,three_dim,ax,cbx,Survey3DData,qualities,qcbx,default_pos};
    
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
end