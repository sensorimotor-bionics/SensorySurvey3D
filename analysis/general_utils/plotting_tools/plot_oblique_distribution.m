function plot_oblique_distribution(Survey3DData)
    temp = Survey3DData(strcmp({Survey3DData.Subject},'BCI02')); % exclude other subjects from dataset
    channels = cell2mat({temp.Channel});
    ele_options = unique(channels);
    oblique_1 = nan(length(ele_options),1);
    
    for ii = 1:length(ele_options)
        ele = ele_options(ii);
        if sum(isnan(cell2mat({temp(channels==ele).Oblique_Proportion})))~=sum(channels==ele)
            oblique_1(ii) = max(cell2mat({temp(channels==ele).Oblique_Proportion}));
        end
    end
    
    temp = Survey3DData(strcmp({Survey3DData.Subject},'BCI03')); % exclude other subjects from dataset
    channels = cell2mat({temp.Channel});
    ele_options = unique(channels);
    oblique_2 = nan(length(ele_options),1);
    
    for ii = 1:length(ele_options)
        ele = ele_options(ii);
        if sum(isnan(cell2mat({temp(channels==ele).Oblique_Proportion})))~=sum(channels==ele)
            oblique_2(ii) = max(cell2mat({temp(channels==ele).Oblique_Proportion}));
        end
    end
    
    bci02_color = [.49 .44 .70];
    bci03_color = [.91 .16 .54];

    % sum(~isnan(oblique_1))
    % sum(~isnan(oblique_2))
    
    % nanmean(oblique_1)
    % nanmean(oblique_2)

    figure
    Swarm(1,oblique_1,'distribution_style','Box','color',bci02_color)
    hold on    
    Swarm(2,oblique_2,'distribution_style','Box','color',bci03_color)
    title('3D Annotation Obliqueness')
    ylabel('Proportion of Oblique Annotation Area')
    
    ranksum(oblique_1,oblique_2)
    
    ylim([0 1])
    text(1.5,0.9,'**','FontSize',14)
    xticks([1 2])
    xticklabels({'C1','C2'})
    % saveas(gcf,'annotation_obliqueness.png')
    % saveas(gcf,'annotation_obliqueness.svg')

    % nanmean(oblique_1)
    % nanstd(oblique_1)
    % nanmean(oblique_2)
    % nanstd(oblique_2)
end