set(0,'DefaultFigureWindowStyle','docked');
addpath(genpath('functions'));

% Make an output folder to save to
date_str = datestr(now,'yyyymmddTHHMMSS');
save_dir = 'results';
fig_save_path = sprintf('%s/%s/', save_dir, date_str);
mkdir(fig_save_path);

folders = {...
  'A1R_High_Response_FIS_Mar14_XY point 2 (well B2) (2)', ...
  'A1R_Low_Response_FIS_Mar14_AIR_XY point 2 (well B2)', ...
  'Cellomics_High_Response_FIS_May1_c661+a770_G3', ...
  'Cellomics_Low_Response_FIS_May1_c661+a770_A3' ...
};

DEBUG_FIGS = true;

for folder=folders
  folder = folder{:};
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
%      figure; imshow(raw,[]);
    end
    % ksdensity(raw(:));
    % hold on;
    thresh_val = prctile(raw(:),95);
    im_thresh = raw>thresh_val;
    if DEBUG_FIGS
      figure; imshow(im_thresh,[]);
    end
  end
  % legend(file_paths);
end

    % Shrink white objects to remove small dots and thin lines
    erode_size = 6;
    im_erode = imerode(im_thresh,strel('disk',erode_size));
    if DEBUG_FIGS
      figure; imshow(im_erode,[]);
    end


    % Filter small objects that are less than half of the larged object area
    stats = regionprops('table',bwlabel(im_erode),'Area');
    min_size = max(stats.Area) / 2; % half of max
    max_size = max(stats.Area);
    im_areafilt = bwareafilt(im_erode,[min_size max_size]);
    if DEBUG_FIGS
      figure; imshow(im_areafilt,[]);
    end

    % Display bounding boxes over the original image
    stats = regionprops('table',bwlabel(im_areafilt),'BoundingBox');
    figure; imshow(raw,[]);
    hold on
    for plate_num = 1:height(stats)
      bbox = stats.BoundingBox(plate_num,:);
      rectangle('Position',bbox,'EdgeColor','r');
    end

    % Save result to disk
    export_fig([fig_save_path filename '_result.png'],'-native');
  end
end
