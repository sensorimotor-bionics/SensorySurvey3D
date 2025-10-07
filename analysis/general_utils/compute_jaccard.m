function jaccard_record = compute_jaccard(subject,documented_electrodes,...
    palmar,PFs_palmar,palmar_image,...
    dorsal,PFs_dorsal,dorsal_image)

    [palmar_mask, dorsal_mask] = get_hand_masks();
    orig_size = size(palmar_mask);
    
    [palm_ref_img, ~, palm_ref_alpha] = imread(palmar_image);
    palm_ref_img = imresize(palm_ref_img, orig_size);
    palm_ref_alpha = imresize(palm_ref_alpha, orig_size);
    [dor_ref_img, ~, dor_ref_alpha] = imread(dorsal_image);

    jaccard_record = nan(length(documented_electrodes),2);
    for ele = 1:length(documented_electrodes)
        try
            this_ele = documented_electrodes{ele};
            foo = split(this_ele,'_');
            this_ele = double(string(cell2mat(foo(2))));
        
            figure; set(gcf,'position',[0,0,2500,1500])
            h = subplot(2,2,1); % dorsal
            temp_dorsal_2D = flipud(PFs_dorsal(this_ele).PixelFreqMap);
            imagesc(temp_dorsal_2D)
            hold on
            image([0,orig_size(2)],[orig_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
            axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0])
            title('2D annotation - dorsal')
            
            h = subplot(2,2,2); % palmar
            temp_palmar_2D = flipud(fliplr(PFs_palmar(this_ele).PixelFreqMap));
            imagesc(temp_palmar_2D)
            hold on
            image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
            axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]); set(h,'CameraPosition',[0,0,-10*1200])
            title('2D annotation - palmar')
            
            h = subplot(2,2,3); % dorsal
            temp_dorsal_3D = flipud(dorsal{double(string(cell2mat(foo(2))))});
            imagesc(temp_dorsal_3D.* flipud(dorsal_mask))
            hold on
            image([0,orig_size(2)],[orig_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
            axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0])
            title('3D annotation - dorsal')
        
            h = subplot(2,2,4); % palmar
            temp_palmar_3D = flipud(fliplr(palmar{double(string(cell2mat(foo(2))))}));
            imagesc(temp_palmar_3D.* flipud(fliplr(palmar_mask)))
            hold on
            image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
            axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]); set(h,'CameraPosition',[0,0,-10*1200])
            title('3D annotation - palmar')
        
            % Jaccard index: area of overlap / area of union
            separator = 0.1;
            temp_palmar_2D = temp_palmar_2D./max(temp_palmar_2D,[],'all');
            temp_palmar_3D = temp_palmar_3D./max(temp_palmar_3D,[],'all');
            temp_palmar_2D(temp_palmar_2D>=separator) = 1;
            temp_palmar_2D(temp_palmar_2D<separator) = 0;
            temp_palmar_3D(temp_palmar_3D>=separator) = 1;
            temp_palmar_3D(temp_palmar_3D<separator) = 0;
            summary_palmar = temp_palmar_2D+temp_palmar_3D.* flipud(fliplr(palmar_mask));
            overlap_palmar = sum(summary_palmar==2,'all');
            union_palmar = sum(summary_palmar>0,'all');
        
            temp_dorsal_2D = temp_dorsal_2D./max(temp_dorsal_2D,[],'all');
            temp_dorsal_3D = temp_dorsal_3D./max(temp_dorsal_3D,[],'all');
            temp_dorsal_2D(temp_dorsal_2D>=separator) = 1;
            temp_dorsal_2D(temp_dorsal_2D<separator) = 0;
            temp_dorsal_3D(temp_dorsal_3D>=separator) = 1;
            temp_dorsal_3D(temp_dorsal_3D<separator) = 0;
            summary_dorsal = temp_dorsal_2D+temp_dorsal_3D.* flipud(dorsal_mask); % follow through with dorsal mask adjustment...
            overlap_dorsal = sum(summary_dorsal==2,'all');
            union_dorsal = sum(summary_dorsal>0,'all');
        
            if union_palmar == 0
                union_palmar = 1;
            end
        
            if union_dorsal == 0
                union_dorsal = 1;
            end

            jaccard_record(ele,1) = overlap_palmar/union_palmar; % palmar
            jaccard_record(ele,2) = overlap_dorsal/union_dorsal; % dorsal
        
            sgtitle([{['electrode ' cell2mat(foo(2))]} {['dorsum jaccard: ' char(string(round(jaccard_record(ele,2),2)))]} {['palmar jaccard: ' char(string(round(jaccard_record(ele,1),2)))]}])
            saveas(gcf,[subject '_comparative_annotation_electrode_' char(foo(2)) '.png'])
        catch
            continue
        end
        close all
    end
end