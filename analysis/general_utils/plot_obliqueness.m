function plot_obliqueness(Survey3DData,row)
    if strcmp(Survey3DData(row).Subject,'BCI02')
        c = [1 1 1; .49 .44 .70];
    elseif strcmp(Survey3DData(row).Subject,'BCI03')
        c = [1 1 1; .91 .16 .54];
    end

    [palmar_mask, dorsal_mask] = get_hand_masks();
    orig_size = size(palmar_mask);
    
    [palm_ref_img, ~, palm_ref_alpha] = imread('TopLayer-handpcontour.png');
    palm_ref_img = imresize(palm_ref_img, orig_size);
    palm_ref_alpha = imresize(palm_ref_alpha, orig_size);
    [dor_ref_img, ~, dor_ref_alpha] = imread('TopLayer-contour.png');

    Survey3DData(row).Channel

    palmar_3D = Survey3DData(row).Palmar.* palmar_mask; % apply the appropriate mask to 3D
    dorsal_3D = Survey3DData(row).Dorsal.* dorsal_mask;

    figure; set(gcf,'position',[0,0,1200,1200])
    colormap(c)
    h = subplot(1,2,1);
    imagesc(flipud(dorsal_3D))
    hold on
    image([0,orig_size(2)],[orig_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0])
    title('DORSAL 3D')
    h = subplot(1,2,2);
    imagesc(flipud(fliplr(palmar_3D)))
    hold on
    image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]); set(h,'CameraPosition',[0,0,-10*1200])
    title('PALMAR 3D')
    sgtitle(['Obliqueness: ' char(string(round(Survey3DData(row).Oblique_Proportion,2)))])
    % saveas(gcf,['row_' char(string(row)) '_obliqueness.png'])
end