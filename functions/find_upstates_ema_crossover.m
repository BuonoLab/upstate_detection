function [ups, downs] = find_upstates_ema_crossover(v, dt, slow_width, fast_width, ...
    up_dist_thresh, down_dist_thresh)
% given 1d signal, returns indices of on-sets and off-sets of "upstates"

% input arguments:
% v: voltage time series
% dt: 1 / sampling rate of v
% slow_width: width of the slow EMA, in the same units as dt
% fast_width: width of the fast EMA, in the same units as dt
% up_dist_thresh: average distance the fast EMA must be over the slow to be
    % considered consequential
% down_dist_thresh: average distance the slow EMA must be over the fast to be
    % considered consequential

% returns:
% ups: indices of upstate onsets
% downs: indices of upstate offsets

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

% measure the average distance between EMAs in putative up and down regions
n_regions = length(ups);
up_dists = zeros(1, length(n_regions));
down_dists = zeros(1, length(n_regions));
for region_ind = 1:n_regions - 1
    up_dists(region_ind) = mean(v_fast_over_slow(ups(region_ind):downs(region_ind) - 1));
    down_dists(region_ind) = mean(v_slow_over_fast(downs(region_ind):ups(region_ind + 1) - 1));
end
up_dists(n_regions) = mean(v_fast_over_slow(ups(end):downs(end) - 1));
down_dists(n_regions) = mean(v_slow_over_fast(downs(end):length(v)));

small_downs = down_dists < down_dist_thresh;
big_ups = up_dists > up_dist_thresh;

% prune putative states
region_ind = 1;
while region_ind <= length(ups)
    % if this is a big up
    if big_ups(region_ind)
        % check to see if all downs and ups until the next big up are small
        % if so, delete them
        next_big_up_ind = region_ind + find(big_ups(region_ind + 1:end), 1);
        if ~any(big_ups(region_ind + 1:next_big_up_ind - 1)) && ...
                all(small_downs(region_ind:next_big_up_ind - 1))
            ups(region_ind + 1:next_big_up_ind) = [];
            big_ups(region_ind + 1:next_big_up_ind) = [];
            downs(region_ind:next_big_up_ind - 1) = [];
            small_downs(region_ind:next_big_up_ind - 1) = [];
        end
        region_ind = region_ind + 1;
    % else if a small up, remove it
    else
        ups(region_ind) = [];
        big_ups(region_ind) = [];
        downs(region_ind) = [];
        small_downs(region_ind) = [];
    end
end

assert(length(ups) == length(downs), 'Number of detected onsets and offsets are different.')

end