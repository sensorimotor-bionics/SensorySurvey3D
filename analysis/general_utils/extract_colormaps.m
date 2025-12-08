function OLS_struct = extract_colormaps(OLS_struct,idx)
    model = struct();
    base_path = OLS_struct(idx).Base;
    annotation_path = OLS_struct(idx).Annotation;
    electrode_num = OLS_struct(idx).Channel;

    data = import_json([base_path '\' annotation_path]);
    OLS_struct(idx).ElectrodeID = ['e_' char(string(electrode_num))];
    model_options =  data.config.models;
  
    OLS_struct(idx).Date = data.date;
    OLS_struct(idx).StartTime = data.startTime;
    OLS_struct(idx).EndTime = data.endTime;
    projected_fields = data.projectedFields;
    
    for pf = 1:length(projected_fields)
        this_projected_field = struct();
        projected_field = projected_fields(pf);
        model.id = projected_field.model;
        model.id(model.id==' ') = '';
        model.name = model_options.(model.id);
        try
            model.name(model.name=='.') = '_';
        catch
            model.name = model.name.file;
            model.name(model.name=='.') = '_';
        end
        mesh_data = import_json([model.name '.json']);
        
        numverts = size(mesh_data.vertices,1);
        temp_field = zeros(numverts,1);
        temp_field(projected_field.vertices) = 1;
        
        if pf==1
            model.vertices = mesh_data.vertices;
            model.faces = mesh_data.faces;
            model.filename = mesh_data.filename;
            OLS_struct(idx).Model = model;
        end
            
        this_projected_field.fields = temp_field; % vertex colors, not face colors
        hotspot = projected_field.hotSpot;
        this_projected_field.hotspots = [hotspot.x, hotspot.y, hotspot.z];
        this_projected_field.naturalness = projected_field.naturalness;
        this_projected_field.pain = projected_field.pain;
        try
            this_projected_field.qualities = {projected_field.qualities.type};
        catch
            this_projected_field.qualities = {'Unspecified'};
        end

        for q = 1:length(this_projected_field.qualities)
            try
                OLS_struct(idx).(this_projected_field.qualities{q}) = this_projected_field;
            catch
                temp = this_projected_field.qualities{q};
                temp(temp==' ') = '_';
                OLS_struct(idx).(temp) = this_projected_field;
            end
        end
    end
end