function all_3d = plotmodellandmarks(which_title,landmarks,viewplot)
    all_3d = [];
    
    if viewplot
        figure
        title(which_title)
        hold on
    end
    
    which_landmarks = {"Tpip","Tmcp",...
        "Idip","Ipip","Imcp",...
        "Mdip","Mpip","Mmcp",...
        "Rdip","Rpip","Rmcp",...
        "Pdip","Ppip","Pmcp"};
    
    for ii = 1:length(which_landmarks)
        this_landmark = landmarks.(which_landmarks{ii});
        if viewplot
            plot3(this_landmark(1),this_landmark(2),this_landmark(3),'r.','MarkerSize',30)
        end
        all_3d = cat(2,all_3d,this_landmark);
    end
    
    which_landmarks = {"Tend","Iend","Mend","Rend","Pend"};
    
    for ii = 1:length(which_landmarks)
        this_landmark = landmarks.(which_landmarks{ii});
        if viewplot
            plot3(this_landmark(1),this_landmark(2),this_landmark(3),'b.','MarkerSize',30)
        end
        all_3d = cat(2,all_3d,this_landmark);
    end
    
    which_landmarks = {"MpP","MpD","WuT","WuP", "EoW"};
    
    for ii = 1:length(which_landmarks)
        this_landmark = landmarks.(which_landmarks{ii});
        if viewplot
            plot3(this_landmark(1),this_landmark(2),this_landmark(3),'g.','MarkerSize',30)
        end
        all_3d = cat(2,all_3d,this_landmark);
    end
    
    axis equal
    all_3d = all_3d';
end