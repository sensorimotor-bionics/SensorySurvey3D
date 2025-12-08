function annotation_viewer(Survey3DData,unique_documented_electrodes,qualities,three_dim)
    fig = uifigure('Name','Annotation Viewer','Position',[0 0 660 max([size(unique_documented_electrodes,2)*23,400])]);
    p = uipanel(fig,'Position',[10 10 400 max([size(unique_documented_electrodes,2)*22,380])]);
    ax = uiaxes(p,'Position',[10 10 380 max([size(unique_documented_electrodes,2)*21,360])]);
    % title(ax,[subject ' Annotations'])
    % camorbit(ax,80,0,'data',[1 0 0]);

    % cbx = uicheckbox(fig,'Position',[430 size(unique_documented_electrodes,2)*21+10 130 20],'Text','Show Hotspots');
    uitextarea(fig,'Position',[420 max([size(unique_documented_electrodes,2)*21,360])+10 230 20],'Value','Parsed Electrode Details',...
        'FontWeight','bold','HorizontalAlignment','center','FontColor',[0 0.5 0.1]);
    cbx = [];
    bg = uibuttongroup(fig,'Position',[420 10 70 max([size(unique_documented_electrodes,2)*21,360])]);
    for ii = 1:size(unique_documented_electrodes,2)
        uiradiobutton(bg,'Position',[10 (ii-1)*20+10 91 15],'Text',unique_documented_electrodes{ii});
    end
    
    qcbx = uitree(fig,'checkbox','Position',[500 10 150 max([size(unique_documented_electrodes,2)*21,360])]);
    qcbx.CheckedNodesChangedFcn = {@quality_change,three_dim,ax,cbx,Survey3DData,bg};
    parent = uitreenode(qcbx,'Text','Qualities');
    for q = 1:length(qualities)
        uitreenode(parent,'Text',qualities{q});
    end
    expand(qcbx)
    
    % cbx.ValueChangedFcn = {@show_hotspots,three_dim,color_map,annotation_record,ax,bg};
    bg.SelectionChangedFcn = {@bselection,three_dim,ax,cbx,Survey3DData,qualities,qcbx};
    
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