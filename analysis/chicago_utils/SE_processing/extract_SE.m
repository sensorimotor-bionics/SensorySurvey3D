function extract_SE(session_path,set_ids,output_directory,info)

    c_max = 4; % Just define the number of channels in a set (for padding purposes)

    log_sess = info{1};
    subid = info{2};
    subject_id = info{3};
    session_str = info{4};
    elec_log = info{5};

    current_paths = dir([char(session_path),'\Survey3D*.json']);

    remSets = set_ids;
    SurveyData = struct();
    ii = 0;
    for s = 1:length(current_paths)
        base_path = current_paths(s).folder;
        annotation_path = current_paths(s).name;
        data = import_json([base_path '\' annotation_path],false);
        
        set = data.setNum;
        %Skip sets not in the requested set list
        if ~ismember(set,set_ids)
            warning(sprintf('Filtering out set %d: not requested.\n', set));
            continue;
        else
            remSets(remSets == set) = [];
        end

        setData = import_json(sprintf('%s\\SensoryExecutiveTaskState.Set%04d_Summary.json',base_path,set),false);
        if ~((setData.amplitude == 60) & (setData.frequency == 100))
            warning(sprintf('Filtering out set %d: not run at 60 uA and 100 Hz.\n', set));
            continue;
        end

        ii = ii + 1;
        channels = zeros(c_max,1);
        channels(1:length(setData.pre_set.electrodes)) = setData.pre_set.electrodes;

        SurveyData(ii).Subject = subject_id;
        SurveyData(ii).Session = log_sess;
        SurveyData(ii).Date = data.date;
        SurveyData(ii).Set = data.setNum;
        SurveyData(ii).StartTime = data.startTime;
        SurveyData(ii).EndTime = data.endTime;
        SurveyData(ii).Ch1 = channels(1);
        SurveyData(ii).Ch2 = channels(2);
        SurveyData(ii).Ch3 = channels(3);
        SurveyData(ii).Ch4 = channels(4);
        SurveyData(ii).ElectrodeID = sprintf('e_%d_%d_%d_%d',channels(1),channels(2),channels(3),channels(4));
        SurveyData(ii).Amp = setData.amplitude;
        SurveyData(ii).Freq = setData.frequency;
        SurveyData(ii).PW = setData.pulse_width;
        SurveyData(ii).Dur = setData.duration;
        SurveyData(ii).PRat = setData.phase_ratio;
        SurveyData(ii).IPI = setData.IPI;
        SurveyData(ii).CatFirst = setData.cat_first;
        SurveyData(ii).Base = base_path;
        SurveyData(ii).Annotation = annotation_path;
        

        model = struct();
        model_options =  data.config.models;
        projected_fields = data.projectedFields;

        configQualities = data.config.qualityTypes;
        numQual = size(configQualities,1);
        for q = 1:numQual
            currQual = configQualities{q,1};
            currQual(currQual==' ') = '_';
            currQual = [upper(currQual(1)) lower(currQual(2:end))];
            qualNames{q} = currQual;
        end
        qualNames{numQual + 1} = 'Unspecified';
        qualNames{numQual + 2} = 'No_report';

        numPF = length(projected_fields);

        if numPF == 0
            SurveyData(ii).NumSense = 0;
            for q = 1:numQual+2
                SurveyData(ii).PFQualities.(qualNames{q}) = [];
            end
            SurveyData(ii).PFQualities.No_report = true;
            SurveyData(ii).Model = 'No_Report';
            SurveyData(ii).ModelName = 'No_Report';
            SurveyData(ii).PFBasics = 'No_Report';
            continue
        end

        % Go through pfs and make sure that they actually have vertices,
        % count and idx pfs with vertices
        numSense = 0;
        senseIdx = [];
        for pf = 1:numPF
            currPF = projected_fields(pf);
            if ~isempty(currPF.vertices)
                numSense = numSense + 1;
                senseIdx = [senseIdx pf];
            end
        end
        % If none of them have vertices, it's an empty report
        if numSense == 0
            SurveyData(ii).NumSense = 0;
            for q = 1:numQual+2
                SurveyData(ii).PFQualities.(qualNames{q}) = [];
            end
            SurveyData(ii).PFQualities.No_report = true;
            SurveyData(ii).Model = 'No_Report';
            SurveyData(ii).ModelName = 'No_Report';
            SurveyData(ii).PFBasics = 'No_Report';
            continue
        end

        SurveyData(ii).NumSense = numSense;
        for ns = 1:numSense
            for q = 1:numQual+2
                SurveyData(ii).PFQualities(ns).(qualNames{q}) = [];
            end
        end

        for ns = 1:numSense
            currPF = projected_fields(senseIdx(ns));
            model.id = currPF.model;
            model.id(model.id==' ') = '';
            model.id(model.id=='(') = '_';
            model.id(model.id==')') = '_';
            model.name = model_options.(model.id);
            try
                model.name(model.name=='.') = '_';
            catch
                model.name = model.name.file;
                %model.name(model.name=='.') = '_';
                model.name(model.name=='/') = '_';
            end

            mesh_data = import_json([session_path '\' model.name '.json'],false);          
            numverts = size(mesh_data.vertices,1);

            currField = zeros(numverts,1);          
            currField(currPF.vertices+1) = 1;
            %currField(currPF.vertices~=0) = 1;
            
            if ns==1
                model.vertices = mesh_data.vertices;
                model.faces = mesh_data.faces;
                model.filename = mesh_data.filename;
                SurveyData(ii).Model = model;
                SurveyData(ii).ModelName = model.name;
            end

            savePF = struct();    
            savePF.fields = currField; % vertex colors, not face colors
            hotspot = currPF.hotSpot;
            savePF.hotspots = [hotspot.x, hotspot.y, hotspot.z];
            savePF.naturalness = currPF.naturalness;
            savePF.pain = currPF.pain;
            savePF.intensity = currPF.intensity;
            SurveyData(ii).PFBasics(ns) = savePF;

            % If nothing is drawn, label as no report and move on
            if sum(currField) == 0
                SurveyData(ii).PFQualities(ns).No_report = true;
                continue
            end

            numPFQual = size(currPF.qualities,1);
            if numPFQual == 0
                SurveyData(ii).PFQualities(ns).Unspecified = true;
            end
            for qPf = 1:numPFQual
                qType = currPF.qualities(qPf).type;
                qType(qType==' ') = '_';
                qType = [upper(qType(1)) lower(qType(2:end))];
                qData = rmfield(currPF.qualities(qPf),'type');
                SurveyData(ii).PFQualities(ns).(qType) = qData;
            end
        end
    end

    if length(remSets) > 0
        warning(sprintf('Set %d not found.\n', remSets));
    end


    save(fullfile(output_directory, subid, [session_str, '.mat']), "SurveyData")
    fprintf(' - Done!\n')

end