function Survey3DData = quantify_oblique_annotations(Survey3DData,MorphedMeshes)
    model_morphs = {MorphedMeshes.ModelName};
    which_models = {Survey3DData.ModelName};
    color_map = {Survey3DData.ColorMap};

    for idx = 1:length(Survey3DData)
        this_model = MorphedMeshes(strcmp(which_models{idx},model_morphs));

        % first, calculate the area of each face
        for f = 1:size(this_model.source.faces,1)
            verts = this_model.source.verts(this_model.source.faces(f,:)+1,:);
            % magnitude of cross product is the positive area of the parallelogram having A and B as sides
            A = verts(2,:)-verts(1,:);
            B = verts(3,:)-verts(1,:);
            this_model.source.face_area(f) = norm(cross(A,B))/2;
        end

        annotated_faces = sum(ismember(this_model.source.faces,find(color_map{idx}>0)),2)==3;

        % sum areas of oblique faces which are annotated
        oblique_area = sum(this_model.source.face_area(annotated_faces&this_model.source.oblique));
        % sum areas of camera-facing faces which are annotated
        non_oblique_area = sum(this_model.source.face_area(annotated_faces&~this_model.source.oblique));
        % calculate proportion of annotated area that is oblique
        Survey3DData(idx).Oblique_Proportion = oblique_area/(oblique_area+non_oblique_area);
    end
end