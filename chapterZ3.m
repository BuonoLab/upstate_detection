%% Load the recording, define the time between samples, and define a time vector.

clear;
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
Seamari, Y., Narváez, J. A., Vico, F. J., Lobo, D. & Sanchez-Vives, M. V.
PLoS One (2007). Robust Off- and Online Separation of Intracellularly
Recorded Up and Down Cortical States. Original code available at
http://www.geb.uma.es/mauds

Concept also used by: Neske, G. T., Patrick, S. L. & Connors, B. W.
J. Neurosci. (2015). Contributions of Diverse Excitatory and Inhibitory
Neurons to Recurrent Network Activity in Cerebral Cortex

For more information on how this method works, please read the original
publication. Long story short, although the method seems like it's great,
the code they provided does not work well on our data under the conditions
they claim it will work well (e.g. drift). For example, see below:
%}

figure(1); clf;
plotMaudsFromData(data, samplingRate);

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
consequential, i.e. to signify upstates and downstates.

I then use the above two parameters to institue two rules for pruning
the initial set of putative states given by EMA crossover:
1) Only putative upstates above the upstate EMA distance threshold are
considered, all others are considered inconsequential and deleted.
2) Sets of consecutively inconsequential down- and upstates that intervene
between consequential upstates are deleted, effectively combining the
surrounding pair of consequential upstates.
%}

% Seamari et al. use 6 s and 0.1 s
% Neske et al. use 10 s and 0.1 s
EMA_WIDTH_SLOW = 10;  % 2 - 10 s
EMA_WIDTH_FAST = 0.1; % .025 - .1 s

dataSlowEMAForward = movmean_exp(data, round(EMA_WIDTH_SLOW / 2 / dt));
dataSlowEMABackward = flipud(movmean_exp(flipud(data), round(EMA_WIDTH_SLOW / 2 / dt)));
dataFastEMAForward = movmean_exp(data, round(EMA_WIDTH_FAST / 2 / dt));
dataFastEMABackward = flipud(movmean_exp(flipud(data), round(EMA_WIDTH_FAST / 2 / dt)));

dataSlowEMA1 = 0.5 * dataSlowEMAForward + 0.5 * dataSlowEMABackward;
dataFastEMA1 = 0.5 * dataFastEMAForward + 0.5 * dataFastEMABackward;

figure(1); clf;
p = plot(time, data, 'k');
p.Color(4) = 0.2;
hold on;
plot(time, dataSlowEMA1, 'g');
plot(time, dataFastEMA1, 'r');
% fill([time fliplr(time)], [dataSlowEMA1' fliplr(dataFastEMA1')], 'b');
% fill_between(time, dataSlowEMA1, dataFastEMA1);
scrollplot_default;

%% investigate the actual distribution of ups and downs

% MIN_UP_AREA = 0.5;
% MIN_DOWN_AREA = 0.04;
MIN_UP_AREA = 1;
MIN_DOWN_AREA = 0.15;

% [ups, downs] = find_upstates_ema_crossover4(data, dt, ...
%     EMA_WIDTH_SLOW, EMA_WIDTH_FAST, [], []);

% MEDIAN_FILTER_WIDTH = 0.1;  % 100 ms
% dataMedf = medfilt1(data, round(MEDIAN_FILTER_WIDTH / dt) + 1, 'truncate');

[ups, downs, up_areas, down_areas] = investigate_upstates_ema_crossover7_mean(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_AREA, MIN_DOWN_AREA, [], []);

down_durs = [ups(2:end) length(data)] - downs;  % consider the end of the recording to be the final "up"
up_durs = downs - ups;

figure(4); clf;
subplot(211);
histogram(up_durs * dt, 0:.04:2);  % bin edges are chosen carefully
xlabel('Time (s)');
ylabel('# of occurrences');
title('putative Up state durations');

subplot(212);
% histogram(down_durs * dt, 0:.2:10);  % bin edges are chosen carefully
histogram(down_durs * dt, 0:.04:2);  % bin edges are chosen carefully
xlabel('Time (s)');
ylabel('# of occurrences');
title('putative Down state durations');

figure(5); clf;
subplot(211);
% histogram(up_areas);  % bin edges are chosen carefully
histogram(up_areas, 0:.01:1);  % bin edges are chosen carefully
% histogram(up_areas * dt, 0:.2:max(up_areas * dt));  % bin edges are chosen carefully
% histogram(up_areas * dt, 0:.02:1);  % bin edges are chosen carefully
% histogram(up_areas * dt);  % bin edges are chosen carefully
xlabel('Area (mV * ms)');
ylabel('# of occurrences');
title('putative Up state amplitudes');

subplot(212);
% histogram(down_areas);  % bin edges are chosen carefully
histogram(down_areas, 0:.01:1);  % bin edges are chosen carefully
% histogram(down_areas * dt, 0:.2:max(down_areas * dt));  % bin edges are chosen carefully
% histogram(down_areas * dt, 0:.02:1);  % bin edges are chosen carefully
% histogram(down_areas * dt);  % bin edges are chosen carefully
xlabel('Area (mV * ms)');
ylabel('# of occurrences');
title('putative Down state amplitudes');

%%

% by Neske
MIN_UP_DUR = 0.5;  % minimum up state duration
MIN_DOWN_DUR = 0.1;  % minimum down state duration

% [u_ons_neske, u_off_neske] = find_upstates_ema_crossover5(data, dt, ...
%     EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_DUR, MIN_DOWN_DUR);
% [u_ons_neske, u_off_neske] = find_upstates_ema_crossover7(data, dt, ...
%     EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_AREA, MIN_DOWN_AREA, MIN_UP_DUR, MIN_DOWN_DUR);
% [u_ons_neske, u_off_neske] = find_upstates_ema_crossover7(data, dt, ...
%     EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_AREA, MIN_DOWN_AREA, [], []);
% [u_ons_neske, u_off_neske] = find_upstates_ema_crossover7_mean(data, dt, ...
%     EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_AREA, MIN_DOWN_AREA, [], []);
% [u_ons_neske, u_off_neske] = find_upstates_ema_crossover8_mean(data, dt, ...
%     EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_AREA, MIN_DOWN_AREA, [], []);

[u_ons_neske1, u_off_neske1] = find_upstates_ema_crossover7_mean(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_AREA, MIN_DOWN_AREA, [], []);
[u_ons_neske2, u_off_neske2] = find_upstates_ema_crossover8_mean(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_AREA, MIN_DOWN_AREA, [], []);
[u_ons_neske3, u_off_neske3] = find_upstates_ema_crossover9_mean(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_AREA, MIN_DOWN_AREA, [], []);

figure(2); clf;

% plot_upstates(time, data, u_ons_neske, u_off_neske);
% scrollplot_default;

u_ons_seq = {u_ons_neske1, u_ons_neske2, u_ons_neske3};
u_off_seq = {u_off_neske1, u_off_neske2, u_off_neske3};
labels = {'1', '2', '3'};
plot_upstate_comparison(time, data, u_ons_seq, u_off_seq, labels);
scrollplot_default;
