function v_out = remove_spikes(v_in, dt, SPIKE_THRESH, SPIKETHRESH_BACKSET, SPIKETHRESH_FORSET)

% ensure voltage vector is oriented correctly (we use a row vector)
if size(v_in, 1) ~= 1
    v_in = v_in';
end

spike_times = find_spikes(v_in, SPIKE_THRESH);
n_spikes = length(spike_times);

ind_minus = ceil(SPIKETHRESH_BACKSET/dt);
ind_plus = ceil(SPIKETHRESH_FORSET/dt);

v_out = v_in;
for si = 1:n_spikes
    
    spike_time = spike_times(si);
    
    val1 = v_out(spike_time - ind_minus);
    val2 = v_out(spike_time + ind_plus);
    
    v_out((spike_time - ind_minus):(spike_time + ind_plus)) = ...
        linspace(val1, val2, ind_plus+ind_minus+1);
    
end

end