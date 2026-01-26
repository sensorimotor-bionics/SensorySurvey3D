function [is_oblique, is_palmar, is_dorsal, three_dim_normals] = partition_by_normals_vertex(three_dim, viewplot)
    three_dim_triangulation = triangulation(three_dim.faces+1,three_dim.verts);
    three_dim_normals = vertexNormal(three_dim_triangulation);
    cam_axis = [0 0 1];
    
    angles_list = nan(size(three_dim_normals,1),1);
    for n = 1:size(three_dim_normals,1)
        angles_list(n) = acosd(dot(three_dim_normals(n,:),cam_axis)/(sqrt(dot(three_dim_normals(n,:),three_dim_normals(n,:)))*sqrt(dot(cam_axis,cam_axis))));
    end
    error_space = 0;
    is_dorsal = angles_list>=90+error_space;
    is_palmar = angles_list<=90-error_space;
    is_oblique = angles_list>60&angles_list<120;

    if viewplot
        figure
        hold on
        plot3(three_dim.verts(is_dorsal,1),three_dim.verts(is_dorsal,2),three_dim.verts(is_dorsal,3),'r*')
        plot3(three_dim.verts(is_palmar,1),three_dim.verts(is_palmar,2),three_dim.verts(is_palmar,3),'c*')
        plot3(three_dim.verts(is_oblique,1),three_dim.verts(is_oblique,2),three_dim.verts(is_oblique,3),'k*')
        h = gca; axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]);
    end
end

