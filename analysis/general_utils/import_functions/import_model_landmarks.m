function all_3d = import_model_landmarks(landmarks,which_landmarks)
    all_3d = [];

    for ii = 1:length(which_landmarks)
        this_landmark = landmarks.(which_landmarks{ii});
        all_3d = cat(2,all_3d,this_landmark);
    end

    all_3d = all_3d';
end