%% Load the recording, define the time between samples, and define a time vector.

load('recording1_good.mat');
data = data';  % transpose for future convenience

dt = 1 ./ samplingRate;  % dt is the time between samples
time = dt:dt:dt*(length(data));  % this time vector will come in handy later!

% Note that I define time value in seconds, not milliseconds.
% This is simply my preference.

%% find a segment with a nice onset to detect
% here i pick a 1 s segment with a ~2 mV deflection in the middle
% let's see if this works

START_SAMP = 20000;
END_SAMP = 30000;

timeSegment = -0.4:dt:(0.6 - dt);
dataSegment = data(START_SAMP:END_SAMP - 1);

figure(1); clf;
plot(timeSegment, dataSegment);
xlabel('Time (s)');
ylabel('mV');

%% define the baseline period with respect to the epoch
% i have defined timeSegment above carefully for this to make sense
% let's pretend there was a very small stimulus at 0.4 seconds
% let's call that timepoint 0 and define the baseline as -0.4 to 0
% you may want to be conservative and make the baseline period end just
% before 0 if the event happens right away (i.e. -0.4 to -0.1 might be better)

BASELINE_START = -0.4;
BASELINE_END = 0;

% first let's make a logical mask of the same size as dataSegment that has
% "true" wherever we are in the baseline
baselineBool = (timeSegment < BASELINE_END) & (timeSegment >= BASELINE_START);

% now let's calculate the mean and std of only that portion of the
% dataSegment
baselineMean = mean(dataSegment(baselineBool));
baselineSTD = std(dataSegment(baselineBool));

% note that here, mean and STD are scalars but if your data is
% multidimensional (i.e. time x trials, etc.) this whole operation can be
% vectorized and done on the arrays... using for loops is not required
% although you can

% next is the crucial step, where we convert the data from mV into
% "deviation", which means the statistical deviation from the mean of the
% baseline in units of the std of the baseline

dataSegmentDeviation = (dataSegment - baselineMean) ./ baselineSTD;


figure(2); clf;
plot(timeSegment, dataSegmentDeviation);
xlabel('Time (s)');
ylabel('STDs from baseline mean');

%% define a STD threshold and define the "onset"
% usually as the point at which the deviation exceed the threshold

STD_THRESHOLD = 5;

% here we use "find" on the logical array which is true when the deviation
% is above threshold. the second argument (1) specifies we just want to find the
% index of the first appearance of a true (i.e. the first time we exceed
% threshold).

onsetTimeIndex = find(dataSegmentDeviation > STD_THRESHOLD, 1);
onsetTime = timeSegment(onsetTimeIndex);

figure(3); clf;
hold on;

plot(timeSegment, dataSegmentDeviation);
xlabel('Time (s)');
ylabel('STDs from baseline mean');

% draw a horizontal line to indicate the STD threshold
plot(timeSegment([1 end]), [STD_THRESHOLD STD_THRESHOLD], 'r--');

% draw a star at the timepoint where we exceeded threshold
scatter(timeSegment(onsetTimeIndex), dataSegmentDeviation(onsetTimeIndex), 'g*');

legend({'data', 'threshold', 'onset'});

%% things can get more complex from here, but this is a good start...
