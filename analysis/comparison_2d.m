%% Consolidate all PFs for each participant
subject_list = {'BCI02'};
num_electrodes = 64;
threshold = 0.33;
min_observations = 3;

ProcessedDataPath = 'H:\UserFolders\CharlesGreenspon\BCI_HistoricalSurvey';

max_implant_duration = Inf;
[palmar_mask, palmar_template, dorsal_mask, dorsal_template] = GetHandMasks();
[palmar_segments, dorsum_segments] = GetHandSegments();
orig_size = size(palmar_mask);
% [X,Y] = meshgrid(1:orig_size(2), 1:orig_size(1));
% req_fn = GetSurveyStructFields();
% 
% for s = 1:length(subject_list)
%     disp(subject_list{s})
%     % Get implant date
%     id = cc.load_config.participant(subject_list{s}, 'chicago').implant_date;
%     id = datetime(id, 'Format', 'uuuu-MM-dd');
% 
%     % Load all the data
%     flist = dir(fullfile(ProcessedDataPath, 'RawData', subject_list{s}, 'BCI02.data.00926.mat'));
%     raw_subj_data = cell(size(flist));
%     for f = 1:length(flist)
%         temp = load(fullfile(flist(f).folder, flist(f).name));
%         if isempty(fieldnames(temp.SurveyData))
%             continue
%         end
% 
%         % Check fieldnames
%         fn_idx = find(~contains(req_fn, fieldnames(temp.SurveyData)));
%         if ~isempty(fn_idx)
%             for fi = 1:length(fn_idx)
%                 temp.SurveyData(1).(req_fn{fn_idx(fi)}) = [];
%             end
%         end
% 
%         raw_subj_data{f} = temp.SurveyData;
%     end
%     raw_subj_data = cat(2, raw_subj_data{:});
% 
%     % Filter dates
%     d = cellfun(@(c) datetime(c, 'InputFormat','dd-MMM-uuuu'), {raw_subj_data.Date});
%     raw_subj_data = raw_subj_data(d - id < max_implant_duration);
% 
%     % Prepare for segmentation
%     ChannelMap = LoadSubjectChannelMap(subject_list{s}(1:5));
%     grid_locations = ChannelMap.ChannelNumbers(ChannelMap.IsSensory);
%     [grid_tags{1, 1}, grid_tags{1, 2}] = deal(cell(size(grid_locations{1})));
% 
%     ConsolidatedPFs = struct();
%     % Combine by electrode
%     for e = 1:num_electrodes
%         % Assign metadata
%         ConsolidatedPFs(e).Subject = subject_list{s};
%         ConsolidatedPFs(e).Electrode = e;
% 
%         % Get index
%         e_idx = find([raw_subj_data.Channel] == e);
% 
%         % Workout where to put tag
%         if e <= 32
%             [row_idx,col_idx] = find(grid_locations{1} == e);
%             array_idx = 1;
%         else
%             [row_idx,col_idx] = find(grid_locations{2} == e);
%             array_idx = 2;
%         end
% 
% 
%         % Compute the pixel frequency map
%         pfm = zeros(size(palmar_mask));
%         for ei = 1:length(e_idx)
%             idx = raw_subj_data(e_idx(ei)).PalmarIdx;
%             pfm(idx) = pfm(idx) + 1;
%         end        
% 
%         % Threshold
%         pfm_max = max(pfm, [], 'all');
%         pfm_threshold = pfm_max * threshold;
%         pfm_t = pfm;
%         pfm_t(pfm < pfm_threshold) = 0;
%         pfm_t(pfm < min_observations) = 0;
% 
%         % Compute the segments
%         pfmt_max = max(pfm_t, [], 'all');
%         if pfmt_max > 0
%             % Centroid
%             centroid_x = sum(pfm_t(:) .* X(:)) ./ sum(pfm_t(:));
%             centroid_y = sum(pfm_t(:) .* Y(:)) ./ sum(pfm_t(:));
%             ConsolidatedPFs(e).WeightedCentroid = [centroid_x, centroid_y];
%             ConsolidatedPFs(e).Segment = GetSegment_Centroid([centroid_x, centroid_y], orig_size, palmar_segments);
%             ConsolidatedPFs(e).SegmentTag = palmar_segments(ConsolidatedPFs(e).Segment).Tag;
%             % Overlap
%             ConsolidatedPFs(e).Segment_Overlap = GetSegment_PixelIdx(find(pfm_t > 0), palmar_segments);
%             ConsolidatedPFs(e).Segment_OverlapTags = {palmar_segments(ConsolidatedPFs(e).Segment_Overlap).Tag};
%         else
%             [ConsolidatedPFs(e).Segment, ConsolidatedPFs(e).SegmentTag, ConsolidatedPFs(e).WeightedCentroid, ...
%                 ConsolidatedPFs(e).Segment_Overlap, ConsolidatedPFs(e).Segment_OverlapTags] = deal([]);
%         end
% 
%         % Assign data
%         ConsolidatedPFs(e).PixelFreqMap = pfm;
%         ConsolidatedPFs(e).PFM_TIdx = find(pfm > pfm_threshold);
%     end
% 
%     % Save
%     save(fullfile('C:\Repositories\SensorySurvey3D\analysis', sprintf('%s_ProcessedPFs.mat', subject_list{s})), "ConsolidatedPFs")
% end

% %% Plot all
% map = zeros(size(palmar_mask));
% for e = 1:64
%     map(ConsolidatedPFs(e).PFM_TIdx) = map(ConsolidatedPFs(e).PFM_TIdx) + 1;
% end
% 
% figure
% imagesc(map)
% 
% % Palmar
% [palm_ref_img, ~, palm_ref_alpha] = imread(fullfile('./ReferenceImages', 'TopLayer-handpcontour.png'));
% palm_ref_img = imresize(palm_ref_img, orig_size);
% palm_ref_alpha = imresize(palm_ref_alpha, orig_size);
% 
% %% Plot each electrode
% clf; 
% figure
% t = tiledlayout('flow');
% for e = 1:64
%     nexttile;
%     imagesc(ConsolidatedPFs(e).PixelFreqMap)
%     hold on
%     image(palm_ref_img, 'AlphaData', palm_ref_alpha);
%     set(gca, 'XTick', [], 'YTick', [])
%     title(e)
% end

%% Plot each big

electrodes_of_interest = [4 7 13 17 30 34 36 53 56 57 63];

for e = electrodes_of_interest
    map = zeros(size(palmar_mask));
    try
    map(ConsolidatedPFs(e).PFM_TIdx) = map(ConsolidatedPFs(e).PFM_TIdx) + 1;
    figure
    colormap summer
    set(gcf,'position',[0,0,300,300])
    imagesc(ConsolidatedPFs(e).PixelFreqMap)
    hold on
    image(palm_ref_img, 'AlphaData', palm_ref_alpha);
    set(gca, 'XTick', [], 'YTick', [])
    sgtitle(string(e))
    catch
    end
    % saveas(gcf,['BCI02_2D_annotation_electrode_' char(string(e)) '.png'])
end