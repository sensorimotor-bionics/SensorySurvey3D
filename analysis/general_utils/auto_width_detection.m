function [width_landmarks, accessory_width] = auto_width_detection(three_dim, primary_landmarks, accessory_landmarks, dependencies, transform)
    accessory_width = nan(length(accessory_landmarks),3);

    for l = 1:size(dependencies,1)
        if ~strcmp(primary_landmarks{dependencies(l,1)},"end")
            point1 = three_dim.landmark_report.(primary_landmarks{dependencies(l,1)});
            point2 = three_dim.landmark_report.(primary_landmarks{dependencies(l,2)});
            point1 = transform.b*point1'*transform.T+transform.c(1,:);
            point2 = transform.b*point2'*transform.T+transform.c(1,:);
            m = (point2(2)-point1(2))/(point2(1)-point1(1)); % line passes through a point and has a slope equal to -1/(slope)
            b = point1(2) - (-1/m)*point1(1); % solve y = mx+b for b, use new slope and b 
            perp_p = point1;
            perp_p(1) = perp_p(1)+.03;
            perp_p(2) = (-1/m)*perp_p(1)+b;
            perp_t = point1;
            perp_t(1) = perp_t(1)-.03;
            perp_t(2) = (-1/m)*perp_t(1)+b;
            try
                accessory_width(strcmp([accessory_landmarks{:}],strcat(primary_landmarks{dependencies(l,1)},"_p")),:) = perp_p;
                accessory_width(strcmp([accessory_landmarks{:}],strcat(primary_landmarks{dependencies(l,1)},"_t")),:) = perp_t;
            catch
            end
        end
    end

    width_distance_record = nan(size(three_dim.verts,1),size(accessory_width,1));
    for v = 1:size(three_dim.verts,1)
        this_vert = three_dim.verts(v,:);
        for l = 1:size(accessory_width,1)
            this_landmark = accessory_width(l,:);
            width_distance_record(v,l) = pdist([this_vert;this_landmark],'euclidean');
        end
    end

    width_landmarks = nan(size(accessory_width,1),3);
    for l = 1:size(accessory_width,1)
        try
            width_landmarks(l,:) = three_dim.verts(find(width_distance_record(:,l)==min(width_distance_record(:,l)),1,'first'),:);
        catch
            width_landmarks(l,:) = nan(1,3);
        end
    end
end