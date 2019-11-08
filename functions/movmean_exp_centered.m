function out = movmean_exp_centered(in, k)

out_fwd = movmean_exp(in, round(k / 2));
out_bwd = fliplr(movmean_exp(fliplr(in), round(k / 2)));
out = 0.5 * out_fwd + 0.5 * out_bwd;

end