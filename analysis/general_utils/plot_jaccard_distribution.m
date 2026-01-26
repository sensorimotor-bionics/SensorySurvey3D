function plot_jaccard_distribution(Survey3DData)
    rows = find(strcmp({Survey3DData.Subject},'BCI02'));
    temp = Survey3DData(rows); % exclude other subjects from dataset
    channels = cell2mat({temp.Channel});
    ele_options = unique(channels);
    % length(ele_options)
    dist_palmar_1 = nan(length(ele_options),1);
    dist_dorsal_1 = nan(length(ele_options),1);
    kept_rows_palmar_1 = nan(length(ele_options),1);
    kept_rows_dorsal_1 = nan(length(ele_options),1);
    
    for ii = 1:length(ele_options)
        ele = ele_options(ii);
        if sum(isnan(cell2mat({temp(channels==ele).Palmar_Jaccard})))~=sum(channels==ele)
            select_channels = find(channels==ele);
            jaccard_options = cell2mat({temp(select_channels).Palmar_Jaccard});
            dist_palmar_1(ii) = max(jaccard_options);
            kept_rows_palmar_1(ii) = rows(select_channels(find(jaccard_options==max(jaccard_options),1,'first')));
        end
        if sum(isnan(cell2mat({temp(channels==ele).Dorsal_Jaccard})))~=sum(channels==ele)
            select_channels = find(channels==ele);
            jaccard_options = cell2mat({temp(select_channels).Dorsal_Jaccard});
            dist_dorsal_1(ii) = max(jaccard_options);
            kept_rows_dorsal_1(ii) = rows(select_channels(find(jaccard_options==max(jaccard_options),1,'first')));
        end
    end
    
    rows = find(strcmp({Survey3DData.Subject},'BCI03'));
    temp = Survey3DData(rows); % exclude other subjects from dataset
    channels = cell2mat({temp.Channel});
    ele_options = unique(channels);
    % length(ele_options)
    dist_palmar_2 = nan(length(ele_options),1);
    dist_dorsal_2 = nan(length(ele_options),1);
    kept_rows_palmar_2 = nan(length(ele_options),1);
    kept_rows_dorsal_2 = nan(length(ele_options),1);
    
    for ii = 1:length(ele_options)
        ele = ele_options(ii);
        if sum(isnan(cell2mat({temp(channels==ele).Palmar_Jaccard})))~=sum(channels==ele)
            select_channels = find(channels==ele);
            jaccard_options = cell2mat({temp(select_channels).Palmar_Jaccard});
            dist_palmar_2(ii) = max(jaccard_options);
            kept_rows_palmar_2(ii) = rows(select_channels(find(jaccard_options==max(jaccard_options),1,'first')));
        end
        if sum(isnan(cell2mat({temp(channels==ele).Dorsal_Jaccard})))~=sum(channels==ele)
            select_channels = find(channels==ele);
            jaccard_options = cell2mat({temp(select_channels).Dorsal_Jaccard});
            dist_dorsal_2(ii) = max(jaccard_options);
            kept_rows_dorsal_2(ii) = rows(select_channels(find(jaccard_options==max(jaccard_options),1,'first')));
        end
    end
    
    bci02_color = [.49 .44 .70];
    bci03_color = [.91 .16 .54];

    % sum(~isnan(dist_palmar_1))
    % sum(~isnan(dist_dorsal_1))
    % sum(~isnan(dist_palmar_2))
    % sum(~isnan(dist_dorsal_2))
    
    figure
    Swarm(1,dist_palmar_1,'distribution_style','Box','color',bci02_color)
    hold on
    Swarm(2,dist_dorsal_1,'distribution_style','Box','color',bci02_color)
    
    Swarm(3,dist_palmar_2,'distribution_style','Box','color',bci03_color)
    Swarm(4,dist_dorsal_2,'distribution_style','Box','color',bci03_color)
    title('2D/3D Annotation Jaccard Distance')
    ylabel('2D/3D Annotation Similarity')
    
    ranksum(dist_palmar_1,dist_dorsal_1)
    ranksum(dist_palmar_2,dist_dorsal_2)
    
    ylim([0 1])
    text(1.5,0.8,'n.s.','FontSize',14)
    text(3.5,0.8,'**','FontSize',14)
    xticks([1 2 3 4])
    xticklabels({'C1 Palm','C1 Dorsum','C2 Palm','C2 Dorsum'})
    % saveas(gcf,'annotation_jaccard.png')
    % saveas(gcf,'annotation_jaccard.svg')

    % add a thing that shows all of the annotations that you're considering
    plot_represented('BCI02',Survey3DData,kept_rows_palmar_1,kept_rows_dorsal_1)
    plot_represented('BCI03',Survey3DData,kept_rows_palmar_2,kept_rows_dorsal_2)
end

%% helper functions

function plot_represented(subject,Survey3DData,rows_palmar,rows_dorsal)
    if strcmp(subject,'BCI02')
        c = [linspace(1,.49)',linspace(1,.44)',linspace(1,.70)'];
    elseif strcmp(subject,'BCI03')
        c = [linspace(1,.91)',linspace(1,.16)',linspace(1,.54)'];
    end

    [palmar_mask, dorsal_mask] = get_hand_masks();
    orig_size = size(palmar_mask);
    
    [palm_ref_img, ~, palm_ref_alpha] = imread('TopLayer-handpcontour.png');
    palm_ref_img = imresize(palm_ref_img, orig_size);
    palm_ref_alpha = imresize(palm_ref_alpha, orig_size);
    [dor_ref_img, ~, dor_ref_alpha] = imread('TopLayer-contour.png');

    palmar_3D = squeeze(nanmean(cell2mat(cellfun(@(x)permute(x,[1,3,2]),{Survey3DData(rows_palmar(~isnan(rows_palmar))).Palmar},'UniformOutput',false)),2)).* palmar_mask; % apply the appropriate mask to 3D;
    palmar_2D = squeeze(nanmean(cell2mat(cellfun(@(x)permute(x,[1,3,2]),{Survey3DData(rows_palmar(~isnan(rows_palmar))).Palmar_2D},'UniformOutput',false)),2));
    dorsal_3D = squeeze(nanmean(cell2mat(cellfun(@(x)permute(x,[1,3,2]),{Survey3DData(rows_palmar(~isnan(rows_palmar))).Dorsal},'UniformOutput',false)),2)).* dorsal_mask; % apply the appropriate mask to 3D;
    dorsal_2D = squeeze(nanmean(cell2mat(cellfun(@(x)permute(x,[1,3,2]),{Survey3DData(rows_palmar(~isnan(rows_palmar))).Dorsal_2D},'UniformOutput',false)),2));

    figure; set(gcf,'position',[0,0,1200,1200])
    colormap(c)
    h = subplot(1,2,1);
    imagesc(flipud(fliplr(palmar_3D)))
    hold on
    image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]); set(h,'CameraPosition',[0,0,-10*1200])
    title('PALMAR 3D')
    h = subplot(1,2,2);
    imagesc(flipud(fliplr(palmar_2D)))
    hold on
    image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]); set(h,'CameraPosition',[0,0,-10*1200])
    title('PALMAR 2D')
    sgtitle('All Annotations Considered')
    % saveas(gcf,[subject '_palmar_jaccard_all.png'])

    figure; set(gcf,'position',[0,0,1200,1200])
    colormap(c)
    h = subplot(1,2,1);
    imagesc(flipud(dorsal_3D))
    hold on
    image([0,orig_size(2)],[orig_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0])
    title('DORSAL 3D')
    h = subplot(1,2,2);
    imagesc(flipud(dorsal_2D))
    hold on
    image([0,orig_size(2)],[orig_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0])
    title('DORSAL 2D')
    sgtitle('All Annotations Considered')
    % saveas(gcf,[subject '_dorsal_jaccard_all.png'])
end