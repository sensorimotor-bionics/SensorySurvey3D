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
    
    if viewplot
        figure; set(gcf,'position',[0,0,1500,1000])
        hold on
        shape_viewer(three_dim.verts,three_dim.faces,[0.6 0.6 0.6],gca)
        P = incenter(three_dim_triangulation);
        quiver3(P(is_dorsal,1),P(is_dorsal,2),P(is_dorsal,3), ...
         three_dim_normals(is_dorsal,1),three_dim_normals(is_dorsal,2),three_dim_normals(is_dorsal,3),1,'color','r');
        quiver3(P(is_palmar,1),P(is_palmar,2),P(is_palmar,3), ...
         three_dim_normals(is_palmar,1),three_dim_normals(is_palmar,2),three_dim_normals(is_palmar,3),1,'color','b');
        axis(gca,'equal')
        axis(gca,'off')
        view(20,50)
        title('palmar/dorsal face normals')

        figure; set(gcf,'position',[0,0,1500,1500])
        hold on
        P = incenter(three_dim_triangulation);
        quiver3(P(is_dorsal,1),P(is_dorsal,2),P(is_dorsal,3), ...
         three_dim_normals(is_dorsal,1),three_dim_normals(is_dorsal,2),three_dim_normals(is_dorsal,3),0.5,'color','r');
        quiver3(P(is_palmar,1),P(is_palmar,2),P(is_palmar,3), ...
         three_dim_normals(is_palmar,1),three_dim_normals(is_palmar,2),three_dim_normals(is_palmar,3),0.5,'color','b');
        shape_viewer(three_dim.verts.*[1 1 0]+[0 0 -.9],three_dim.faces(is_dorsal,:),[1 0 0],gca)
        shape_viewer(three_dim.verts.*[1 1 0]+[0 0 0.9],three_dim.faces(is_palmar,:),[0 0 1],gca)
        axis(gca,'equal')
        axis(gca,'off')
        view(10,40)
        title('palmar/dorsal separated')

        figure; set(gcf,'position',[0,0,1500,1500])
        hold on
        P = incenter(three_dim_triangulation);
        quiver3(P(is_oblique,1),P(is_oblique,2),P(is_oblique,3), ...
         three_dim_normals(is_oblique,1),three_dim_normals(is_oblique,2),three_dim_normals(is_oblique,3),0.5,'color','k');
        shape_viewer(three_dim.verts.*[1 1 0]+[0 0 -.9],three_dim.faces(is_dorsal,:),[0.6 0.6 0.6],gca)
        shape_viewer(three_dim.verts.*[1 1 0]+[0 0 0.9],three_dim.faces(is_palmar,:),[0.6 0.6 0.6],gca)
        shape_viewer(three_dim.verts.*[1 1 0]+[0 0 -.9],three_dim.faces(is_oblique&is_dorsal,:),[1 0 0],gca)
        shape_viewer(three_dim.verts.*[1 1 0]+[0 0 0.9],three_dim.faces(is_oblique&is_palmar,:),[0 0 1],gca)
        axis(gca,'equal')
        axis(gca,'off')
        view(10,40)
        title('palmar/dorsal/oblique separated')
    end
end

