function thresh = estimate_threshold(v, bin_width, separation, do_plot)

if nargin < 4
    do_plot = false;
end

[N, edges] = histcounts(v, min(v):bin_width:max(v));
bin_centers_all = (edges(1:end - 1) + edges(2:end)) / 2;
[~, locs] = findpeaks(N, 'NPeaks', 2, 'SortStr', 'descend', ...
    'MinPeakDistance', round(separation / bin_width));

lower_edge = bin_centers_all(min(locs));
upper_edge = bin_centers_all(max(locs));

N_valley = N(min(locs):max(locs));
[min_count, min_inter_peak_ind] = min(N_valley);
thresh = bin_centers_all(min(locs) + min_inter_peak_ind - 1);
% peaks = [lower_edge, upper_edge];

if do_plot
    plot(bin_centers_all, N);
    hold on;
    scatter(lower_edge, N(min(locs)), 'r');
    scatter(upper_edge, N(max(locs)), 'r');
    scatter(thresh, min_count, 'g');
end

end