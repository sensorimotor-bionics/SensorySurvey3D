function plot_correlation_distribution(Survey3DData)
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

    obliqueness_palmar_1 = cell2mat({Survey3DData(kept_rows_palmar_1(~isnan(kept_rows_palmar_1))).Oblique_Proportion});
    obliqueness_dorsal_1 = cell2mat({Survey3DData(kept_rows_dorsal_1(~isnan(kept_rows_dorsal_1))).Oblique_Proportion});
    
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
    
    obliqueness_palmar_2 = cell2mat({Survey3DData(kept_rows_palmar_2(~isnan(kept_rows_palmar_2))).Oblique_Proportion});
    obliqueness_dorsal_2 = cell2mat({Survey3DData(kept_rows_dorsal_2(~isnan(kept_rows_dorsal_2))).Oblique_Proportion});
    
    bci02_color = [.49 .44 .70];
    bci03_color = [.91 .16 .54];

    % group by palmar/dorsal
    % ji_p = [dist_palmar_1(~isnan(dist_palmar_1));dist_palmar_2(~isnan(dist_palmar_2))];
    % ji_d = [dist_dorsal_1(~isnan(dist_dorsal_1));dist_dorsal_2(~isnan(dist_dorsal_2))];
    
    % o_p = [obliqueness_palmar_1,obliqueness_palmar_2]';
    % o_d = [obliqueness_dorsal_1,obliqueness_dorsal_2]';
    
    % [R,P] = corrcoef(ji_p,o_p)
    % [R,P] = corrcoef(ji_d,o_d)

    % group by subject ID
    ji_1 = [dist_palmar_1(~isnan(dist_palmar_1));dist_dorsal_1(~isnan(dist_dorsal_1))];
    ji_2 = [dist_palmar_2(~isnan(dist_palmar_2));dist_dorsal_2(~isnan(dist_dorsal_2))];

    o_1 = [obliqueness_palmar_1,obliqueness_dorsal_1]';
    o_2 = [obliqueness_palmar_2,obliqueness_dorsal_2]';

    [R_1,P_1] = corrcoef(ji_1,o_1);
    [R_2,P_2] = corrcoef(ji_2,o_2);

    % group everything
    [R_all,P_all] = corrcoef([ji_1;ji_2],[o_1;o_2]);

    figure
    hold on
    scatter(dist_palmar_1(~isnan(dist_palmar_1)),obliqueness_palmar_1,[],bci02_color)
    scatter(dist_dorsal_1(~isnan(dist_dorsal_1)),obliqueness_dorsal_1,[],bci02_color,'*')
    text(0.8,0.8,[char(string(round(R_1(1,2),2))) ' n.s.'],'FontSize',14,'Color',bci02_color)

    scatter(dist_palmar_2(~isnan(dist_palmar_2)),obliqueness_palmar_2,[],bci03_color)
    scatter(dist_dorsal_2(~isnan(dist_dorsal_2)),obliqueness_dorsal_2,[],bci03_color,'*')
    text(0.8,0.7,[char(string(round(R_2(1,2),2))) ' *'],'FontSize',14,'Color',bci03_color)

    axis([-0.1 1 -0.1 1])
    axis square
    xlabel('Jaccard Index')
    ylabel('Obliqueness Score')
    title('Correlation Plot')

    foo = 0:.1:1;
    p = polyfit(ji_1,o_1,1);
    plot(foo,p(1).*foo+p(2),'--','Color',bci02_color)

    p = polyfit(ji_2,o_2,1);
    plot(foo,p(1).*foo+p(2),'--','Color',bci03_color)

    p = polyfit([ji_1;ji_2],[o_1;o_2],1);
    plot(foo,p(1).*foo+p(2),'-','Color','k')
    text(0.8,0.6,[char(string(round(R_all(1,2),2))) ' **'],'FontSize',14,'Color','k')

    % saveas(gcf,'annotation_correlation.png')
    % saveas(gcf,'annotation_correlation.svg')

    [pval, ~] = bonf_holm([P_1(1,2),P_2(1,2),P_all(1,2)],0.05);
    pvals = string(pval)


    % separating palmar and dorsal and subject ID
    % [R,P] = corrcoef(dist_palmar_1(~isnan(dist_palmar_1)),obliqueness_palmar_1)
    % [R,P] = corrcoef(dist_dorsal_1(~isnan(dist_dorsal_1)),obliqueness_dorsal_1)
    % [R,P] = corrcoef(dist_palmar_2(~isnan(dist_palmar_2)),obliqueness_palmar_2)
    % [R,P] = corrcoef(dist_dorsal_2(~isnan(dist_dorsal_2)),obliqueness_dorsal_2)
    % 
    % foo = 0:.1:1;
    % p = polyfit(dist_palmar_1(~isnan(dist_palmar_1)),obliqueness_palmar_1,1);
    % plot(foo,p(1).*foo+p(2),'-','Color',bci02_color)
    % 
    % p = polyfit(dist_dorsal_1(~isnan(dist_dorsal_1)),obliqueness_dorsal_1,1);
    % plot(foo,p(1).*foo+p(2),'--','Color',bci02_color)
    % 
    % p = polyfit(dist_palmar_2(~isnan(dist_palmar_2)),obliqueness_palmar_2,1);
    % plot(foo,p(1).*foo+p(2),'-','Color',bci03_color)
    % 
    % p = polyfit(dist_dorsal_2(~isnan(dist_dorsal_2)),obliqueness_dorsal_2,1);
    % plot(foo,p(1).*foo+p(2),'--','Color',bci03_color)
end

