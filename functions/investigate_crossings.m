function [ups, downs, dists, durs] = investigate_crossings(v, dt, v_thresh)
% given 1d signal, returns indices of on-sets and off-sets of "upstates"

if size(v, 1) ~= 1
    v = v';
end

above_bool = v >= v_thresh;
below_bool = v < v_thresh;

upward_crossings = [false below_bool(1:end - 1) & above_bool(2:end)];
downward_crossings = [false above_bool(1:end - 1) & below_bool(2:end)];

ups = find(upward_crossings);
downs = find(downward_crossings);

while length(ups) ~= length(downs)
    if downs(1) < ups(1)
        downs(1) = [];
    else
        ups(end) = [];
    end
end

assert(length(ups)==length(downs));

% no upstates?
if isempty(ups)
    dists = [];
    durs = [];
    return
end

dists = ups(2:end) - downs(1:end - 1);
durs = downs - ups;

% convert to real time (seconds)
ups = ups .* dt;
downs = downs .* dt;
dists = dists .* dt;
durs = durs .* dt;

end