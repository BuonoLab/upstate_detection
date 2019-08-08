%% Load the recording, define the time between samples, and define a time vector.

% load('recording1_good.mat')
% load('recording2_drift.mat')
load('recording3_drift.mat')
% load('recording4_drift.mat')
% load('recording5_nonlinear_drift.mat')
% load('recording6_nonlinear_drift.mat')
% load('recording7_extremedrift.mat')
% load('recording8_noisydrift.mat')
% load('recording9_submerged.mat')
% load('recordingA_driftsubmerged.mat')
data = data';  % transpose for future convenience
dt = 1 ./ samplingRate;  % dt is the time between samples
time = dt:dt:dt*(length(data));  % this time vector will come in handy later!

%% Upstate detection through crossover of exponential moving averages

%{
Seamari, Y., Narváez, J. A., Vico, F. J., Lobo, D. & Sanchez-Vives, M. V. PLoS One (2007).
Robust Off- and Online Separation of Intracellularly Recorded Up and Down Cortical States.
Original code available at http://www.geb.uma.es/mauds

Concept also used by:
Neske, G. T., Patrick, S. L. & Connors, B. W. J. Neurosci. (2015).
Contributions of Diverse Excitatory and Inhibitory Neurons to Recurrent
Network Activity in Cerebral Cortex

For more information on how this method works, please read the original
publication. Long story short, although the method seems like it's great,
the code they provided does not work well on our data under the conditions
they claim it will work well (e.g. drift). For example, see below:
%}

figure(1); clf;
plotMaudsFromData(data, samplingRate);
title('Out-of-the-box mauds4matlab solution from Seamari et al. 2007', ...
    'FontSize', 18);

%{
Furthermore, while the method may seem to have very few chosen parameters,
the authors' implementation has six, or, arguably, seven. The two essential
parameters for any analysis of this kind are the timescales of the slow and
fast exponential moving averages (EMAs). However, the authors'
implementation also include four parameters related to sharpening onset and
offset time estimates and one parameter related to rejecting short states.
Actually, these two steps (sharpening onset/offset timing and rejecting
states based on duration) are arguably irrelevant to state detection and
can always be applied post hoc!
%}

%% So... is the method useful?

%{
Actually, I think the concept of using crossover of EMAs is potentially
very useful. Not only that, but after applying a few modifications to
the concept, I was able to make it perform quite well as a truly "robust"
but strictly offline method for detecting upstates. The modifications are
as follows:

1. The original method uses a tradtional EMA: each point is a weighted average of
**past** points (and the weights decrease exponentially from the current point).
In part, this approach was taken so that it could be applied in realtime where only
past points are known. However, for offline upstate detection, the method should
become more accurate if each point is a weighted average of both past and **future**
points (with weights decreasing exponentially on either side). To achieve
this, I calculated the EMA both forwards in time and backwards in time and
averaged the two together (another important detail is that for each of the
forward and backward EMAs, the time scale should be half of what it would
have been, so that the timescale of the "centered" EMA is the same as it would
have been in a purely time-forward scenario.)

2. The original method considers any interval between crossings of the slow
and fast EMAs to be a putative state no matter how far apart they are from
each other during that interval. This approach is extremely susceptible to
noise in the original signal, even though the EMAs are much smoother.
In fact, the average distance between EMAs in a given interval between
crossings is heavily skewed toward small values; most of these EMA
crossings are inconsequential and can be safely ignored. Here, I introduce
two additional parameters to handle this problem. The two parameters describe
how far the EMAs must be from each other in order for them to be considered
consequential, i.e. to signify upstates (first param) and downstates (second param).

3. I then use the above two parameters to institue two rules for pruning
the initial set of putative states given by EMA crossover:
Step 1: Only putative upstates above the upstate EMA distance threshold are
considered, and all others are labeled sub-threshold and will be deleted.
Step 2: Sets of consecutive sub-threshold down- and upstates that intervene
between supra-threshold upstates are deleted, effectively combining the
surrounding pair of consequential upstates.
%}

%% Let's take a look at the EMAs and their crossover regions.
% Note: the below plot takes a long time depending on the length of the
% trace, so I only plot a short 20 s segment.

% Here I define the widths (in seconds) of the slow and fast EMAs
% Seamari et al. use 6 s and 0.1 s
% Neske et al. use 10 s and 0.1 s
EMA_WIDTH_SLOW = 10;  % 2 - 10 s
EMA_WIDTH_FAST = 0.1; % .025 - .1 s

% If you're interested in how the EMA is calculated, inspect the movmean_exp function.
dataSlowEMAForward = movmean_exp(data, round(EMA_WIDTH_SLOW / 2 / dt));

% Here, I flip the input so that the EMA is computed moving backwards in
% time, then I flip the output to orient it correctly with respect to the data.
dataSlowEMABackward = flipud(movmean_exp(flipud(data), round(EMA_WIDTH_SLOW / 2 / dt)));

% Do the same for the fast EMA.
dataFastEMAForward = movmean_exp(data, round(EMA_WIDTH_FAST / 2 / dt));
dataFastEMABackward = flipud(movmean_exp(flipud(data), round(EMA_WIDTH_FAST / 2 / dt)));

% I simply average the forward and backward together.
dataSlowEMA1 = 0.5 * dataSlowEMAForward + 0.5 * dataSlowEMABackward;
dataFastEMA1 = 0.5 * dataFastEMAForward + 0.5 * dataFastEMABackward;

showTime = 20;
showPts = round(showTime / dt);

figure(2); clf;
p = plot(time(1:showPts), data(1:showPts), 'k');
p.Color(4) = 0.1;
hold on;
plot(time(1:showPts), dataSlowEMA1(1:showPts), 'g');
plot(time(1:showPts), dataFastEMA1(1:showPts), 'r');
fill_between(time(1:showPts), dataSlowEMA1(1:showPts), dataFastEMA1(1:showPts));
fill_between(time(1:showPts), dataFastEMA1(1:showPts), dataSlowEMA1(1:showPts));
xlabel('Time (s)');
ylabel('Potential (mv)');

%{
The red trace is the fast EMA, and the green trace is the slow EMA.
The yellow shaded region shows the area between them.
The "positive" regions where the fast EMA (red) exceeds the slow EMA (green)
represent putative upstates.
The "negative" regions where the fast EMA (red) falls below the slow EMA (green)
represent putative downstates.
Notice that most yellow regions are small.
We argue they should be ignored below a certain threshold of smallness.
%}

%% How far apart are the two EMAs between crossings?
% Let's plot the distribution of average inter-EMA distances.

[up_dists, down_dists] = investigate_states_ema_crossover(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST);

figure(3); clf;
subplot(211);
histogram(up_dists, 0:.1:max(up_dists));  % bin edges are chosen carefully
xlabel('Average putative state inter-EMA distance (mV)');
ylabel('# of occurrences');
title('Up (fast > slow)');

subplot(212);
histogram(down_dists, 0:.02:max(down_dists));  % bin edges are chosen carefully
xlabel('Average putative state inter-EMA distance (mV)');
ylabel('# of occurrences');
title('Down (slow > fast');

%% Now let's actually find upstates using EMA crossover.

% Based on the above distributions, I chose the following parameters for
% the minimum up and down state inter-EMA distances.
MIN_UP_DIST = 1;
MIN_DOWN_DIST = 0.15;

[u_ons_cema, u_off_cema] = find_upstates_ema_crossover(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_DIST, MIN_DOWN_DIST);

figure(4); clf;
plot_upstates(time, data, u_ons_cema, u_off_cema);
scrollplot_default(time, 20);

% Note that I haven't filtered out short events. This is to emphasize that using
% filters based on putative state duration to get good detection results is
% unnecessary using crossover of EMAs. Instead, here we focused on the
% amplitude of crossover to filter out noise-driven state estimates.

%% Let's compare all three techniques thus far.
% To make the comparison fair, I'll try to filter out short states from the
% crossover of moving averages (otherwise it will look like the other
% didn't detect these short states when in truth, they did to some extent.)
% However, since the EMA technique tends to estimate upstate onsets to be
% earlier and offsets to be later, many of the shorter upstates will get
% through the filter.

MIN_UP_DUR = 0.5;
MIN_DOWN_DUR = 0.1;

vRestRaw = mode(data);
dataDetrended = detrend(data) + vRestRaw;
vRestDetrended = mode(dataDetrended);
[u_ons, u_off] = find_upstates(dataDetrended, dt, vRestDetrended + 5, MIN_UP_DUR, MIN_DOWN_DUR);

STD_WIDTH = 0.05;

dataMSTD = movstd(data, (STD_WIDTH / dt) + 1);

STD_THRESH = 5 * approximate_mode(dataMSTD);

[u_ons_std, u_off_std] = find_upstates(dataMSTD, dt, STD_THRESH, MIN_UP_DUR, MIN_DOWN_DUR);

[u_ons_cema, u_off_cema] = find_upstates_ema_crossover(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_DIST, MIN_DOWN_DIST);
[u_ons_cema, u_off_cema] = filter_upstates(u_ons_cema, u_off_cema, dt, ...
    MIN_UP_DUR, MIN_DOWN_DUR);

figure(5); clf;
u_ons_seq = {u_ons, u_ons_std, u_ons_cema};
u_off_seq = {u_off, u_off_std, u_off_cema};
labels = {'voltage thresh', 'STD thresh', 'EMA crossover'};
plot_upstate_comparison(time, data, u_ons_seq, u_off_seq, labels);
scrollplot_default(time, 20);
