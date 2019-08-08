function spike_times = find_spikes(v, thresh)

supthresh_inds = find(v > thresh);

if isempty(supthresh_inds)
    spike_times = [];
    return
end

supthresh_inds_diff = [0 diff(supthresh_inds) 0];

consec_bounds = find(supthresh_inds_diff ~= 1);

n_spikes = length(consec_bounds) - 1;
spike_times = zeros(1, n_spikes);

for si=1:n_spikes
    start_ind = consec_bounds(si);
    end_ind = consec_bounds(si + 1) - 1;
    spike_times(si) = supthresh_inds(ceil((start_ind + end_ind) / 2));
end

end