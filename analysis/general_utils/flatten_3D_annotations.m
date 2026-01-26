function Survey3DDataRecord = flatten_3D_annotations(subject,Survey3DDataRecord,MorphedMeshes)
    %% view annotations on flattened 3D mesh
    disp(' ')
    disp('Converting palmar and dorsal fits to heatmaps.')
    [palmar_mask, ~] = get_hand_masks();

    this_subject = find(strcmp({Survey3DDataRecord.Subject},subject)); % which rows correspond to this subject
    Survey3DData = Survey3DDataRecord(this_subject); % exclude other subjects from dataset

    model_morphs = {MorphedMeshes.ModelName};
    which_models = {Survey3DData.ModelName};
    documented_electrodes = {Survey3DData.ElectrodeID};
    color_map = {Survey3DData.ColorMap};

    idx_record = 1:length(Survey3DDataRecord);
    these_idxs = idx_record(this_subject);

    for idx = 1:length(documented_electrodes)
        this_model = MorphedMeshes(strcmp(which_models{idx},model_morphs));
        [Survey3DDataRecord(these_idxs(idx)).Palmar,Survey3DDataRecord(these_idxs(idx)).Dorsal] = convert_3D_to_heatmap(this_model.ThreeDim,this_model.ThreeDimDorsum,documented_electrodes{idx},color_map{idx},size(palmar_mask));
        close all
    end
end