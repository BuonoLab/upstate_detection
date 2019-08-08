function spike_inds = find_spikes2(v, thresh)
% given a 1d array v, return indices of local maxima within segments of v that exceed thresh
% mike seay, buonomano lab, may 2019

% final all supra-threshold indices
supthresh_inds = find(v > thresh);

% if there are none, abort and return an empty array
if isempty(supthresh_inds)
    spike_inds = [];
    return
end

% find the divisions between sets of consecutive supra-threshold indices
% these tell us where the data segments that exceed thresh are located
supthresh_inds_diff = [0 diff(supthresh_inds) 0];
consec_bounds = find(supthresh_inds_diff ~= 1);

% pre-calculate how many spikes there should be, and initialize an array to contain them
n_exceeding_segments = length(consec_bounds) - 1;
spike_inds = zeros(1, n_exceeding_segments);

% for each data segment, find its maximum and store that index
for si = 1:n_exceeding_segments
    start_ind = consec_bounds(si);
    end_ind = consec_bounds(si + 1) - 1;
    [~, local_max_ind] = max(v(supthresh_inds(start_ind:end_ind)));
    spike_inds(si) = supthresh_inds(start_ind + local_max_ind - 1);
end

end