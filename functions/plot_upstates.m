function plot_upstates(t, v, u_ons, u_off)

ymin = min(v);
ymax = max(v);

hold on;
p = plot(t, v, 'k');
p.Color(4) = .2;
xlabel('Time (s)');
ylabel('Potential (mV)');

scatter(t(u_ons), v(u_ons), ...
    'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'r', 'Marker', '^');
scatter(t(u_off), v(u_off), ...
    'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'r', 'Marker', 'v');

n_upstates = length(u_ons);

for up_ind = 1:n_upstates
    x1 = t(u_ons(up_ind));
    x2 = t(u_off(up_ind));
    patch('Vertices', [x1, ymin; x2, ymin; x2, ymax; x1, ymax], 'Faces', [1, 2, 3, 4], ...
        'FaceColor', 'red', 'FaceAlpha', 0.2, 'EdgeAlpha', 0);
    l = line([x1 x2], [(ymin - 1) (ymin - 1)]);
    l.Color = 'r';
end
hold off;

ylim([(ymin - 2) ymax]);

end