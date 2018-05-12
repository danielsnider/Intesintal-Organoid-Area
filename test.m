close all
DEBUG_FIGS = false;

areas=[];
folder = folders{1};
  search_path = sprintf('Favourite_Images/%s/*.tif',folder);
  files = dir(search_path);
  % figure
  % title(folder)
  file_paths = {};
  for file=files'
    filename = file.name;
    file_path = sprintf('%s/%s',file.folder, file.name);
    short_path = file_path(87:end);
    fprintf('Loading file %s\n',short_path)
    file_paths = [file_paths short_path];

    raw = imread(file_path);
    if size(raw,3)>1
      %raw = im2double(raw);
      raw = rgb2gray(raw);
    end
    if DEBUG_FIGS
     figure; imshow(raw,[]);
    end
    % ksdensity(raw(:));
    % hold on;

    im_smooth = imgaussfilt(raw,.5);
    % thresh_val = prctile(raw(:),80);
    % im_thresh = o>thresh_val;
    T = adaptthresh(im_smooth, 0.4);
    im_thresh = imbinarize(im_smooth,T);
    if DEBUG_FIGS
      figure; imshow(im_thresh,[]);
    end

    % Shrink white objects to remove small dots and thin lines
    close_size = 5;
    im_close = imclose(im_thresh,strel('disk',close_size));
    if DEBUG_FIGS
      figure; imshow(im_close,[]);
    end
    
    filled_img = imfill(im_close,'holes');
    if DEBUG_FIGS
      figure; imshow(filled_img,[]);
    end
        
    open_size = 5;
    im_open = imopen(filled_img,strel('disk',open_size));
    if DEBUG_FIGS
      figure; imshow(im_open,[]);
    end

    % % Filter small objects that are less than half of the larged object area
    % im_labelled = bwlabel(im_open);
    % num_objects = max(im_labelled(:));
    % stats = regionprops('table',im_labelled, im_smooth, 'MeanIntensity');
    % for idx=1:num_objects
    %   if stats.MeanIntensity(idx) < prctile(im_smooth(:),85);
    %     im_labelled(im_labelled==idx)=0;
    %   end
    % end
    % im_object_thresh = im_labelled > 0;
    % if DEBUG_FIGS
    %   figure; imshow(im_object_thresh,[]);
    % end


    % im_smooth = imgaussfilt(raw,10,'filtersize',75);
    % im_stdev = stdfilt(im_smooth);
    % figure; imshow(im_stdev<1,[]);
    % if DEBUG_FIGS
    % end

    im_smooth = imgaussfilt(raw,8,'filtersize',75);
    im_stdev = stdfilt(im_smooth);
    im_stdev_thresh = im_stdev<.6;
    im_stdev_open = imopen(im_stdev_thresh,strel('disk',30));
    im_open(im_stdev_open==1)=0;
    if DEBUG_FIGS
      figure; imshow(im_open,[]);
    end

    im_areafilt = bwareafilt(im_open,[200 Inf]);
    if DEBUG_FIGS
      figure; imshow(im_areafilt,[]);
    end

    total_area = sum(im_areafilt(:))
    areas = [areas; total_area];

    figure
    if min(raw(:)) < prctile(raw(:),99.5)
        min_max = [min(raw(:)) prctile(raw(:),99.5)];
    else
        min_max = [];
    end
    imshow(raw,[min_max]);
    hold on
    % Display color overlay
    labelled_perim = imdilate(bwperim(im_areafilt),strel('disk',1));
    labelled_rgb = label2rgb(uint32(labelled_perim), 'jet', [1 1 1], 'shuffle');
    himage = imshow(im2uint8(labelled_rgb),[min_max]);
    himage.AlphaData = labelled_perim*1;

  end

figure
plot(1:7,areas,'r-')