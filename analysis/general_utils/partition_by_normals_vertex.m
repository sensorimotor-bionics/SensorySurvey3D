function [is_oblique, is_palmar, is_dorsal, three_dim_normals] = partition_by_normals_vertex(three_dim, viewplot)
    three_dim_triangulation = triangulation(three_dim.faces+1,three_dim.verts);
    three_dim_normals = vertexNormal(three_dim_triangulation);
    
    angles_list = nan(size(three_dim_normals,1),1);
    for n = 1:size(three_dim_normals,1)
        angles_list(n) = acosd(dot(three_dim_normals(n,:),[0 0 1])/(sqrt(dot(three_dim_normals(n,:),three_dim_normals(n,:)))*sqrt(dot([0 0 1],[0 0 1]))));
    end
    error_space = 0;
    is_palmar = angles_list>=90+error_space;
    is_dorsal = angles_list<=90-error_space;
    is_oblique = angles_list>60&angles_list<120;
end

