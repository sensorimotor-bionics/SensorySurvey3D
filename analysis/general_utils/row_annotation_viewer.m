function row_annotation_viewer(Survey3DData,qualities,three_dim)
    numrows = size(Survey3DData,2);

    fig = uifigure('Name','Rowwise Annotation Viewer','Position',[0 0 660 max([numrows*23,400])]);
    p = uipanel(fig,'Position',[10 10 400 max([numrows*22,380])]);
    ax = uiaxes(p,'Position',[10 10 380 max([numrows*21,360])]);
    % title(ax,[subject ' Annotations'])
    % camorbit(ax,80,0,'data',[1 0 0]);

    uitextarea(fig,'Position',[420 max([numrows*21,360])+10 230 20],'Value','Parsed File Details',...
        'FontWeight','bold','HorizontalAlignment','center','FontColor',[0 0.5 0.1]);

    
    bg = uibuttongroup(fig,'Position',[420 10 230 max([numrows*21,360])]);
    for ii = 1:numrows
        uiradiobutton(bg,'Position',[10 (numrows-ii)*20+10 91 15],'Text',Survey3DData(ii).Annotation(end-12:end));
    end
    
    bg.SelectionChangedFcn = {@rselection,three_dim,ax,Survey3DData,qualities};
    
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