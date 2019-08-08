%% Sharpening state transition timing
%{
The methods we've covered so far are mainly designed to accomplish the
detection of states, but as we saw in the final figure of the previous
chapter, they differ markedly in the exact timepoints chosen for upstate
onset and offset. For example, because of its very definition, voltage
threshold-based upstate detection tends to choose upstate onsets and
offsets that are "tight" around the upstate - most expert observers would
agree that the true upstate "start" is slightly before the algorithmically
chosen onset.

On the other hand, EMA crossover sometimes has a tendency to choose onsets
and offsets that are "loose" around the upstate - since the EMAs are
broadly smoothed versions of the original signal, some temporal blurring
tends to occur.

Because these systematic biases may tend to influence measurements such as
upstate duration or inter-upstate correlation, it becomes important to
accurately measure onset and offset timing. On the one hand, as long as a single
study employs the same technique to quantify all upstates, the same bias
should affect all of their measurements somewhat equally, so condition and
group differences should still be meaningful. But, on the other hand,
condition and group differences may interact with the technique's
onset and offset detection. Also, cross-study comparison will be hindered.
Here, we will primarily focus on onset timing, as similar concepts apply to
offset timing.

There are two main techniques for sharpening onset timing:
1) After detecting upstates using a theshold-based technique, find the point
at which the upstate transition would have occurred using a more sensitive
(i.e. lower) threshold (voltage or STD).
2) Calculate moving slope, and determine the point at which the moving
slope exceeds a theshold, or reaches a maximum.
%}

%% Load the recording, define the time between samples, and define a time vector.

load('recording1_good.mat')
data = data';  % transpose for future convenience

dt = 1 ./ samplingRate;  % dt is the time between samples
time = dt:dt:dt*(length(data));  % this time vector will come in handy later!


%% Ensure that previously defined techniques produce reasonable results

MIN_UP_DUR = 0.5;
MIN_DOWN_DUR = 0.1;
V_THRESH = mode(data) + 7;

[u_ons, u_off] = find_upstates(data, dt, V_THRESH, MIN_UP_DUR, MIN_DOWN_DUR);

STD_WIDTH = 0.05;

dataMSTD = movstd(data, (STD_WIDTH / dt) + 1);

STD_THRESH = 5 * approximate_mode(dataMSTD);

[u_ons_std, u_off_std] = find_upstates(dataMSTD, dt, STD_THRESH, MIN_UP_DUR, MIN_DOWN_DUR);

EMA_WIDTH_SLOW = 10;
EMA_WIDTH_FAST = 0.1;
MIN_UP_DIST = 1;
MIN_DOWN_DIST = 0.15;

[u_ons_cema, u_off_cema] = find_upstates_ema_crossover(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_DIST, MIN_DOWN_DIST);
[u_ons_cema, u_off_cema] = filter_upstates(u_ons_cema, u_off_cema, dt, ...
    MIN_UP_DUR, MIN_DOWN_DUR);

figure(1); clf;
u_ons_seq = {u_ons, u_ons_std, u_ons_cema};
u_off_seq = {u_off, u_off_std, u_off_cema};
labels = {'voltage thresh', 'STD thresh', 'EMA crossover'};
plot_upstate_comparison(time, data, u_ons_seq, u_off_seq, labels);
scrollplot_default(time, 20);

%% For voltage threshold, use a more sensitive threshold to estimate onset/offset timing
% Here we define a more sensitive (lower) voltage threshold and use a new
% function that accepts this transition threshold as an additional input.
% Read the function if you want to know how it works.

V_THRESH_TRANSITION = mode(data) + 3;

[u_ons_sharp_vthresh, u_off_sharp_vthresh] = find_upstates_sharp(data, dt, V_THRESH, V_THRESH_TRANSITION, ...
    MIN_UP_DUR, MIN_DOWN_DUR);

figure(2); clf;
u_ons_seq = {u_ons, u_ons_sharp_vthresh};
u_off_seq = {u_off, u_off_sharp_vthresh};
labels = {'voltage-regular', 'voltage-sharp'};
plot_upstate_comparison(time, data, u_ons_seq, u_off_seq, labels);
scrollplot_default(time, 5);

%% Does the same trick work for STD threshold?
% In short, no, because the moving STD is temporally blurred, so attempting
% to use a more sensitive threshold will not find more accurate transition
% timings.

STD_THRESH_TRANSITION = 2 * approximate_mode(dataMSTD);

[u_ons_std_sharp_vthresh, u_off_std_sharp_vthresh] = find_upstates_sharp(dataMSTD, dt, ...
    STD_THRESH, STD_THRESH_TRANSITION, MIN_UP_DUR, MIN_DOWN_DUR);

figure(3); clf;
u_ons_seq = {u_ons_std, u_ons_std_sharp_vthresh};
u_off_seq = {u_off_std, u_off_std_sharp_vthresh};
labels = {'std-regular', 'std-sharp'};
plot_upstate_comparison(time, data, u_ons_seq, u_off_seq, labels);
scrollplot_default(time, 5);

%% Create a "spike-deleted" copy of the data to better visualize moving slope
% This is because the moving slope during spikes is extremely large and
% overshadows the moving slope everywheere else.

SPIKE_THRESH = -20;
SPIKETHRESH_BACKSET = 0.0015; % 1.2
SPIKETHRESH_FORSET = 0.0055; % 2.2

dataNoSpikes = remove_spikes(data, dt, SPIKE_THRESH, SPIKETHRESH_BACKSET, SPIKETHRESH_FORSET);


%% Visualize moving slope.
% More parameters, yuck! Unfortunately, these are necessary if one wants to
% use slope to sharpen onset timing...

SLOPE_WIDTH = 0.002;  % the timescale over which to calculate slope, in seconds
SLOPE_THRESH = 500;  % in mV / s, i.e. 0.5 mV / ms

dataMovSlope = movingslope(dataNoSpikes, round(SLOPE_WIDTH / dt) + 1, 1, dt);  % the returned slope values are in mV / s

figure(4); clf;
sp1 = subplot(211);
plot(time, dataNoSpikes);
sp2 = subplot(212);
plot(time, dataMovSlope);
hold on;
plot(time([1 end]), [SLOPE_THRESH SLOPE_THRESH], 'r--');
linkaxes([sp1 sp2], 'x');
scrollplot_default(time, 5);

%% For all three techniques, use moving slope to sharpen onset timing.
% Also, filter the resulting upstates by minimum down and upstate duration,
% both because sharpening onset and offset timing may have widened or
% shrank previous up and down state durations, but also to improve the
% fairness of comparison between the three techniques.

BASELINE_DISTANCE = 0.1;  % time period surrounding current onset to check slope values

[u_ons_sharp_slope, u_off_sharp_slope] = sharpen_upstates_slope(data, dt, ...
    u_ons, u_off, SLOPE_WIDTH, SLOPE_THRESH, BASELINE_DISTANCE);
[u_ons_std_sharp_slope, u_off_std_sharp_slope] = sharpen_upstates_slope(data, dt, ...
    u_ons_std, u_off_std, SLOPE_WIDTH, SLOPE_THRESH, BASELINE_DISTANCE);
[u_ons_cema_sharp_slope, u_off_cema_sharp_slope] = sharpen_upstates_slope(data, dt, ...
    u_ons_cema, u_off_cema, SLOPE_WIDTH, SLOPE_THRESH, BASELINE_DISTANCE);

[u_ons_sharp_slope, u_off_sharp_slope] = filter_upstates(u_ons_sharp_slope, u_off_sharp_slope, dt, ...
    MIN_UP_DUR, MIN_DOWN_DUR);
[u_ons_std_sharp_slope, u_off_std_sharp_slope] = filter_upstates(u_ons_std_sharp_slope, u_off_std_sharp_slope, dt, ...
    MIN_UP_DUR, MIN_DOWN_DUR);
[u_ons_cema_sharp_slope, u_off_cema_sharp_slope] = filter_upstates(u_ons_cema_sharp_slope, u_off_cema_sharp_slope, dt, ...
    MIN_UP_DUR, MIN_DOWN_DUR);

%% Compare the sharpened state transition timing

figure(5); clf;

u_ons_seq = {u_ons_sharp_slope, u_ons_std_sharp_slope, u_ons_cema_sharp_slope};
u_off_seq = {u_off_sharp_slope, u_off_std_sharp_slope, u_off_cema_sharp_slope};
labels = {'v-sharp', 'STD-sharp', 'EMA-sharp'};
plot_upstate_comparison(time, data, u_ons_seq, u_off_seq, labels);
scrollplot_default(time, 5);

% Pretty good!
