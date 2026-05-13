function pf_struct = ExtractPFs(raw_images, mask, segmenter)
    orig_size = size(mask);
    SE_big = strel("disk", 20); % Structure Element for closing, Int for pixel radius (minimum size)
    SE_small = strel("disk", 5); 

    running_map = zeros(orig_size); 
    num_images = length(raw_images);
    for i = 1:num_images
        im = raw_images{i};
        temp_im_size = size(im);
        
        % Trim black space around image (if there is any) - must do sequentialy
        bb_horz_idx = sum(sum(im, 3) == 0,2) > temp_im_size(2)*0.9; % Need a percentage to account for marks outside of boundary
        new_im = im(~bb_horz_idx,:,:);
        bb_vert_idx = sum(sum(new_im, 3) == 0,1) > temp_im_size(1)*0.9;
        new_im = new_im(:,~bb_vert_idx,:);
        % Resize image
        new_im = imresize(new_im, orig_size);

        % Extract non-BW values
        color_idx = var(double(new_im), 0, 3) > 0;
        
        % Find boundaries of color_idx
%         [B, ~, ~] = bwboundaries(color_idx, 'holes');
        color_regions = regionprops(color_idx, 'Centroid', 'PixelIdxList', 'FilledImage');
        % Apply to color mask
        color_idx = false(orig_size);
        for c = 1:size(color_regions,1)
            color_idx_temp = false(orig_size);
            color_idx_temp(color_regions(c).PixelIdxList) = true;
            color_idx_temp = imclose(color_idx_temp, SE_big);
            color_idx(color_idx_temp) = true;
        end
        color_idx = imfill(color_idx,'holes');
        color_idx = imclose(color_idx, SE_small); % Connect adjacent PFs

        % Mask to the hand mask
        color_masked = color_idx & mask;
        
        % Overlay all regions - add to running mask
        [B, ~, ~] = bwboundaries(color_masked, 'noholes'); % Don't allow hollow regions (somewhat redundant with imclose)
        for j = 1:size(B,1)
            roi_mask = poly2mask(B{j}(:,2), B{j}(:,1), orig_size(1), orig_size(2));
            overlay_masked = roi_mask & mask;
            running_map = running_map | overlay_masked;
        end
    end
    
    % Once all images have been processed, extract info
    pf_struct = regionprops(running_map, 'Centroid', 'PixelIdxList', 'Area', 'Eccentricity', 'Orientation', 'FilledImage', 'BoundingBox');
    % Now iterate through regions to get more features that regionprops can't
    if isempty(pf_struct)
        [pf_struct(i).Boundary, pf_struct(i).CentroidLocation, pf_struct(i).BoundaryLocations] = deal([]);
    else
        for i = 1:length(pf_struct)
            % Boundary
            [B, ~, ~] = bwboundaries(pf_struct(i).FilledImage, 'noholes'); % Need to use BWBoundaries to extract boundary that's better than ConvexHull 
            pf_struct(i).Boundary = [B{1}(:,2) + pf_struct(i).BoundingBox(1), B{1}(:,1) + pf_struct(i).BoundingBox(2)];
            % Segment
            centroid_idx = sub2ind(orig_size, round(pf_struct(i).Centroid(2)), round(pf_struct(i).Centroid(1))); % xy is reversed
            overlapping_pixels = false(size(segmenter,1),1);
            found_centroid = false;
            for j = 1:size(segmenter,1)
                % Centroid only
                if ismember(centroid_idx, segmenter(j).PixelIdxList)
                    pf_struct(i).CentroidLocation = segmenter(j).Tag;
                    found_centroid = true;
                end
                % Any overlap
                if any(ismember(pf_struct(i).PixelIdxList, segmenter(j).PixelIdxList))
                    overlapping_pixels(j) = true;
                end
            end
            if ~found_centroid
                [~, segment_idx] = min(sum(abs(pf_struct(i).Centroid - cat(1,segmenter.Centroid)),2));
                pf_struct(i).CentroidLocation = segmenter(segment_idx).Tag;
            end
            pf_struct(i).BoundaryLocations = {segmenter(overlapping_pixels).Tag};
        end
    end
    pf_struct = rmfield(pf_struct, {'BoundingBox', 'FilledImage'});
end