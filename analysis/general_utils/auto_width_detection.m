function width_landmarks = auto_width_detection(target, primary_landmarks, accessory_landmarks, dependencies, transform)
    % either extract widths from file or guess from context
    width_landmarks = nan(size(accessory_landmarks,2),3);

    if length(fieldnames(target.landmark_report))>length(primary_landmarks)
        for ii = 1:length(accessory_landmarks)
            if sum(strcmp(fieldnames(target.landmark_report),accessory_landmarks{ii}))
                width_landmarks(ii,:) = transform.b*target.landmark_report.(accessory_landmarks{ii})'*transform.T+transform.c(1,:);
            end
        end
    end

    % accessory_width = nan(length(accessory_landmarks),3);
    % pt1 = 1;
    % pt2 = 2;
    % 
    % for l = 1:size(dependencies,1)
    %     if ~strcmp(primary_landmarks{dependencies(l,1)},"end")
    %         point1 = target.landmark_report.(primary_landmarks{dependencies(l,1)});
    %         point2 = target.landmark_report.(primary_landmarks{dependencies(l,2)});
    %         point1 = transform.b*point1'*transform.T+transform.c(1,:);
    %         point2 = transform.b*point2'*transform.T+transform.c(1,:);
    %         m = (point2(pt2)-point1(pt2))/(point2(pt1)-point1(pt1)); % line passes through a point and has a slope equal to -1/(slope)
    %         b = point1(pt2) - (-1/m)*point1(pt1); % solve y = mx+b for b, use new slope and b 
    %         perp_p = point1;
    %         perp_p(pt1) = perp_p(pt1)+.03;%.005; % this width value needs to be based on something...
    %         perp_p(pt2) = (-1/m)*perp_p(pt1)+b;
    %         perp_t = point1;
    %         perp_t(pt1) = perp_t(pt1)-.03;%.005;
    %         perp_t(pt2) = (-1/m)*perp_t(pt1)+b;
    %         try
    %             accessory_width(strcmp([accessory_landmarks{:}],strcat(primary_landmarks{dependencies(l,1)},"_p")),:) = perp_p;
    %             accessory_width(strcmp([accessory_landmarks{:}],strcat(primary_landmarks{dependencies(l,1)},"_t")),:) = perp_t;
    %         catch
    %         end
    %     end
    % end
    % 
    % width_distance_record = nan(size(target.verts,1),size(accessory_width,1));
    % for v = 1:size(target.verts,1)
    %     this_vert = target.verts(v,:);
    %     for l = 1:size(accessory_width,1)
    %         this_landmark = accessory_width(l,:);
    %         width_distance_record(v,l) = pdist([this_vert;this_landmark],'euclidean');
    %     end
    % end
    % 
    % for l = 1:size(accessory_width,1)
    %     if isnan(width_landmarks(l,1))
    %         try
    %             width_landmarks(l,:) = target.verts(find(width_distance_record(:,l)==min(width_distance_record(:,l)),1,'first'),:);
    %         catch
    %             width_landmarks(l,:) = nan(1,3);
    %         end
    %     end
    % end
end