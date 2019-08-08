function [up_dists, down_dists] = investigate_states_ema_crossover(v, dt, ...
    slow_width, fast_width)
% given 1d signal, returns indices of on-sets and off-sets of "upstates"

% input arguments:
% v: voltage time series

% returns:
% u_ons: indices of upstate onsets
% u_off: indices of upstate offsets

% ensure voltage vector is oriented correctly (we use a row vector)
if size(v, 1) ~= 1
    v = v';
end

slow_width_pts = round(slow_width / dt);
fast_width_pts = round(fast_width / dt);

v_fast_fwd = movmean_exp(v, round(fast_width_pts / 2));
v_slow_fwd = movmean_exp(v, round(slow_width_pts / 2));

v_fast_bwd = fliplr(movmean_exp(fliplr(v), round(fast_width_pts / 2)));
v_slow_bwd = fliplr(movmean_exp(fliplr(v), round(slow_width_pts / 2)));

v_slow = 0.5 * v_slow_fwd + 0.5 * v_slow_bwd;
v_fast = 0.5 * v_fast_fwd + 0.5 * v_fast_bwd;

fast_over_slow = v_fast >= v_slow;
slow_over_fast = v_slow > v_fast;

upward_crossings = [false, slow_over_fast(1:end - 1) & fast_over_slow(2:end)];
downward_crossings = [false, fast_over_slow(1:end - 1) & slow_over_fast(2:end)];

% find crossing locations: these are the putative up and down transitions
ups = find(upward_crossings);
downs = find(downward_crossings);

% recording could have started and ended during different states
% (e.g. start during upstate & end during downstate or vice versa)
% in which case one putative up or down transition will not be paired with its buddy
% we choose the convention that the first putative event should be an up transition
% and all up transitions should be paired with a subsequent down transition
if downs(1) < ups(1)
    downs(1) = [];
end
if ups(end) > downs(end)
    ups(end) = [];
end

% no upstates? return empty vectors
if isempty(ups)
    return
end

% assess the dist of each up and down region
v_fast_over_slow = v_fast - v_slow;
v_slow_over_fast = v_slow - v_fast;

% measure the size of up and down regions
n_regions = length(ups);
up_dists = zeros(1, length(n_regions));
down_dists = zeros(1, length(n_regions));
for region_ind = 1:n_regions - 1
    up_dists(region_ind) = mean(v_fast_over_slow(ups(region_ind):downs(region_ind) - 1));
    down_dists(region_ind) = mean(v_slow_over_fast(downs(region_ind):ups(region_ind + 1) - 1));
end
up_dists(n_regions) = mean(v_fast_over_slow(ups(end):downs(end) - 1));
down_dists(n_regions) = mean(v_slow_over_fast(downs(end):length(v)));

end