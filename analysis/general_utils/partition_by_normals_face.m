function [is_oblique, is_palmar, is_dorsal, three_dim_normals] = partition_by_normals_face(three_dim, viewplot)
    three_dim_triangulation = triangulation(three_dim.faces+1,three_dim.verts);
    three_dim_normals = faceNormal(three_dim_triangulation);
    cam_axis = [0 0 1];
    
    angles_list = nan(size(three_dim_normals,1),1);
    for n = 1:size(three_dim_normals,1)
        angles_list(n) = acosd(dot(three_dim_normals(n,:),cam_axis)/(sqrt(dot(three_dim_normals(n,:),three_dim_normals(n,:)))*sqrt(dot(cam_axis,cam_axis))));
    end
    error_space = 0;
    is_dorsal = angles_list>=90+error_space;
    is_palmar = angles_list<=90-error_space;
    is_oblique = angles_list>60&angles_list<120;

    % three_dim_normals = -three_dim_normals;

    if viewplot
        figure
        hold on
        P = incenter(three_dim_triangulation);
        quiver3(P(is_dorsal,1),P(is_dorsal,2),P(is_dorsal,3), ...
         three_dim_normals(is_dorsal,1),three_dim_normals(is_dorsal,2),three_dim_normals(is_dorsal,3),0.5,'color','r');
        quiver3(P(is_palmar,1),P(is_palmar,2),P(is_palmar,3), ...
         three_dim_normals(is_palmar,1),three_dim_normals(is_palmar,2),three_dim_normals(is_palmar,3),0.5,'color','c');
        quiver3(P(is_oblique,1),P(is_oblique,2),P(is_oblique,3), ...
         three_dim_normals(is_oblique,1),three_dim_normals(is_oblique,2),three_dim_normals(is_oblique,3),0.5,'color','k','LineWidth',1);
        h = gca; axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]);

        figure; set(gcf,'position',[0,0,1500,1000])
        hold on
        P = incenter(three_dim_triangulation);
        quiver3(P(is_dorsal,1),P(is_dorsal,2),P(is_dorsal,3), ...
         three_dim_normals(is_dorsal,1),three_dim_normals(is_dorsal,2),three_dim_normals(is_dorsal,3),1,'color','r');
        quiver3(P(is_palmar,1),P(is_palmar,2),P(is_palmar,3), ...
         three_dim_normals(is_palmar,1),three_dim_normals(is_palmar,2),three_dim_normals(is_palmar,3),1,'color','b');
        axis(gca,'equal')
        axis(gca,'off')
        view(20,50)
        % saveas(gcf,'palmar_dorsal.png')

        figure; set(gcf,'position',[0,0,1500,1000])
        hold on
        P = incenter(three_dim_triangulation);
        % plot3(P(:,1),P(:,2),P(:,3),'.','Color',[0.5 0.5 0.5],'MarkerSize',12)
        quiver3(P(is_dorsal,1),P(is_dorsal,2),P(is_dorsal,3), ...
         three_dim_normals(is_dorsal,1),three_dim_normals(is_dorsal,2),three_dim_normals(is_dorsal,3),0.5,'color','r');
        quiver3(P(is_palmar,1),P(is_palmar,2),P(is_palmar,3), ...
         three_dim_normals(is_palmar,1),three_dim_normals(is_palmar,2),three_dim_normals(is_palmar,3),0.5,'color','b');
        plot3(P(is_dorsal,1),P(is_dorsal,2),ones(sum(is_dorsal),1).*.6,'.','Color','r','MarkerSize',5)
        plot3(P(is_palmar,1),P(is_palmar,2),ones(sum(is_palmar),1).*-.55,'.','Color','b','MarkerSize',5)
        axis(gca,'equal')
        axis(gca,'off')
        view(10,40)
        % saveas(gcf,'palmar_dorsal_separated.png')

        figure; set(gcf,'position',[0,0,1500,1000])
        hold on
        P = incenter(three_dim_triangulation);
        quiver3(P(is_oblique,1),P(is_oblique,2),P(is_oblique,3), ...
         three_dim_normals(is_oblique,1),three_dim_normals(is_oblique,2),three_dim_normals(is_oblique,3),0.5,'color','k');
        plot3(P(is_dorsal,1),P(is_dorsal,2),ones(sum(is_dorsal),1).*.6,'.','Color',[0.75 0.75 0.75],'MarkerSize',5)
        plot3(P(is_palmar,1),P(is_palmar,2),ones(sum(is_palmar),1).*-.55,'.','Color',[0.75 0.75 0.75],'MarkerSize',5)
        plot3(P(is_oblique,1),P(is_oblique,2),ones(sum(is_oblique),1).*.6,'.','Color','k','MarkerSize',5)
        plot3(P(is_oblique,1),P(is_oblique,2),ones(sum(is_oblique),1).*-.55,'.','Color','k','MarkerSize',5)
        axis(gca,'equal')
        axis(gca,'off')
        view(10,40)
        % saveas(gcf,'palmar_dorsal_oblique_separated.png')
    end
end

