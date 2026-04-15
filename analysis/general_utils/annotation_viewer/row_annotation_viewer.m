function row_annotation_viewer(Survey3DData,qualities,three_dim,subject,mesh_source)
    % a maximum of 30 entries per column, for cleanliness
    if size(Survey3DData,2) > 30
        num_per_column = 30;
        num_columns = ceil(size(Survey3DData,2)/30);
    else
        num_per_column = size(Survey3DData,2);
        num_columns = 1;
    end

    fig = uifigure('Name','Rowwise Annotation Viewer','Position',[0 0 660+(num_columns-1)*100 max([num_per_column*23,400])]);
    p = uipanel(fig,'Position',[10 10 400 max([num_per_column*22,380])]);
    ax = uiaxes(p,'Position',[10 10 380 max([num_per_column*21,360])]);
    title(ax,[subject ' ' mesh_source ' Annotations'], 'Interpreter', 'none')
    camorbit(ax,180,0,'data',[1 0 0]);
    camorbit(ax,45,0,'data',[0 1 0]);
    ax.NextPlot = 'add';
    default_pos = ax.CameraPosition;

    uitextarea(fig,'Position',[420 max([num_per_column*21,360])+10 230+(num_columns-1)*100 20],'Value','Parsed File Details',...
        'FontWeight','bold','HorizontalAlignment','center','FontColor',[0 0.5 0.1]);
    
    bg = uibuttongroup(fig,'Position',[420 10 230+(num_columns-1)*100 max([num_per_column*21,360])]);

    row_counter = 1;
    for col = 1:num_columns
        if num_columns == 1
            for ii = 1:size(Survey3DData,2)
                uiradiobutton(bg,'Position',[10+(col-1)*150 (num_per_column-ii)*20+10 91 15],'Text',Survey3DData(row_counter).Annotation(end-12:end));
                row_counter = row_counter+1;
            end
        elseif col == num_columns
            num_remaining = mod(size(Survey3DData,2),30);

            if num_remaining == 0
                for ii = 1:30
                    uiradiobutton(bg,'Position',[10+(col-1)*150 (num_per_column-ii)*20+10 91 15],'Text',Survey3DData(row_counter).Annotation(end-12:end));
                    row_counter = row_counter+1;
                end
            else
                for ii = 1:num_remaining
                    uiradiobutton(bg,'Position',[10+(col-1)*150 (num_per_column-ii)*20+10 91 15],'Text',Survey3DData(row_counter).Annotation(end-12:end));
                    row_counter = row_counter+1;
                end
            end
        else
            for ii = 1:30
                uiradiobutton(bg,'Position',[10+(col-1)*150 (num_per_column-ii)*20+10 91 15],'Text',Survey3DData(row_counter).Annotation(end-12:end));
                row_counter = row_counter+1;
            end
        end
    end

    bg.SelectionChangedFcn = {@rselection,three_dim,ax,Survey3DData,qualities,default_pos};
    
    this_row = find([bg.Buttons.Value]); % which rows correspond to selected electrode
    appropriate_fields = [];
    
    for q = 1:length(qualities)
        which_occupied = ~cellfun(@isempty,{Survey3DData(this_row).(qualities{q})});
        if sum(which_occupied)
            appropriate_fields = cat(2,appropriate_fields,cell2mat(cellfun(@(x) x.fields,{Survey3DData(this_row).(qualities{q})},'UniformOutput',false)));
        end
    end
    
    temp = nanmean(appropriate_fields,2);
    if max(temp)>0
        temp = temp./max(temp);
    end
    shape_viewer(three_dim.raw_verts,three_dim.faces,temp,ax)
end