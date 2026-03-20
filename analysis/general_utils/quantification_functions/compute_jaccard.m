function Survey3DData = compute_jaccard(Survey3DData)
    [palmar_mask, dorsal_mask] = get_hand_masks();
    orig_size = size(palmar_mask);
    
    [palm_ref_img, ~, palm_ref_alpha] = imread('TopLayer-handpcontour.png');
    palm_ref_img = imresize(palm_ref_img, orig_size);
    palm_ref_alpha = imresize(palm_ref_alpha, orig_size);
    [dor_ref_img, ~, dor_ref_alpha] = imread('TopLayer-contour.png');

    for ddd = 1:length(Survey3DData)
        palmar_3D = Survey3DData(ddd).Palmar.* palmar_mask; % apply the appropriate mask to 3D
        palmar_2D = Survey3DData(ddd).Palmar_2D;
        dorsal_3D = Survey3DData(ddd).Dorsal.* dorsal_mask;
        dorsal_2D = Survey3DData(ddd).Dorsal_2D;

        % Jaccard index: area of overlap / area of union
        palm_sum = palmar_3D+palmar_2D;
        overlap_palm = sum(palm_sum==2,'all');
        union_palm = sum(palm_sum>0,'all');

        dorsum_sum = dorsal_3D+dorsal_2D;
        overlap_dorsum = sum(dorsum_sum==2,'all');
        union_dorsum = sum(dorsum_sum>0,'all');

        % divide-by-zero accommodation
        % if union_palm == 0
        %     union_palm = 1;
        % end
        % 
        % if union_dorsum == 0
        %     union_dorsum = 1;
        % end

        Survey3DData(ddd).Palmar_Jaccard = overlap_palm/union_palm; % palmar
        Survey3DData(ddd).Dorsal_Jaccard = overlap_dorsum/union_dorsum; % dorsal

        % throw out examples where there isn't any annotation for one of the maps...
        if sum(palmar_3D,'all')==0 || sum(palmar_2D,'all')==0
            Survey3DData(ddd).Palmar_Jaccard = NaN;
        end

        if sum(dorsal_3D,'all')==0 || sum(dorsal_2D,'all')==0
            Survey3DData(ddd).Dorsal_Jaccard = NaN;
        end
    end
end