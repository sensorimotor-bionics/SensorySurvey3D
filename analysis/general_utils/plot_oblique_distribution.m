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

    % figure;
    % histogram(oblique_proportion(~isnan(oblique_proportion)),0:.2:1)
    % xlabel('proportion of annotation occluded')
    % ylabel('number of electrodes')
    % title('3D annotation visibility')
    % saveas(gcf,[subject '_annotation_visibility.svg'])
    % 
    % for ele = 1:length(documented_electrodes)
    %     try
    %         this_ele = documented_electrodes{ele};
    %         foo = split(this_ele,'_');
    % 
    %         figure; set(gcf,'position',[0,0,1109,600])
    %         subplot(1,2,1); hold on
    %         axis tight; axis equal
    %         subplot(1,2,2); hold on
    %         axis tight; axis equal
    % 
    %         disp_shape_single(three_dim.verts_flat,three_dim.faces,color_map.(this_ele),0,0);
    % 
    %         sgtitle([foo(2) ['proportion occluded: ' char(string(round(oblique_proportion(double(string(foo(2)))),2)))]])
    %         saveas(gcf,[subject '_occlusion_electrode_' char(foo(2)) '.png'])
    %     catch
    %     end
    %     close all
    % end
end