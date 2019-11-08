function [ups, downs, e_ups, e_downs] = filter_upstates(ups, downs, dt, extension_thresh, dur_thresh)

% attempt to lengthen edges forward and backward
% i.e. for lengthening a long upstate's onset to a prior short upstate's offset
dists = ups(2:end) - downs(1:end - 1);

if ~isempty(extension_thresh)
    remove = dists < extension_thresh / dt;
    ups = ups([true ~remove]);
    downs = downs([~remove true]);
end
    
assert(length(ups)== length(downs));

if ~isempty(dur_thresh)
    durs = downs - ups;
    long_durs = durs > dur_thresh / dt;
    ups = ups(long_durs);
    downs = downs(long_durs);
    e_ups= ups(~long_durs);
    e_downs = downs(~long_durs);
end

assert(length(ups) == length(downs), 'Number of detected onsets and offsets are different.')

end