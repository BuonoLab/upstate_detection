function [u_ons, u_off] = find_upstates(v, dt, v_thresh, dur_thresh, extension_thresh)
% given 1d signal, returns indices of on-sets and off-sets of "upstates"

% input arguments:
% v: voltage time series
% dt: 1 / sampling rate of v
% v_thresh: voltage threshold above which v must go to be "up"
% dur_thresh: minimum upstate duration (in same units as dt)
% extension_thresh: minimum downstate duration (in same units as dt)

% returns:
% u_ons: indices of upstate onsets
% u_off: indices of upstate offsets

% ensure voltage vector is oriented correctly (we use a row vector)
if size(v, 1) ~= 1
    v = v';
end

% define logical vectors indicating where signal is at-or-above and below the threshold
above_bool = v >= v_thresh;
below_bool = v < v_thresh;

% define logical vectors indicating points of upward / downward crossings
upward_crossings = [false below_bool(1:end - 1) & above_bool(2:end)];
downward_crossings = [false above_bool(1:end - 1) & below_bool(2:end)];

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

% ensure the above worked and we have equal numbers of putative up and down transitions
assert(length(ups)==length(downs));

% no upstates? return empty vectors
if isempty(ups)
    u_ons = [];
    u_off = [];
    return
end

% calculate downstate durations (in points)
down_durs = ups(2:end) - downs(1:end - 1);

% delete short downstates
% (this effectively combines upstates that are separated by short downstates)
keep_downs = down_durs > extension_thresh / dt;
ups = ups([true keep_downs]);
downs = downs([keep_downs true]);

assert(length(ups)== length(downs));

% delete short upstates
up_durs = downs - ups;
long_durs = up_durs > dur_thresh / dt;
u_ons = ups(long_durs);
u_off = downs(long_durs);

assert(length(u_ons) == length(u_off), 'Number of detected onsets and offsets are different.')

end