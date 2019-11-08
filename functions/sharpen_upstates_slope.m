function [ups, downs] = sharpen_upstates_slope(v, dt, ups, downs, ...
    slope_width, slope_thresh, before_distance, after_distance)

if nargin < 8
    after_distance = before_distance;
end

if isempty(ups)
    return
end

slope_width_pts = round(slope_width / dt) + 1;  % should be odd
before_distance_pts = round(before_distance / dt) + 1;
after_distance_pts = round(after_distance / dt) + 1;

n_failures = 0;
n_events = length(ups);
for event_ind = 1:n_events
    
    current_onset_ind = ups(event_ind);
    start_ind = current_onset_ind - before_distance_pts;
    end_ind = current_onset_ind + after_distance_pts;
    
    if start_ind < 1
        start_ind = 1;
    end
    
    if end_ind > length(v)
        end_ind = length(v);
    end
    
    take_piece = v(start_ind:end_ind);
    take_piece_slope = movingslope(take_piece, slope_width_pts, 1, dt);
    
    piece_onset_ind = find(take_piece_slope > slope_thresh, 1);
    
    if isempty(piece_onset_ind)
        n_failures = n_failures + 1;
        [~, piece_onset_ind] = max(take_piece_slope);
    end
    
    ups(event_ind) = piece_onset_ind + current_onset_ind - before_distance_pts - 1;    
end

% check to see if any of the up / down states became overlapping - if so, join them
down_durs = ups(2:end) - downs(1:end - 1);
overlapping_bool = down_durs <= 0;
ups = ups([true ~overlapping_bool]);
downs = downs([~overlapping_bool true]);

fprintf('there were %d traces where the slope didnt exceed the thresh\n', n_failures);

end