function Survey3DDataRecord = revise_colormaps(Survey3DDataRecord)
    all_fields = fieldnames(Survey3DDataRecord);
    qualities = all_fields(find(strcmp(all_fields,'ModelName'))+1:end-1);

    for this_row = 1:length(Survey3DDataRecord)
        appropriate_fields = [];
        for q = 1:length(qualities)
            which_occupied = ~cellfun(@isempty,{Survey3DDataRecord(this_row).(qualities{q})});
            if sum(which_occupied)
                appropriate_fields = cat(2,appropriate_fields,cell2mat(cellfun(@(x) x.fields,{Survey3DDataRecord(this_row).(qualities{q})},'UniformOutput',false)));
            end
        end
        
        temp = nanmean(appropriate_fields,2);
        if max(temp)>0
            temp = temp./max(temp);
        end
        Survey3DDataRecord(this_row).ColorMap = temp;
    end
end