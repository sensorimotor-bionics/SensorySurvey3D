function val = import_json(fname,create_landmark_report)
    fid = fopen(fname); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    val = jsondecode(str);
    old_val = val;

    if create_landmark_report
        try
            % if landmarks saved using app and not stored manually
            all_names = {val.landmarks.name};
            all_x = {val.landmarks.x};
            all_y = {val.landmarks.y};
            all_z = {val.landmarks.z};
            clear val

            for ii = 1:length(all_names)
                val.(all_names{ii}) = [all_x{ii};all_y{ii};all_z{ii}];
            end
        catch
            val = old_val;
        end
    end
end