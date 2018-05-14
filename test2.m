f = figure;
get_n_length_cmap_colors
cmap = colormap('jet');
cmap_size = size(cmap,1);
num_desired_colors = 7;
interval = cmap_size / num_desired_colors;
subset_cmap = [];
for idx=1:num_desired_colors
    cmap_index = round(interval * idx)
    subset_cmap(idx,:) = cmap(cmap_index,:)
end

delete(f)