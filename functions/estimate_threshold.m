function [thresh, edges] = estimate_threshold(v, bin_width, separation, do_plot)

if nargin < 4
    do_plot = false;
end

% get histogram counts
[N, edges] = histcounts(v, min(v):bin_width:max(v));
% [N, edges] = histcounts(v);
bin_centers_all = (edges(1:end - 1) + edges(2:end)) / 2;

% find the two biggest peaks that are separated by at least
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
    scatter([lower_edge upper_edge], [N(min(locs)) N(max(locs))], 'r');
    scatter(thresh, min_count, 'g');
    xlim([-80 -35]);
%     strip_axes;
    ylabel('# of points at voltage');
    xlabel('mV');
    legend('voltage histogram', 'modes', 'chosen threshold');
end

end