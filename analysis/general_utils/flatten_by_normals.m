function [two_dim_verts_shifted, three_dim_verts_shifted] = flatten_by_normals(two_dim, three_dim, landmark_superset, which_side)
    three_dim_verts_flattened = three_dim.verts;
    
    for n = 1:size(three_dim.normals,1)
        this_face = three_dim.faces(n,:)+1;
        for v = 1:length(this_face)
            if three_dim.is_palmar(n)
                three_dim_verts_flattened(this_face(v),3) = 0.1;
            elseif three_dim.is_dorsal(n)
                three_dim_verts_flattened(this_face(v),3) = -0.1;
            else
                three_dim_verts_flattened(this_face(v),3) = 0;
            end
        end
    end

    if strcmp(which_side,"palmar")
        landmarks = import_json("2D_model_procrustes_keypoints_palm_tight.json",false);
        landmarks = import_model_landmarks(landmarks,landmark_superset);
        translation_adjustment = [90,30];
    elseif strcmp(which_side,"dorsal")
        landmarks = import_json("2D_model_procrustes_keypoints_dorsum_tight.json",false);
        landmarks = import_model_landmarks(landmarks,landmark_superset);
        translation_adjustment = [195,25];
    else
        translation_adjustment = [0,0];
    end

    scaling_factor = 1140/(max(landmarks(:,2))-min(landmarks(:,2)));
    two_dim_landmarks_shifted = landmarks;
    two_dim_landmarks_shifted(:,1) = (landmarks(:,1)-min(landmarks(:,1))).*scaling_factor+translation_adjustment(1);
    two_dim_landmarks_shifted(:,2) = (landmarks(:,2)-min(landmarks(:,2))).*scaling_factor+translation_adjustment(2);
    two_dim_landmarks_shifted(:,3) = landmarks(:,3).*scaling_factor;

    [~,two_dim_landmarks_shifted,transform] = procrustes(two_dim_landmarks_shifted,two_dim.landmarks); % Z = TRANSFORM.b * Y * TRANSFORM.T + TRANSFORM.c
    three_dim_verts_shifted = transform.b*three_dim_verts_flattened*transform.T+transform.c(1,:);
    three_dim.verts_flat = three_dim_verts_shifted;

    two_dim_verts_shifted = transform.b*two_dim.verts*transform.T+transform.c(1,:);
    two_dim.verts_flat = two_dim_verts_shifted;

    % ref_img_path = fullfile(pwd(), 'reference images');
    % [palmar_mask, dorsal_mask] = get_hand_masks();
    % mask_size = size(palmar_mask);
    % 
    % [palm_ref_img, ~, palm_ref_alpha] = imread(fullfile(ref_img_path, 'TopLayer-handpcontour.png'));
    % palm_ref_img = imresize(palm_ref_img, mask_size);
    % palm_ref_alpha = imresize(palm_ref_alpha, mask_size);
    % [dor_ref_img, ~, dor_ref_alpha] = imread(fullfile(ref_img_path, 'TopLayer-contour.png'));

    % if strcmp(which_side,"palmar")
    %     figure
    %     hold on
    %     image([mask_size(2),0],[mask_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    %     plot3(three_dim_verts_shifted(:,1),three_dim_verts_shifted(:,2),three_dim_verts_shifted(:,3),'.')
    %     axis equal
    %     h = gca;
    %     axis(h,'off'); axis(h,'equal');
    %     set(h,'Projection','perspective')
    %     set(h,'CameraUpVector',[0 1 0])
    %     set(h,'CameraPosition',h.CameraPosition.*[1 1 -1]);
    % 
    %     figure
    %     hold on
    %     image([mask_size(2),0],[mask_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    %     plot3(two_dim_verts_shifted(:,1),two_dim_verts_shifted(:,2),two_dim_verts_shifted(:,3),'.')
    %     axis equal
    %     h = gca;
    %     axis(h,'off'); axis(h,'equal');
    %     set(h,'Projection','perspective')
    %     set(h,'CameraUpVector',[0 1 0])
    %     set(h,'CameraPosition',h.CameraPosition.*[1 1 -1]);
    % elseif strcmp(which_side,"dorsal")
    %     figure
    %     hold on
    %     image([mask_size(2),0],[mask_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
    %     plot3(three_dim_verts_shifted(:,1),three_dim_verts_shifted(:,2),three_dim_verts_shifted(:,3),'.')
    %     axis equal
    %     h = gca;
    %     axis(h,'off'); axis(h,'equal');
    %     set(h,'Projection','perspective')
    %     set(h,'CameraUpVector',[0 1 0])
    %     set(h,'CameraPosition',h.CameraPosition.*[1 1 -1]);
    % 
    %     figure
    %     hold on
    %     image([mask_size(2),0],[mask_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
    %     plot3(two_dim_verts_shifted(:,1),two_dim_verts_shifted(:,2),two_dim_verts_shifted(:,3),'.')
    %     axis equal
    %     h = gca;
    %     axis(h,'off'); axis(h,'equal');
    %     set(h,'Projection','perspective')
    %     set(h,'CameraUpVector',[0 1 0])
    %     set(h,'CameraPosition',h.CameraPosition.*[1 1 -1]);
    % end
end
