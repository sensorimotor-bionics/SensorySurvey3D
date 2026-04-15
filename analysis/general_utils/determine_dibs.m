function [apply_transform_reference, dibs] = determine_dibs(three_dim, primary_landmarks, landmark_superset, dependencies)
    dibs = nan(size(three_dim.verts,1),1);
    expanded_landmarks = [];
    expanded_values = [];
    valence_values = [];
    
    % use medial axis to assign dibs
    for l = 1:size(dependencies,1)
        point1 = three_dim.landmark_report.(primary_landmarks{dependencies(l,1)});
        point2 = three_dim.landmark_report.(primary_landmarks{dependencies(l,2)});
        expanded_landmarks = cat(1,expanded_landmarks,...
            [linspace(point1(1),point2(1),10);linspace(point1(2),point2(2),10);linspace(point1(3),point2(3),10)]');
        expanded_values = cat(1,expanded_values,dependencies(l,1).*ones(10,1));
        valence_values = cat(1,valence_values,ones(10,1));
    end

    % proximity to each keypoint on the overlying mesh, then normalize (0 to 1)
    distance_record = nan(size(three_dim.verts,1),length(expanded_landmarks));
    
    for v = 1:size(three_dim.verts,1)
        this_vert = three_dim.verts(v,:);
        
        for l = 1:length(expanded_landmarks)
            this_landmark = expanded_landmarks(l,:);
            distance_record(v,l) = pdist([this_vert;this_landmark],'euclidean');
        end
    
        dibs(v) = expanded_values(find(distance_record(v,:) == min(distance_record(v,:)),1,'first'));
    end

    dibs_valence = distance_record-min(distance_record,[],1);
    dibs_valence = dibs_valence./repmat(max(dibs_valence,[],1),[size(three_dim.verts,1),1]);
    dibs_valence = 1-dibs_valence;

    apply_transform_reference = nan(size(three_dim.verts,1),length(landmark_superset));
    for l = 1:length(landmark_superset)
        try
            apply_transform_reference(:,l) = max(dibs_valence(:,expanded_values==l),[],2);
        catch
            apply_transform_reference(:,l) = zeros(size(three_dim.verts,1),1);
        end
    end

    % winner takes all-ish
    winner_takes_all = apply_transform_reference==repmat(max(apply_transform_reference,[],2),[1,size(apply_transform_reference,2)]);
    winner_takes_all = double(winner_takes_all);

    for r = 1:length(winner_takes_all)
        this_winner = find(winner_takes_all(r,:)==max(winner_takes_all(r,:)));

        for w = 1:length(this_winner)
            considered_winner = this_winner(1);
            winner_partners_1 = find(dependencies(:,1)==considered_winner);
            winner_partners_2 = find(dependencies(:,2)==considered_winner);
            winner_takes_all(r,dependencies(winner_partners_1,2)) = apply_transform_reference(r,dependencies(winner_partners_1,2)).^10; % can't just be 1, needs a falloff
            winner_takes_all(r,dependencies(winner_partners_2,1)) = apply_transform_reference(r,dependencies(winner_partners_2,1)).^10;
        end
    end

    apply_transform_reference = apply_transform_reference.*winner_takes_all;
    apply_transform_reference(apply_transform_reference<0.01) = 0;
    apply_transform_reference = apply_transform_reference./sum(apply_transform_reference,2);
end