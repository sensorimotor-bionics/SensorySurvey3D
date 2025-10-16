function [is_oblique, is_palmar, is_dorsal, three_dim_normals] = partition_by_normals(three_dim, viewplot)
    three_dim_triangulation = triangulation(three_dim.faces+1,three_dim.verts);
    three_dim_normals = faceNormal(three_dim_triangulation);
    
    angles_list = nan(size(three_dim_normals,1),1);
    for n = 1:size(three_dim_normals,1)
        angles_list(n) = acosd(dot(three_dim_normals(n,:),[0 0 1])/(sqrt(dot(three_dim_normals(n,:),three_dim_normals(n,:)))*sqrt(dot([0 0 1],[0 0 1]))));
    end
    error_space = 0;
    is_palmar = angles_list>=90+error_space;
    is_dorsal = angles_list<=90-error_space;
    is_oblique = angles_list>60&angles_list<120;
    
    if viewplot
        figure
        hold on
        P = incenter(three_dim_triangulation);
        quiver3(P(is_dorsal,1),P(is_dorsal,2),P(is_dorsal,3), ...
         three_dim_normals(is_dorsal,1),three_dim_normals(is_dorsal,2),three_dim_normals(is_dorsal,3),0.5,'color','r');
        quiver3(P(is_palmar,1),P(is_palmar,2),P(is_palmar,3)-.1, ...
         three_dim_normals(is_palmar,1),three_dim_normals(is_palmar,2),three_dim_normals(is_palmar,3)-.1,0.5,'color','c');
        quiver3(P(is_oblique,1),P(is_oblique,2),P(is_oblique,3), ...
         three_dim_normals(is_oblique,1),three_dim_normals(is_oblique,2),three_dim_normals(is_oblique,3),0.5,'color','k','LineWidth',1);
        h = gca; axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]);
    end
end

