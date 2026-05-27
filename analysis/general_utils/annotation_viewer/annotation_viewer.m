function annotation_viewer(Survey3DData,unique_documented_electrodes,qualities,three_dim,subject,mesh_source)
    % a maximum of 30 entries per column, for cleanliness
    if size(unique_documented_electrodes,2) > 30
        num_per_column = 30;
        num_columns = ceil(size(unique_documented_electrodes,2)/30);
    else
        num_per_column = size(unique_documented_electrodes,2);
        num_columns = 1;
    end

    spacing = 10;
    panel_width = 400;
    col_width = 150;
    text_width = col_width - 9;
    qual_width = 150;

    text_xstart = panel_width + 2*spacing;
    qual_xstart = panel_width + 3*spacing;
    fig_width = panel_width + qual_width + 4*spacing;
   

    fig = uifigure('Name','Annotation Viewer','Position',[0 0 fig_width+(num_columns)*col_width max([num_per_column*23,panel_width])]);
    p = uipanel(fig,'Position',[spacing spacing panel_width max([num_per_column*22,380])]);
    ax = uiaxes(p,'Position',[spacing spacing panel_width-20 max([num_per_column*21,360])]);
    title(ax,[subject ' ' mesh_source ' Annotations'], 'Interpreter', 'none')
    camorbit(ax,180,0,'data',[1 0 0]);
    camorbit(ax,45,0,'data',[0 1 0]);
    ax.NextPlot = 'add';
    default_pos = ax.CameraPosition;

    
    uitextarea(fig,'Position',[text_xstart max([num_per_column*21,360])+10 spacing+qual_width+(num_columns)*col_width 20],'Value','Parsed Electrode Details',...
        'FontWeight','bold','HorizontalAlignment','center','FontColor',[0 0.5 0.1]);
    cbx = [];
    bg = uibuttongroup(fig,'Position',[text_xstart 10 (num_columns)*col_width max([num_per_column*21,360])]);

    electrode_counter = 1;
    for col = 1:num_columns
        if num_columns == 1
            for ii = 1:size(unique_documented_electrodes,2)
                buttonText = getBText(unique_documented_electrodes{electrode_counter});
                uiradiobutton(bg,'Position',[10+(col-1)*col_width (num_per_column-ii)*20+10 text_width 15],'Text',buttonText);
                electrode_counter = electrode_counter+1;
            end
        elseif col == num_columns
            num_remaining = mod(size(unique_documented_electrodes,2),30);

            if num_remaining == 0
                for ii = 1:30
                    buttonText = getBText(unique_documented_electrodes{electrode_counter});
                    uiradiobutton(bg,'Position',[10+(col-1)*col_width (num_per_column-ii)*20+10 text_width 15],'Text',buttonText);
                    electrode_counter = electrode_counter+1;
                end
            else
                for ii = 1:num_remaining
                    buttonText = getBText(unique_documented_electrodes{electrode_counter});
                    uiradiobutton(bg,'Position',[10+(col-1)*col_width (num_per_column-ii)*20+10 text_width 15],'Text',buttonText);
                    electrode_counter = electrode_counter+1;
                end
            end
        else
            for ii = 1:30
                buttonText = getBText(unique_documented_electrodes{electrode_counter});
                uiradiobutton(bg,'Position',[10+(col-1)*col_width (num_per_column-ii)*20+10 text_width 15],'Text',buttonText);
                electrode_counter = electrode_counter+1;
            end
        end
    end
    
    qcbx = uitree(fig,'checkbox','Position',[qual_xstart+(num_columns)*col_width 10 qual_width max([num_per_column*21,360])]);
    qcbx.CheckedNodesChangedFcn = {@quality_change,three_dim,ax,cbx,Survey3DData,bg};
    parent = uitreenode(qcbx,'Text','Qualities');
    for q = 1:length(qualities)
        uitreenode(parent,'Text',qualities{q});
    end
    expand(qcbx)
    
    bg.SelectionChangedFcn = {@bselection,three_dim,ax,cbx,Survey3DData,qualities,qcbx,default_pos};
    
    bText = bg.Buttons(find([bg.Buttons.Value])).Text;
    eText = getEText(bText);
    this_electrode = find(strcmp({Survey3DData.ElectrodeID},eText)); % which rows correspond to selected electrode
    qcbx.CheckedNodes = [];    

    combFields = zeros(size(Survey3DData(1).Model.vertices,1),1);
    for d = 1:length(this_electrode)
        if ischar(Survey3DData(this_electrode(d)).binaryMap)
            continue
        end
        combFields = combFields + Survey3DData(this_electrode(d)).binaryMap;
        for q = 1:length(qualities)-1
            if (sum(Survey3DData(this_electrode(d)).binaryQualities.(qualities{q}),"all") > 0)
                qcbx.CheckedNodes = cat(1,qcbx.CheckedNodes,qcbx.Children(1).Children(q));
            end
        end
    end
    if sum(combFields,'all') == 0
        qcbx.CheckedNodes = cat(1,qcbx.CheckedNodes,qcbx.Children(1).Children(length(qualities)));
    end
    combFields(combFields>0) = 1; %for now, just binarily add up all the maps

    shape_viewer(three_dim.raw_verts,three_dim.faces,combFields,ax)

end