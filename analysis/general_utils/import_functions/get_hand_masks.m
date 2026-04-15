function [palmar_mask, dorsum_mask] = get_hand_masks()
    % Palm mask
    palmar_template = imread(".\reference images\palm_right.png");
    orig_size = size(palmar_template);
    bw_image = imbinarize(palmar_template); 
    bw_image = bw_image(:,:,1);
    [B, ~, ~] = bwboundaries(bw_image, 'holes');
    image_boundary = B{6}; % hand outline
    mask = poly2mask(image_boundary(:,2), image_boundary(:,1), orig_size(1), orig_size(2));
    mask = imfill(mask(1:1100, :), [600 525], 8); % Fill above wrist
    palmar_mask = cat(1, mask, zeros(100, orig_size(2))); % Return to original size

    % Dorsum mask
    dorsal_template = imread(".\reference images\dorsum_right.png");
    orig_size = size(dorsal_template);
    bw_image = imbinarize(dorsal_template); 
    bw_image = bw_image(:,:,1);
    [B, ~, ~] = bwboundaries(bw_image, 'holes');
    image_boundary = B{5}; % hand outline
    mask = poly2mask(image_boundary(:,2), image_boundary(:,1), orig_size(1), orig_size(2));
    mask = imfill(mask(1:1100, :), [600 525], 8); % Fill above wrist
    dorsum_mask = cat(1, mask, zeros(100, orig_size(2))); % Return to original size
end