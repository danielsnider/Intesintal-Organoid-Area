im_smooth = imgaussfilt(raw,8,'filtersize',75);
im_stdev = stdfilt(im_smooth);
im_stdev_thresh = im_stdev<.6;
im_open = imopen(im_stdev_thresh,strel('disk',30));
figure; imshow(im_open,[]);
