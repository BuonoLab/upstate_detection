%% Load the recording, define the time between samples, and define a time vector.

load('recording2_drift.mat')
data = data';  % transpose for future convenience
dt = 1 ./ samplingRate;  % dt is the time between samples
time = dt:dt:dt*(length(data));  % this time vector will come in handy later!

%% Plot the voltage time series and its distribution (as a line plot).
% (Look at your data!)

figure(1); clf;  % initialize the figure by number to avoid figure build-up if this gets re-run
p = plot(time, data, 'k');  % the two arguments to plot are the x values and the y values
p.Color(4) = 0.2;
xlabel('Time (s)');
ylabel('Potential (mv)');

figure(2); clf;  % clf clears the figure if it already exists
[dataHistCounts, binEdges] = histcounts(data, min(data):0.5:-40);
binCenters = (binEdges(1:end - 1) + binEdges(2:end)) / 2;
plot(binCenters, dataHistCounts, 'k');
xlabel('Potential (mv)');
ylabel('# of occurrences');

%{
Notice that this data, while still being a decent recording, is not as clean as the previous example.
The resting membrane potential drifts upward slowly throughout the recording.
As a result, the voltage histogram does not have a typical shape. The resting membrane potential
(i.e. the left-hand peak) is not as well-defined, and the distribution is not clearly bimodal.

Ideally, recording conditions will be such that this does not happen.
Nevertheless, we should be prepared to deal with it. This also will allow us
to demonstrate that some upstate detection methods are impervious to drift.
%}

%% Let's try performing a voltage threshold-based upstate detection on the raw data.

vRestRaw = mode(data);  % resting membrane potential

V_THRESH = vRestRaw + 7;  % voltage threshold
MIN_UP_DUR = 0.5;  % minimum up state duration
MIN_DOWN_DUR = 0.1;  % minimum down state duration

[u_ons, u_off] = find_upstates(data, dt, V_THRESH, MIN_UP_DUR, MIN_DOWN_DUR);

figure(3); clf;
plot_upstates(time, data, u_ons, u_off);
title('Voltage threshold fails in the presence of drift (without detrending)');

% While this approach works decently well in the first part of the recording,
% it begins to completely break down as the resting membrane potential drifts above the threshold.

% If the goal is to separate down and up state using a voltage threshold, drift will cause
% huge problems.
% One quick fix for the purposes of threshold-based upstate detection is a linear detrend.

%% Create a linearly detrended copy of the raw data.
% A linear detrend works as follows:
% 1) Fit a linear model (i.e. regression) across the sequential points in the whole time series.
% 2) Subtract the linear component of the model from the data.
% In ideal conditions, this means that the linear drift will be subtracted, leaving
% the variation around the linear trend behind.

% Because it also subtracts the y-intercept from the linear model, we will add our previous
% estimate of the resting membrane potential back, to re-center it in the y-axis.
dataDetrended = detrend(data) + vRestRaw;

vRestDetrended = mode(dataDetrended);

% Let's superimpose the detrended time series and distribution back to our initial plots
% to compare them.
figure(1);
hold on;
p = plot(time, dataDetrended, 'b');
p.Color(4) = 0.2;
legend('Raw', 'Detrended');

figure(2);
hold on;
[dataHistCounts, binEdges] = histcounts(dataDetrended, min(dataDetrended):0.5:-40);
binCenters = (binEdges(1:end - 1) + binEdges(2:end)) / 2;
plot(binCenters, dataHistCounts, 'b');
legend('Raw', 'Detrended');

% Note that in the detrended data, the resting membrane potential is more stable,
% and the corresponding peak of the voltage distribution is more well-defined.
% However, the detrend should not be used lightly, as it fundamentally alters
% your data in a manner that many would not consider to be "fair."

%% Optimizing choice of threshold
% Before we attempt voltage threshold-based upstate detection on the detrended data,
% let's briefly touch on the concept of choosing a good threshold.

% In the previous chapter and above, we chose the threshold to be the resting potential
% plus a constant value. This will work in many cases, but is it the best choice?

% One approach is to determine the value of the inter-mode minimum in the voltage histogram.
% I wrote a function that does this, based on the concept that the voltage distribution
% will be bimodal and the two peaks will be separated by a certain amount.
% More specifically, to use the function, we need to define two parameters:
% 1) The bin size for the histogram, in mV.
% 2) About how separated the two mode peaks should be, in mV.
BINSIZE_V = .1;  % mV
SEPARATION_V = 7;  % mV

figure(4); clf;
V_THRESH = estimate_threshold(dataDetrended, BINSIZE_V, SEPARATION_V, true);
xlabel('Potential (mV)');
ylabel('# of occurences');
title('Optimizing choice of voltage threshold');

%% Visualizing supra- and sub-threshold durations
% As in the previous chapter, let's visualize the distribution of supra- and sub-threshold
% durations in the median-filtered data. This will give us an idea of what our minimum
% up and down state durations should be.
% It's also just a good idea, to get a feel for the interaction between your choice of threshold
% and your data.

MEDIAN_FILTER_WIDTH = 0.1;  % 100 ms

dataMedf = medfilt1(dataDetrended, round(MEDIAN_FILTER_WIDTH / dt) + 1, 'truncate');

[upCrossings, downCrossings, downDurs, upDurs] = investigate_crossings(dataMedf, dt, V_THRESH);

figure(5); clf;

subplot(211);
histogram(upDurs, 0:.04:2);  % bin edges are chosen carefully
xlabel('Time (s)');
ylabel('# of occurrences');
title('putative Up state durations');

subplot(212);
histogram(downDurs, 0:.2:10);  % bin edges are chosen carefully
xlabel('Time (s)');
ylabel('# of occurrences');
title('putative Down state durations');

% Based on this, I don't think the previous parameters for minimimum upstate and downstate
% durations need to be changed, although one could make the argument to increase
% the minimum downstate duration.

%% Applying voltage threshold-based upstate detection to the detrended data
% Now that the data have been detrended, and an optimal voltage threshold has
% been determined, voltage threshold-based upstated detection should perform better.

MIN_UP_DUR = 0.5;
MIN_DOWN_DUR = 0.1;

% *** NOTE: I use dataDetrended rather than data ! ***
[u_ons, u_off] = find_upstates(dataDetrended, dt, V_THRESH, MIN_UP_DUR, MIN_DOWN_DUR);
% [u_ons, u_off] = find_upstates(dataDetrended, dt, vRestDetrended + 7, MIN_UP_DUR, MIN_DOWN_DUR);

figure(6); clf;
plot_upstates(time, data, u_ons, u_off);
title('Voltage thresh succeeds when applied to detrended signal');

% After detrending and choosing a more optimal voltage threshold,
% our voltage threshold-based upstate detection looks pretty good!
% But is there a way we can achieve a similar result without detrending?

%% Attempting variance threshold-based upstate detection
%{
Volgushev, M., Chauvette, S., Mukovski, M. & Timofeev, I. J. Neurosci. (2006).
Precise long-range synchronization of activity and silence in neocortical
neurons during slow-wave oscillations

Mann, E. O., Kohl, M. M. & Paulsen, O. J. Neurosci. (2009).
Distinct Roles of GABA-A and GABA-B Receptors in Balancing and Terminating
Persistent Cortical Activity.

Concept also used as a "backup" method in:
Neske, G. T., Patrick, S. L. & Connors, B. W. J. Neurosci. (2015).
Contributions of Diverse Excitatory and Inhibitory Neurons to Recurrent
Network Activity in Cerebral Cortex.

Typically upstates are associated not only with an increase in voltage, but also an increase
in variability of voltage over time. In other words, the voltage trace not only goes up,
but it becomes more wiggly and noisy. This fact has led several researchers to use the moving
standard deviation to detect upstates. Moving standard deviations are the second kind of moving
operation we have encountered (the first being the moving median), and they behave exactly as you
would expect: each point in the moving standard deviation represents the standard deviation across
points within some time window surrounding that point. Here, we choose a 50 ms window, which falls right
in the middle of the ballpark of what published scientific articles have used.

First, let's simply examine the moving standard deviation of the trace and its distribution.
%}

STD_WIDTH = 0.05;

% Notice that we apply movstd to the raw trace, rather than the detrended trace.
dataMSTD = movstd(data, (STD_WIDTH / dt) + 1);
figure(6); clf;
subplot(211);
plot(time, data);
title('Original data');
subplot(212);
plot(time, dataMSTD);
title('Moving standard deviation');

figure(7); clf;
histogram(dataMSTD);
title('Most values in the moving STD trace are small');

% Right away we see a few things:
% First, the moving STD is bounded at 0.
% Second, during upstates, the moving standard deviation also tends to increase.
% Third, the distribution of moving STD values is heavily skewed toward 0,
% and the mode of this distribution represents the baseline or "resting"
% value of the moving STD.

%% Use the moving standard deviation to detect upstates.
%{
This will function nearly identically to the voltage threshold-based approaches,
but instead of using the data trace, we will use the moving standard deviation.
This also means that we will have to choose a threshold, in units of standard deviation.
Here, I choose 5 times the "baseline" moving standard deviation value, which I 
estimate using the mode. After detecting upstates in this way,
we will plot a comparison of the upstates chosen by the two methods to each other.
I will also add a scroll bar to the plot so that the upstates can be compared
more closely.
%}

STD_THRESH = 5 * mode(dataMSTD);

[u_ons_std, u_off_std] = find_upstates(dataMSTD, dt, STD_THRESH, MIN_UP_DUR, MIN_DOWN_DUR);

figure(8); clf;
u_ons_seq = {u_ons, u_ons_std};
u_off_seq = {u_off, u_off_std};
labels = {'voltage-based', 'STD-based'};
plot_upstate_comparison(time, data, u_ons_seq, u_off_seq, labels);
scrollplot_default(time, 20);

%{
*** For this particular dataset and with the currently chosen paramters ***
performing upstate detection using the moving standard deviation had a few advantages:
1) The data did not have to be detrended.
2) The threshold did not have to be chosen carefully.
3) According to most observers' standards, STD-based upstate detection performed slightly better.
It detected one upstate not detected by the voltage-based approach and correctly detected an upstate
that the voltage-based broke into two upstates.

These problems could have potentially been fixed by altering some of the parameters
in the voltage-based approach. However, the parameter-light approach provided by
the moving STD is arguably superior.
%}
