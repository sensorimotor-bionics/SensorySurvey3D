function [annotation_record, this_model, model_name] = extract_colormaps(subject,session,electrodes)
    base_paths = {};
    annotation_paths = {};
    annotation_record = struct();

    for sess = 1:length(session)
        % point to appropriate folder(s) based on subject and session details
        current_paths = dir(['Z:\\SessionData\' subject '\OpenLoopStim\' subject '.data.00' char(string(session(sess))) '\BCI*.json']);
        base_paths = [base_paths {current_paths.folder}];
        annotation_paths = [annotation_paths {current_paths.name}];
    end

    if length(annotation_paths)~=length(electrodes)
        this_model = '';
        model_name = '';
        return
    end

    for electrode = 1:length(electrodes)
        data = import_json([base_paths{electrode} '\' annotation_paths{electrode}]);
        electrode_num = electrodes(electrode);
        electrode_name = ['e_' char(string(electrode_num))];
    
        participant = data.participant;
        model_options =  data.config.models;
        sensation_types =  data.config.typeList;
        hide_scale = data.config.hideScaleValues;
        
        date = data.date;
        start_time = data.startTime;
        end_time = data.endTime;
        projected_fields = data.projectedFields;
        
        for pf = 1:length(projected_fields)
            projected_field = projected_fields(pf);
            this_model = projected_field.model;
            this_model(this_model==' ') = '';
            model_name = model_options.(this_model);
            model_name(model_name=='.') = '_';
            mesh_data = import_json([model_name '.json']);
            
            numverts = size(mesh_data.vertices,1);
            temp_field = zeros(numverts,1);
            temp_field(projected_field.vertices) = 1;
            
            if ~ismember(this_model,fieldnames(annotation_record))
                annotation_record.(this_model).vertices = mesh_data.vertices;
                annotation_record.(this_model).faces = mesh_data.faces;
                annotation_record.(this_model).filename = mesh_data.filename;
                
                % can't use electrode number directly as a field name
                annotation_record.(this_model).electrodes.(electrode_name).fields = temp_field; % vertex colors, not face colors...
                hotspot = projected_field.hotSpot;
                annotation_record.(this_model).electrodes.(electrode_name).hotspots = [hotspot.x, hotspot.y, hotspot.z];
                annotation_record.(this_model).electrodes.(electrode_name).naturalness = projected_field.naturalness;
                annotation_record.(this_model).electrodes.(electrode_name).pain = projected_field.pain;
                try
                    annotation_record.(this_model).electrodes.(electrode_name).qualities = {projected_field.qualities.type};
                catch
                    annotation_record.(this_model).electrodes.(electrode_name).qualities = {};
                end
            else
                if ~ismember(['e_' char(string(electrode_num))],fieldnames(annotation_record.(this_model).electrodes))
                    annotation_record.(this_model).electrodes.(electrode_name).fields = [];
                    annotation_record.(this_model).electrodes.(electrode_name).hotspots = [];
                    annotation_record.(this_model).electrodes.(electrode_name).naturalness = [];
                    annotation_record.(this_model).electrodes.(electrode_name).pain = [];
                    annotation_record.(this_model).electrodes.(electrode_name).qualities = {};
                end
                        
                annotation_record.(this_model).electrodes.(electrode_name).fields = cat(2,annotation_record.(this_model).electrodes.(electrode_name).fields,temp_field); % vertex colors, not face colors...
                hotspot = projected_field.hotSpot;
                annotation_record.(this_model).electrodes.(electrode_name).hotspots = cat(1,annotation_record.(this_model).electrodes.(electrode_name).hotspots,[hotspot.x, hotspot.y, hotspot.z]);
                annotation_record.(this_model).electrodes.(electrode_name).naturalness = cat(1,annotation_record.(this_model).electrodes.(electrode_name).naturalness,projected_field.naturalness);
                annotation_record.(this_model).electrodes.(electrode_name).pain = cat(1,annotation_record.(this_model).electrodes.(electrode_name).pain,projected_field.pain);
                
                try
                    annotation_record.(this_model).electrodes.(electrode_name).qualities = [annotation_record.(this_model).electrodes.(electrode_name).qualities projected_field.qualities.type];
                catch
                end
            end
        end
    end
end