function [two_dim_verts_shifted, three_dim_verts_shifted] = flatten_by_normals(two_dim, three_dim, which_side)
    three_dim_verts_flattened = three_dim.verts;
    
    for n = 1:size(three_dim.normals,1)
        this_face = three_dim.faces(n,:)+1;
        for v = 1:length(this_face)
            if three_dim.is_palmar(n)
                three_dim_verts_flattened(this_face(v),3) = -0.1;
            elseif three_dim.is_dorsal(n)
                three_dim_verts_flattened(this_face(v),3) = 0.1;
            else
                three_dim_verts_flattened(this_face(v),3) = 0;
            end
        end
    end

    if strcmp(which_side,"palmar")
        translation_adjustment = [100,30];
    elseif strcmp(which_side,"dorsal")
        translation_adjustment = [160,25];
    else
        translation_adjustment = [0,0];
    end
    scaling_factor = 1140/(max(two_dim.landmarks(:,2))-min(two_dim.landmarks(:,2)));

    three_dim_verts_shifted = three_dim_verts_flattened;
    three_dim_verts_shifted(:,1) = (three_dim_verts_flattened(:,1)-min(two_dim.landmarks(:,1))).*scaling_factor+translation_adjustment(1);
    three_dim_verts_shifted(:,2) = (three_dim_verts_flattened(:,2)-min(two_dim.landmarks(:,2))).*scaling_factor+translation_adjustment(2);
    three_dim_verts_shifted(:,3) = three_dim_verts_flattened(:,3).*scaling_factor;
    three_dim.verts_flat = three_dim_verts_shifted;
    
    two_dim_verts_shifted = two_dim.verts;
    two_dim_verts_shifted(:,1) = (two_dim.verts(:,1)-min(two_dim.landmarks(:,1))).*scaling_factor+translation_adjustment(1);
    two_dim_verts_shifted(:,2) = (two_dim.verts(:,2)-min(two_dim.landmarks(:,2))).*scaling_factor+translation_adjustment(2);
    two_dim_verts_shifted(:,3) = two_dim.verts(:,3).*scaling_factor;
    two_dim.verts_flat = two_dim_verts_shifted;
end
