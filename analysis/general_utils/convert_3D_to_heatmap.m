function [palmar,dorsal] = convert_3D_to_heatmap(three_dim,three_dim_dorsum,documented_electrodes,color_map,orig_size)
    temp_background = zeros([orig_size 3]);
    this_ele = documented_electrodes;
    foo = split(this_ele,'_');

    figure; set(gcf,'position',[0,0,1109,600])
    subplot(1,2,1); hold on
    imagesc(temp_background)
    axis tight; axis equal
    subplot(1,2,2); hold on
    imagesc(temp_background)
    axis tight; axis equal

    disp_shape_single(three_dim.verts_flat,three_dim.faces,color_map,0,0);

    cdata = print('-RGBImage','-r272','-noui'); % was -r300...
    p = cdata(:,size(cdata,2)/2+1:end,:);
    del_row = sum(p(:,:,1)~=0,2)==size(p,2);
    del_col = sum(p(:,:,1)~=0,1)==size(p,1);
    p(del_row,:,:) = [];
    p(:,del_col,:) = [];
    temp = double(p(:,:,1));
    palmar = temp(1:orig_size(1),1:orig_size(2)); % enforce proper sizing

    sgtitle(foo(2))
    % close all

    figure; set(gcf,'position',[0,0,1109,600])
    subplot(1,2,1); hold on
    imagesc(temp_background)
    axis tight; axis equal
    subplot(1,2,2); hold on
    imagesc(temp_background)
    axis tight; axis equal

    disp_shape_single(three_dim_dorsum.verts_flat,three_dim_dorsum.faces,color_map,0,0);

    cdata = print('-RGBImage','-r272','-noui');
    d = cdata(:,1:size(cdata,2)/2,:);
    del_row = sum(d(:,:,1)~=0,2)==size(d,2);
    del_col = sum(d(:,:,1)~=0,1)==size(d,1);
    d(del_row,:,:) = [];
    d(:,del_col,:) = [];
    temp = double(d(:,:,1));
    dorsal = temp(1:orig_size(1),1:orig_size(2)); % enforce proper sizing
    
    sgtitle(foo(2))
    % close all
end