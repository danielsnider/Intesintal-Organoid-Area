set(0,'DefaultFigureWindowStyle','docked');
addpath(genpath('functions'));
close all

% Make an output folder to save to
date_str = datestr(now,'yyyymmddTHHMMSS');
save_dir = 'results';
fig_save_path = sprintf('%s/%s/', save_dir, date_str);
mkdir(fig_save_path);

folders = {...
  'A1R_High_Response_FIS_Mar14_XY point 8 (well H2)', ...
  'A1R_Low_Response_FIS_Mar14_XY point 2 (well B2)', ...
  'Cellomics_High_Response_FIS_May1_c661+a770_G3', ...
  'Cellomics_Low_Response_FIS_May1_c661+a770_A3' ...
};

dark_green = [130/255, 170/255, 80/255];
light_green = [190/255, 225/255, 130/255];
dark_purple = [158/255, 66/255, 178/255];
light_purple = [235/255, 145/255, 255/255];

line_cmap = {dark_green light_green dark_purple light_purple};

DEBUG_FIGS = false;
SAVE_TO_DISK = true;
all_areas = {};

folders = folders(1); % for testing

for folder=folders
  folder = folder{:};
  search_path = sprintf('Favourite_Images/%s/*.tif',folder);
  files = dir(search_path);
  file_paths = {};
  areas = [];
  count = 1;
  all_boundaries = {};
  num_images = length(files);
  num_desired_colors = num_images;
  vis_cmap = get_n_length_cmap('jet', num_desired_colors);
  for file=files'
    filename = file.name;
    file_path = sprintf('%s/%s',file.folder, file.name);
    short_path = file_path(87:end);
    fprintf('Loading file %s\n',short_path)
    file_paths = [file_paths short_path];

    raw = imread(file_path);
    if size(raw,3)>1
      raw = rgb2gray(raw);
    end
    if DEBUG_FIGS
     figure; imshow(raw,[]);
    end

    im_smooth = imgaussfilt(raw,.5);
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

    im_boundaries = im_areafilt;
    all_boundaries{length(all_boundaries)+1} = im_boundaries;

    total_area = sum(im_boundaries(:))
    areas = [areas; total_area];

    % figure
    % if min(raw(:)) < prctile(raw(:),99.5)
    %     min_max = [min(raw(:)) prctile(raw(:),99.5)];
    % else
    %     min_max = [];
    % end
    % imshow(raw,[min_max]);
    % hold on
    % % Display color overlay
    % labelled_perim = imdilate(bwperim(im_boundaries),strel('disk',1));
    % labelled_rgb = label2rgb(uint32(labelled_perim), [1 0 0], [1 1 1]);
    % himage = imshow(im2uint8(labelled_rgb),[min_max]);
    % himage.AlphaData = labelled_perim*1;

    % txt = sprintf('t=%d', count);
    % h = text(15,15,txt,'Color',[.8 .8 .8],'FontSize',22,'Clipping','on','HorizontalAlignment','left','VerticalAlignment','top','Interpreter','none');
    % txt = sprintf('%s', short_path);
    % h = text(15,size(raw,1)-45,txt,'Color',[.8 .8 .8],'FontSize',12,'Clipping','on','HorizontalAlignment','left','VerticalAlignment','top','Interpreter','none');

    % if SAVE_TO_DISK
    %   pause(0.33)
    %   image_name = strrep(short_path,'/','__');
    %   fig_name = sprintf('%s/visualization %s.png',fig_save_path,image_name);
    %   export_fig(fig_name,'-m2');
    % end


    figure
    if min(raw(:)) < prctile(raw(:),99.5)
        min_max = [min(raw(:)) prctile(raw(:),99.5)];
    else
        min_max = [];
    end
    imshow(raw,[min_max]);
    hold on
    % Display color overlay (different color for each boundary line)
    for img_id=1:length(all_boundaries)
      im_boundaries = all_boundaries{img_id};
      labelled_perim = imdilate(bwperim(im_boundaries),strel('disk',0));
      labelled_rgb = label2rgb(uint32(labelled_perim), vis_cmap(img_id,:), [1 1 1]);
      himage = imshow(im2uint8(labelled_rgb),[min_max]);
      himage.AlphaData = labelled_perim*1;
    end

    txt = sprintf('t=%d', count);
    h = text(15,15,txt,'Color',[.8 .8 .8],'FontSize',22,'Clipping','on','HorizontalAlignment','left','VerticalAlignment','top','Interpreter','none');
    txt = sprintf('%s', short_path);
    h = text(15,size(raw,1)-45,txt,'Color',[.8 .8 .8],'FontSize',9,'Clipping','on','HorizontalAlignment','left','VerticalAlignment','top','Interpreter','none');

    %% Crop to interesting area
    % X 171, 466
    % X 55, 325
    % A1R_High_Response_FIS_Mar14_XY
    % h=gcf; set(h.Children,'Xlim',[30 171]);
    % h=gcf; set(h.Children,'Ylim',[325 466]);

    %% Crop to interesting area
    % Cellomics_High_Response
    %h=gcf; set(h.Children,'Xlim',[512 705]);
    %h=gcf; set(h.Children,'Ylim',[626 789]);


    if SAVE_TO_DISK
      pause(0.33)
      image_name = strrep(short_path,'/','__');
      fig_name = sprintf('%s/rainbow_visualization_%s.png',fig_save_path,image_name);
      export_fig(fig_name,'-m2');
    end

    count = count + 1;

  end
  all_areas{length(all_areas)+1} = areas;
end

%% Normalize
norm_areas = {}
for folder_id = 1:length(all_areas)
  norm_areas{folder_id} = all_areas{folder_id} - all_areas{folder_id}(1); % minus all by the first point 
  norm_areas{folder_id} = all_areas{folder_id} ./ all_areas{folder_id}(1); % divide all by the first point
end

norm_area = norm_areas_o;


%% Plot
figure
hold on
for folder_id = 3:4
  plot(1:7,norm_areas{folder_id},'Color',line_cmap{folder_id},'LineWidth',1.5)
end

% Style
set(gca,'FontSize',12);
set(gca,'Color',[.95 .95 .95 ]);
set(gcf,'Color',[1 1 1 ]);
grid on;
axis tight;
box off;
set(gca,'GridAlpha',1);
set(gca,'GridColor',[1 1 1]);
% Make smaller tick names;
Fontsize = 12;
xl = get(gca,'XLabel');
xlFontSize = get(xl,'FontSize');
xAX = get(gca,'XAxis');
set(xAX,'FontSize', Fontsize);
set(xl, 'FontSize', xlFontSize);
xl = get(gca,'YLabel');
xlFontSize = get(xl,'FontSize');
xAY = get(gca,'YAxis');
set(xAY,'FontSize', Fontsize);
set(xl, 'FontSize', xlFontSize);
% Titles
title('Growth over Time','Interpreter','none','FontName','Yu Gothic UI Light');
xlabel('Time (a.u.)', 'Interpreter','none','FontName','Yu Gothic UI');
ylabel('Normalized Area (%)', 'Interpreter','none','FontName','Yu Gothic UI');
h=suptitle('Organoid Swelling');
set(h,'FontSize',18,'FontName','Yu Gothic UI');
% Legend
legend_names = {'A1R (4x) High Response', 'A1R (4x) Low Response','Cellomics (2.5x) High Resp.', 'Cellomics (2.5x) Low Resp.'}
lgd = legend(legend_names,'Interpreter','none','Location','northwest');
lgd.Color = [1 1 1];
% Y ticks
yt = yticks;
yt = yt*100
ticklabels=sprintfc('%g%%',yt);
yticklabels(ticklabels);
set(gca,'TickLabelInterpreter','none');


