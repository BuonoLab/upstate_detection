function plot_upstate_comparison(t, v, u_ons_seq, u_off_seq, labels, plot_patches)

if nargin < 6
    plot_patches = true;
end

n_seqs = length(u_ons_seq);
colors = lines(n_seqs);

if nargin < 5
    labels = cellfun(@num2str, num2cell(1:n_seqs), 'uni', 0);
end

ymin = min(v);
ymax = max(v);

hold on;
p = plot(t, v, 'k');
p.Color(4) = .2;
xlabel('Time (s)');
ylabel('Potential (mV)');

legend_collector = [];
for seq_ind = 1:n_seqs
   
    u_ons = u_ons_seq{seq_ind};
    u_off = u_off_seq{seq_ind};
    
    scatter(t(u_ons), v(u_ons), ...
        'MarkerEdgeColor', 'none', 'MarkerFaceColor', colors(seq_ind, :), 'Marker', '^');
    scatter(t(u_off), v(u_off), ...
        'MarkerEdgeColor', 'none', 'MarkerFaceColor', colors(seq_ind, :), 'Marker', 'v');
    
    n_upstates = length(u_ons);
    
    for up_ind = 1:n_upstates
        x1 = t(u_ons(up_ind));
        x2 = t(u_off(up_ind));
        if plot_patches
            y1 = ymax - seq_ind / n_seqs * (ymax - ymin);
            y2 = ymax - (seq_ind - 1) / n_seqs * (ymax - ymin);
            patch('Vertices', [x1, y1; x2, y1; x2, y2; x1, y2], 'Faces', [1, 2, 3, 4], ...
                'FaceColor', colors(seq_ind, :), 'FaceAlpha', 0.2, 'EdgeAlpha', 0);
        end
        l = line([x1 x2], [(ymin - seq_ind) (ymin - seq_ind)]);
        l.Color = colors(seq_ind, :);
    end
    
    if n_upstates == 0
        labels(seq_ind) = [];
    else
        legend_collector(end + 1) = l;
    end
end
legend(legend_collector, labels);
hold off;

ylim([(ymin - n_seqs - 1) ymax]);

end