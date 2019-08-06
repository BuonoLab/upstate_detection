%% Load the recording, define the time between samples, and define a time vector.

load('recording1_good.mat')
data = data';  % transpose for future convenience

dt = 1 ./ samplingRate;  % dt is the time between samples
time = dt:dt:dt*(length(data));  % this time vector will come in handy later!

% Note that I define time value in seconds, not milliseconds.
% This is simply my preference.

%% First, let's visualize the time series. Look at your data!

figure(1); clf;  % initialize the figure by number to avoid figure build-up if this gets re-run
plot(time, data);  % the two arguments to plot are the x values and the y values
xlabel('Time (s)');
ylabel('Potential (mv)');

% Note: because I included time as an argument to plot, the x axis is in units of seconds.
% This is useful because anyone can understand what it means without needing to know the sampling rate.

% This recording is pretty good. By eye, we can see that the
% resting membrane potential and spike amplitude are reasonably stable.

%% Next, let's visualize the distribution of voltage values with a histogram.
% Since I know that the spikes present in the data will skew the histogram,
% I will choose my bins ahead of time, to go from the minimum of the data to
% just above spike threshold, -40 mV, in steps of 0.5 mV.

figure(2); clf;  % clf clears the figure if it already exists
histogram(data, min(data):0.5:-40);  % second argument can specify the exact edges to use
xlabel('Potential (mv)');
ylabel('# of occurrences');

% There is a clear bimodal distribution of voltage in the data (two peaks).
% This provides evidence for two-state dynamics: the so-called Down and Up states.

% The Down state mode, on the left, is dominated by the resting membrane potential.

% The Up state mode, on the right, represents a state during which the recorded cell
% receives huge barrages of synaptic currents that keep it stably depolarized for up to a few seconds.
% The recorded cell often, but not always, fires action potentials (spikes) during the Up state.

%% Measuring the peaks of the modes of the Up and Down states.
% For reasonable data, the location of the peak of the left-hand mode will be roughly equivalent to the
% resting membrane potential. Because the data spends more time in the Down state,
% the peak of the left-hand mode is larger, and it can be well estimated by the (overall) mode.
% Note: this is identical to the x-value of the peak of the left-hand mode of the voltage distribution.

vRestRaw = mode(data);

% The right-hand peak is slightly more difficult to estimate, but it can be done if we simply
% take the mode of the voltage values that are above a threshold that separates the Up and Down states.
% Eyeballing the data tells us that a good threshold might be -60 mV, which is about 7 mV above resting.

% In the following statement, I use logical indexing to get all the data in the right-hand part
% of the distribution, which is all more than 7 mV above the left-hand peak.
dataAboveDownState = data(data > vRestRaw + 7);

% Now I use mode again to get the peak of that part of the distribution.
upMode = mode(dataAboveDownState);

% What should we do if we want to identify which periods of time are Down and Up states?
% There are two main approaches:
    % 1) Threshold-based.
    % 2) Crossover of moving averages.
    
%% Approach 1: Define states above and below a voltage threshold to be "Up" and "Down," respectively.
% To best distinguish the two states using a threshold, the first step is to choose a threshold.
% In the previous section we estimated the mode of the Up states by separating data more than
% 5 mV above the Down mode. So in a sense, we already used a threshold.
% Let's define that formally and plot it on the time series.

V_THRESH = vRestRaw + 7;

figure(1); clf;
plot(time, data);
hold on;  % to prevent erasing the previous plot
plot(time([1 end]), [V_THRESH V_THRESH], 'r--');
xlabel('Time (s)');
ylabel('Potential (mv)');

% What if we simply define all time periods at or above the threshold to be Up states,
% and those below to be Down states?
aboveThresh = data >= V_THRESH;

% In the below code, I simply make copies of data in which the below and above threshold values
% are changed into "NaN" or "Not a Number" values so that when plotted, those values are not shown.
dataAboveThresh = data;
dataBelowThresh = data;
dataAboveThresh(~aboveThresh) = NaN;
dataBelowThresh(aboveThresh) = NaN;

figure(3); clf;
plot(time, dataAboveThresh, 'g');
hold on;
plot(time, dataBelowThresh, 'b');
xlabel('Time (s)');
ylabel('Potential (mv)');
legend('putative Up states', 'putative Down states');

% An initial problem with this approach is that membrane voltage is noisy and variable.
% Sometimes, it crosses threshold extremely briefly. It is unlikely that these small crossings
% represent a true state change. How can we deal with the noisiness present in the data?

%% 1) Median filtering
% Median filtering introduces the concept of "moving operations" that will appear repeatedly.
% A moving operation is a signal processing tool for time series data in which an operation
% is calculated within a "window" of the data. Then, that window "slides" forward in time
% across the data, and the operation is repeated. The result is a new time series that is the same
% size as the original data, but each value represents the result of the moving operation.

% In this case, the operation is the median function.
% The time window we will use is 100 ms.

MEDIAN_FILTER_WIDTH = 0.1;  % 100 ms

% The second argument is the number of *points* to perform the median across,
% so I have to convert time to points by dividing by dt. I add 1 because the median
% works best when given an odd number of points.
% The third argument specifies that at the edges, the sliding window should be
% truncated (the default behavior is to assume 0s, which would be incorrect for this data).

dataMedf = medfilt1(data, round(MEDIAN_FILTER_WIDTH / dt) + 1, 'truncate');

% Now let's plot the result superimposed on the raw data.

figure(1); clf;
p = plot(time, data, 'k');
p.Color(4) = 0.1; % this sets the transparency of the raw time series to 10% to make it less visible
hold on;  % to prevent erasing the previous plot
plot(time([1 end]), [V_THRESH V_THRESH], 'r--');
plot(time, dataMedf, 'b');
xlabel('Time (s)');
ylabel('Potential (mv)');
legend('raw data', 'threshold', 'median filtered data');

% Let's also re-do our threshold-based classification using the median-filtered data.

aboveThresh = dataMedf >= V_THRESH;

dataAboveThresh = data;
dataBelowThresh = data;
dataAboveThresh(~aboveThresh) = NaN;
dataBelowThresh(aboveThresh) = NaN;

figure(3); clf;
plot(time, dataAboveThresh, 'g');
hold on;
plot(time, dataBelowThresh, 'b');
xlabel('Time (s)');
ylabel('Potential (mv)');
legend('putative Up states', 'putative Down states');

% Applying the new classification to the raw data now shows that some of the brief, noisy events
% that go above threshold are now considered to be below threshold, when the classification
% was based on the median filtered data.

% But not all of them.
% The remaining ones were large and/or long in duration (relative to the median filter width).
% So what do we do? We have two choices:
	% 1) Make our threshold higher and/or make our median filter wider, if necessary.
    % 2) Filter the above-threshold events: some will be considered true Up states,
    %    while the rest will be considered "events."

% For now, it is perhaps a good idea to examine the current classification
% and think about it before proceeding.

%% Let's visualize the distribution of above and below-threshold periods
% I wrote a function to do this. It's not intended for wide usage so it's not well-commented.
% It takes as its three arguments:
% 1) the time-series, 2) dt, 3) the voltage threshold
% And it returns:
% 1) the times of upward crossings, 2) the times of downward crossings,
% 3) the down durations, 4) the up durations
% (all outputs are in the same units as dt - here, seconds)

% Note that I use dataMedf as the input time-series here.
[upCrossings, downCrossings, downDurs, upDurs] = investigate_crossings(dataMedf, dt, V_THRESH);

figure(4); clf;

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

% There is no overwhelmingly clear interpretation of these distributions.
% For putative Up state durations, it looks like there may be a mound between 40 ms and 400 ms,
% while the rest are scattered from 500 ms up to 2 s.

% For putative Down state durations, the most common Down state length is about 3 s,
% and most are between 1 and 6 s, with a handful being longer.
% Also, a handful are very short ( < 400 ms).

%% Applying minimum upstate and downstate durations (i.e. filtering putative Up and Down states).

%{
Often at this point in analysis, we filter the putative up and down states to achieve
a classification in which each category (i.e. Up states vs. events) contains a relatively homogenous
set of phenomena. Much of this is based on experience and intuition, but as our previous
visualization of the Up and Down durations showed, it can be empirically justified based on the data.

For example, we can apply a minimum downstate duration of 100 ms by taking any putative downstate
classification that is shorter than 100 ms and deleting that label.
Practically speaking, the result is that the preceding and following upstates will be combined.
This is often a correcting operation that rejects spurious putative Down states that
are actually short interruptions of a single Up state.

On the other hand, applying a minimum upstate duration should probably be considered
a purely semantic move. It simply labels putative Up states that are shorter than the minimum duration
as "events" rather than Up states... Thus, they are separated for all further analysis.
Each analysis should consider carefully whether these events should be considered to be
part of the Down state.

In the current analysis, as in most, we will simply ignore the shorter "events" and focus on longer
putative Up states. We will use chosen values for the minimum "true" Up state duration
and minimum Down state duration. To apply these parameters, we will use the function 'find_upstates'
which you should read to see how it works.

Note that deleting short putative Down states and rejecting short putative Up states
performs a similar function to using a median filtered version of the data.
Short excursions above and below threshold that caused by noise will not influence
our chosen up and down states. Thus, it is not necessary to median filter the input
to 'find_upstates.' However, it could help in some datasets.
%}

MIN_UP_DUR = 0.5;
MIN_DOWN_DUR = 0.1;

[u_ons, u_off] = find_upstates(data, dt, V_THRESH, MIN_UP_DUR, MIN_DOWN_DUR);

figure(5); clf;
plot_upstates(time, data, u_ons, u_off);

%% What now?
% The world is your oyster. Here are some ideas for things you could do:
%{
1) Segment the upstates out of the raw recording.
2) Plot all upstates superimposed
3) Calculate each upstate and downstate's duration
4) Calculate the upstate frequency in the data
5) Calculate the variance of the upstate vs. downstate
6) Calculate the correlation between each pair of upstates
7) Etc
%}
