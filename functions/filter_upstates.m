function [u_ons, u_off] = filter_upstates(ups, downs, dt, extension_thresh, dur_thresh)

% attempt to lengthen edges forward and backward
% i.e. for lengthening a long upstate's onset to a prior short upstate's offset
dists = ups(2:end) - downs(1:end - 1);

remove = dists < extension_thresh / dt;
ups = ups([true ~remove]);
downs = downs([~remove true]);

assert(length(ups)== length(downs));

durs = downs - ups;
long_durs = durs > dur_thresh / dt;
u_ons = ups(long_durs);
u_off = downs(long_durs);

assert(length(u_ons) == length(u_off), 'Number of detected onsets and offsets are different.')

end