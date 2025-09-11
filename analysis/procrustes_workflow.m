
%% options
% subject = 'BCI03';
% session = 235;
% electrodes = [2 12 14 22 3 41 45 54 9 4 48 10 38 50 36 26 18 6 43 8 39 16 37 34 15 24 27];

subject = 'BCI02';
session = [908 925 926];
electrodes = [7 29 53 54 ...
            3 10 63 34 4 7 21 57 17 56 13 53 26 30 52 ...
            36];

% session = 925;
% electrodes_3d = [3 10 63 34 4 7 21 57 17 56 13 53 26 30 52]; % sets 14 3 5 13 15 4 12 24 6 2 25 26 23 22 16
% electrodes_2d = [61 11 29 59 6 9 38 55 12 54]; % 925 ols data is 25 long, sets 2-26 (sets 7-11, 17-21) (skip OLS rows for the sets above!)
% 
% session = 926;
% electrodes_3d = [36]; % set 17
% electrodes_2d = [36 56 32 63 30 4 34 7 57 13 53 17 36]; % 926 ols data is 13 long, sets 4-16

% have both 2d and 3d for: 4 7 13 17 30 34 35 53 56 57 63
% OLSData_BCI02_00925
% OLSData_BCI02_00926

%% import 3D mesh and annotation colormaps
% parse jsons from session to determine colormaps
[annotation_record, this_model, model_name] =  extract_colormaps(subject,session,electrodes);
documented_electrodes = fieldnames(annotation_record.(this_model).electrodes);

%% summarize annotation colormaps
for ele = 1:length(documented_electrodes)
    this_ele = documented_electrodes{ele};

    if size(annotation_record.(this_model).electrodes.(this_ele).fields,2)>1
        % which_map = sum(annotation_record.(this_model).electrodes.(this_ele).fields,2);
        % which_map(which_map>1) = 1;
        which_map = mean(annotation_record.(this_model).electrodes.(this_ele).fields,2);
    else
        which_map = annotation_record.(this_model).electrodes.(this_ele).fields;
    end
    color_map.(this_ele) = [which_map,0.5*ones(size(which_map)),0.2*ones(size(which_map))];
end

%% transform 3D mesh to 2D palmar (keep both sides)
mesh_2D = "2D_mesh_data.json";
landmarks_2D = "2D_model_procrustes_keypoints_tight.json";
mesh_3D = [model_name '.json'];
landmarks_3D = "3D_model_procrustes_keypoints.json";
[two_dim,three_dim] = transform_mesh(mesh_2D,landmarks_2D,mesh_3D,landmarks_3D,"palmar");

%% transform 3D mesh to 2D dorsal (keep dorsum only)
landmarks_2D = "2D_model_procrustes_keypoints_dorsum_tight.json";
[~,three_dim_dorsum] = transform_mesh(mesh_2D,landmarks_2D,mesh_3D,landmarks_3D,"dorsal");

%% view annotations on flattened 3D mesh
ref_img_path = fullfile(pwd(), 'ReferenceImages');
[palmar_mask, palmar_template, dorsal_mask, dorsal_template] = GetHandMasks();
[palmar_segments, dorsum_segments] = GetHandSegments();
orig_size = size(palmar_mask);
temp_background = zeros([orig_size 3]);

[palm_ref_img, ~, palm_ref_alpha] = imread(fullfile(ref_img_path, 'TopLayer-handpcontour.png'));
palm_ref_img = imresize(palm_ref_img, orig_size);
palm_ref_alpha = imresize(palm_ref_alpha, orig_size);
[dor_ref_img, ~, dor_ref_alpha] = imread(fullfile(ref_img_path, 'TopLayer-contour.png'));

% disp_shape_single(two_dim.verts_flat,two_dim.faces,[0 1 0],50,-50)
% subplot(1,2,1)
% hold on
% image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
% subplot(1,2,2)
% hold on
% image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)

% figure
% disp_shape_single(three_dim_dorsum.verts_flat,three_dim_dorsum.faces,[0 1 0],130,-130)
% subplot(1,2,1)
% hold on
% image([0,orig_size(2)],[orig_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
% 
% figure
% disp_shape_single(three_dim.verts_flat,three_dim.faces,[0 1 0],130,-130)
% subplot(1,2,2)
% hold on
% image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)

for ele = 1:length(documented_electrodes)
    this_ele = documented_electrodes{ele};
    foo = split(this_ele,'_');

    figure; set(gcf,'position',[0,0,1109,600])
    subplot(1,2,1); hold on
    imagesc(temp_background)
    axis tight; axis equal
    subplot(1,2,2); hold on
    imagesc(temp_background)
    axis tight; axis equal

    disp_shape_single(three_dim.verts_flat,three_dim.faces,color_map.(this_ele),0,0);

    cdata = print('-RGBImage','-r300','-noui');
    p = cdata(:,size(cdata,2)/2+1:end,:);
    del_row = sum(p(:,:,1)~=0,2)==size(p,2);
    del_col = sum(p(:,:,1)~=0,1)==size(p,1);
    p(del_row,:,:) = [];
    p(:,del_col,:) = [];
    temp = double(p(:,:,1));
    palmar{double(string(cell2mat(foo(2))))} = temp(1:orig_size(1),1:orig_size(2)); % enforce proper sizing

    sgtitle(foo(2))
    close all

    figure; set(gcf,'position',[0,0,1109,600])
    subplot(1,2,1); hold on
    imagesc(temp_background)
    axis tight; axis equal
    subplot(1,2,2); hold on
    imagesc(temp_background)
    axis tight; axis equal

    disp_shape_single(three_dim_dorsum.verts_flat,three_dim_dorsum.faces,color_map.(this_ele),0,0);

    cdata = print('-RGBImage','-r300','-noui');
    d = cdata(:,1:size(cdata,2)/2,:);
    del_row = sum(d(:,:,1)~=0,2)==size(d,2);
    del_col = sum(d(:,:,1)~=0,1)==size(d,1);
    d(del_row,:,:) = [];
    d(:,del_col,:) = [];
    temp = double(d(:,:,1));
    dorsal{double(string(cell2mat(foo(2))))} = temp(1:orig_size(1),1:orig_size(2)); % enforce proper sizing
    
    sgtitle(foo(2))
    close all
end

%% compare 2D and 3D heatmaps...
load([subject '_ProcessedPFs_PalmarIdx.mat']); % ConsolidatedPFs
PFs_palmar = ConsolidatedPFs;
load([subject '_ProcessedPFs_DorsumIdx.mat']); % ConsolidatedPFs
PFs_dorsal = ConsolidatedPFs;

for ele = 1:length(documented_electrodes)
    this_ele = documented_electrodes{ele};
    foo = split(this_ele,'_');
    this_ele = double(string(cell2mat(foo(2))));

    figure; set(gcf,'position',[0,0,2500,1500])
    h = subplot(2,2,1); % dorsal
    temp_dorsal_2D = flipud(PFs_dorsal(this_ele).PixelFreqMap);
    imagesc(temp_dorsal_2D)
    hold on
    image([0,orig_size(2)],[orig_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0])
    title('2D annotation - dorsal')
    
    h = subplot(2,2,2); % palmar
    temp_palmar_2D = flipud(fliplr(PFs_palmar(this_ele).PixelFreqMap));
    imagesc(temp_palmar_2D)
    hold on
    image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]); set(h,'CameraPosition',[0,0,-10*1200])
    title('2D annotation - palmar')
    
    h = subplot(2,2,3); % dorsal
    temp_dorsal_3D = flipud(dorsal{double(string(cell2mat(foo(2))))});
    imagesc(temp_dorsal_3D.* flipud(dorsal_mask))
    hold on
    image([0,orig_size(2)],[orig_size(1),0],dor_ref_img,'AlphaData', dor_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0])
    title('3D annotation - dorsal')

    h = subplot(2,2,4); % palmar
    temp_palmar_3D = flipud(fliplr(palmar{double(string(cell2mat(foo(2))))}));
    imagesc(temp_palmar_3D.* flipud(fliplr(palmar_mask)))
    hold on
    image([orig_size(2),0],[orig_size(1),0],palm_ref_img,'AlphaData', palm_ref_alpha)
    axis(h,'off'); axis(h,'equal'); set(h,'YDir', 'normal'); set(h,'CameraUpVector',[0 1 0]); set(h,'CameraPosition',[0,0,-10*1200])
    title('3D annotation - palmar')

    % Jaccard index: area of overlap / area of union
    separator = 0.1;
    temp_palmar_2D = temp_palmar_2D./max(temp_palmar_2D,[],'all');
    temp_palmar_3D = temp_palmar_3D./max(temp_palmar_3D,[],'all');
    temp_palmar_2D(temp_palmar_2D>=separator) = 1;
    temp_palmar_2D(temp_palmar_2D<separator) = 0;
    temp_palmar_3D(temp_palmar_3D>=separator) = 1;
    temp_palmar_3D(temp_palmar_3D<separator) = 0;
    summary_palmar = temp_palmar_2D+temp_palmar_3D.* flipud(fliplr(palmar_mask));
    overlap_palmar = sum(summary_palmar==2,'all');
    union_palmar = sum(summary_palmar>0,'all');

    temp_dorsal_2D = temp_dorsal_2D./max(temp_dorsal_2D,[],'all');
    temp_dorsal_3D = temp_dorsal_3D./max(temp_dorsal_3D,[],'all');
    temp_dorsal_2D(temp_dorsal_2D>=separator) = 1;
    temp_dorsal_2D(temp_dorsal_2D<separator) = 0;
    temp_dorsal_3D(temp_dorsal_3D>=separator) = 1;
    temp_dorsal_3D(temp_dorsal_3D<separator) = 0;
    summary_dorsal = temp_dorsal_2D+temp_dorsal_3D.* flipud(dorsal_mask); % follow through with dorsal mask adjustment...
    overlap_dorsal = sum(summary_dorsal==2,'all');
    union_dorsal = sum(summary_dorsal>0,'all');

    if union_palmar == 0
        union_palmar = 1;
    end

    if union_dorsal == 0
        union_dorsal = 1;
    end

    sgtitle([{['electrode ' cell2mat(foo(2))]} {['dorsum jaccard: ' char(string(round(overlap_dorsal/union_dorsal,2)))]} {['palmar jaccard: ' char(string(round(overlap_palmar/union_palmar,2)))]}])
    % saveas(gcf,[subject '_comparative_annotation_electrode_' char(foo(2)) '.png'])
    close all
end

%% what proportion of annotated normals are oblique?
% (invisible to camera or squashed in a 2D representation)

% need to calculate the area of each face
for f = 1:size(three_dim.faces)
    verts = three_dim.verts(three_dim.faces(f,:)+1,:);
    % magnitude of cross product is the positive area of the parallelogram having A and B as sides
    A = verts(2,:)-verts(1,:);
    B = verts(3,:)-verts(1,:);
    three_dim.face_area(f) = norm(cross(A,B))/2;
end

oblique_proportion = nan(64,1);

for ele = 1:length(documented_electrodes)
    this_ele = documented_electrodes{ele};
    foo = split(this_ele,'_');

    this_map = color_map.(this_ele);
    annotated_faces = sum(ismember(three_dim.faces,find(this_map(:,1)>0)),2)==3;

    % sum areas of oblique faces which are annotated
    oblique_area = sum(three_dim.face_area(annotated_faces'&three_dim.oblique));
    % sum areas of camera-facing faces which are annotated
    non_oblique_area = sum(three_dim.face_area(annotated_faces'&~three_dim.oblique));
    % calculate proportion of annotated area that is oblique
    oblique_proportion(double(string(cell2mat(foo(2))))) = oblique_area/(oblique_area+non_oblique_area);
end

nanmean(oblique_proportion)
nanstd(oblique_proportion)

figure;
histogram(oblique_proportion(~isnan(oblique_proportion)),0:.2:1)
ylim([0 4.2])
xlabel('proportion of annotation occluded')
ylabel('number of electrodes')
title('3D annotation visibility')
% saveas(gcf,[subject '_annotation_visibility.png'])
% saveas(gcf,[subject '_annotation_visibility.svg'])

for ele = 1:length(documented_electrodes)
    try
    this_ele = documented_electrodes{ele};
    foo = split(this_ele,'_');

    figure; set(gcf,'position',[0,0,1109,600])
    subplot(1,2,1); hold on
    axis tight; axis equal
    subplot(1,2,2); hold on
    axis tight; axis equal

    disp_shape_single(three_dim.verts_flat,three_dim.faces,color_map.(this_ele),0,0);

    sgtitle([foo(2) ['proportion occluded: ' char(string(round(oblique_proportion(double(string(foo(2)))),2)))]])
    % saveas(gcf,[subject '_occlusion_electrode_' char(foo(2)) '.png'])
    catch
    end
    close all
end

%% view annotations on morphed 3D mesh
for ele = 1:length(documented_electrodes)
    this_ele = documented_electrodes{ele};
    disp_shape_single(three_dim.verts_flat,three_dim.faces,color_map.(this_ele),0,0);
    foo = split(this_ele,'_');
    sgtitle(foo(2))
    % saveas(gcf,[subject '_3D_annotation_electrode_' char(foo(2)) '.png'])
end

%% helper functions
function disp_shape_single(verts,faces,colors,front_dist,back_dist)
    for persp = 1:2
        h = subplot(1,2,persp);
        temp_verts = verts;

        if persp == 1
            temp_verts(:,3) = verts(:,3)+back_dist;
        elseif persp == 2
            temp_verts(:,3) = verts(:,3)+front_dist;
        end
        
        hp = patch('vertices',temp_verts,'faces',faces+1,'parent',h); hold(h,'on');
        hp.EdgeColor = 'none'; 
        hp.FaceColor = 'flat';
        hp.FaceVertexCData = colors;
        hp.FaceLighting = 'flat';
        material(hp,[0.5 0.5 0.0 20 0.5]);
    
        ch = get(h,'children');
        lightExists = sum(arrayfun(@(x) contains(class(ch(x)),'Light'),1:length(ch)));
        supported_positions = [1 1 1; 1 1 -1; 1 -1 1; 1 -1 -1; -1 1 1; -1 1 -1; -1 -1 1; -1 -1 -1];
        if ~lightExists
            for ii = 1:size(supported_positions,1)
                light('parent',h,'Position',supported_positions(ii,:)); 
            end
        end
        
        axis(h,'off'); axis(h,'equal');
        set(h,'Projection','perspective')
        set(h,'CameraUpVector',[0 1 0])

        if persp == 2
            set(h,'CameraPosition',h.CameraPosition.*[1 1 -1])
        end
    end
end
