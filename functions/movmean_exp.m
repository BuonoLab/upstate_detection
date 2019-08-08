function out = movmean_exp(in, k)

nSamps = length(in);
out = in;

ro = k / (k + 1);  % big number
alpha = 1 - ro;  % small number

for sampInd = 2:nSamps
    
    out(sampInd) = ro * out(sampInd - 1) + alpha * in(sampInd);
    
end

end