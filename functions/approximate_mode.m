function am = approximate_mode(x)

[N, edges] = histcounts(x);
centers = (edges(1:end-1) + edges(2:end)) / 2;

[~, ami] = max(N);
am = centers(ami);

end