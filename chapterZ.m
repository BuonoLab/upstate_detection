%%

[u_ons_cema1, u_off_cema1] = find_upstates_ema_crossover5(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, [], []);
[u_ons_cema2, u_off_cema2] = find_upstates_ema_crossover5(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, MIN_UP_DUR, MIN_DOWN_DUR);
%{
dw gets filtered in the following way:
    1) 
%}
[data, dw, dd, hmfast, hmslow] = maudsStatesFestWindow(data, samplingRate, round(EMA_WIDTH_SLOW / dt), round(EMA_WIDTH_FAST / dt));
u_ons_mauds1 = dw(1:end - 1, 2)';
u_off_mauds1 = dw(2:end, 1)';
[u_ons_mauds2, u_off_mauds2] = filter_upstates(u_ons_mauds1, u_off_mauds1, dt, MIN_DOWN_DUR, MIN_UP_DUR);
% u_ons_mauds2 = dd(1:end - 1, 2)';
% u_off_mauds2 = dd(2:end, 1)';
% [u_ons_mauds2, u_off_mauds2] = filter_upstates(u_ons_mauds2, u_off_mauds2, dt, [], .04);

% figure(2); clf;
% plot_upstates(time, data, u_ons_cema, u_off_cema);

figure(3); clf;
u_ons_seq = {u_ons_cema1, u_ons_cema2, u_ons_mauds1, u_ons_mauds2};
u_off_seq = {u_off_cema1, u_off_cema2, u_off_mauds1, u_off_mauds2};
labels = {'CEMA-nofilt', 'CEMA-filt', 'MAUDS-d', 'MAUDS-d-filt'};
plot_upstate_comparison(time, data, u_ons_seq, u_off_seq, labels);
scrollplot_default;

dataSlowEMA1 = movmean_exp(data, round(EMA_WIDTH_SLOW / dt));
dataFastEMA1 = movmean_exp(data, round(EMA_WIDTH_FAST / dt));

figure(3); clf;
p = plot(time, data, 'k');
p.Color(4) = 0.2;
hold on;
plot(time, dataSlowEMA1, 'g');
plot(time, dataFastEMA1, 'r');
scrollplot_default;

%% backwards EMA?

% EMA_SC_SLOW = 5e-6 * 4;  % 2-6
% EMA_SC_FAST = 5e-4 * 4; % .025-.1

dataSlowEMA1f = movmean_exp(data, round(EMA_WIDTH_SLOW / 2 / dt));
dataSlowEMA1r = flipud(movmean_exp(flipud(data), round(EMA_WIDTH_SLOW / 2 / dt)));
dataFastEMA1f = movmean_exp(data, round(EMA_WIDTH_FAST / 2 / dt));
dataFastEMA1r = flipud(movmean_exp(flipud(data), round(EMA_WIDTH_FAST / 2 / dt)));

dataSlowEMA1 = 0.5 * dataSlowEMA1f + 0.5 * dataSlowEMA1r;
dataFastEMA1 = 0.5 * dataFastEMA1f + 0.5 * dataFastEMA1r;

% dataSlowEMA2 = movmean_exp2(data, EMA_SC_SLOW);
% dataFastEMA2 = movmean_exp2(data, EMA_SC_FAST);

figure(3); clf;
p = plot(time, data, 'k');
p.Color(4) = 0.2;
hold on;
% plot(time, dataSlowEMA1f, 'g.');
% plot(time, dataSlowEMA1r, 'g--');
% plot(time, dataFastEMA1f, 'r.');
% plot(time, dataFastEMA1r, 'r--');

plot(time, dataSlowEMA1, 'g');
plot(time, dataFastEMA1, 'r');

scrollplot_default;

% ARROWS_EVERY = 1;
% timeDS = time(1:round(ARROWS_EVERY / dt):end);
% dataDS = dataSlowEMA1(1:round(ARROWS_EVERY / dt):end);
% u = pi ./ 2 * ones(size(dataDS));
% v = 0 * ones(size(dataDS));
% quiver(timeDS', dataDS, u, v, 0.01);

%% Calculating moving standard deviation based on Mann et al. (2009)

MEDIAN_FILTER_WIDTH = 0.02;
STD_WIDTH = 0.4;
DOWNSTATE_PERIOD = [65 95];

dataMedf = medfilt1(dataDetrended, round(MEDIAN_FILTER_WIDTH / dt) + 1, 'truncate');
dataMSTD = movstd(dataMedf, (STD_WIDTH / dt) + 1);
dataDownMSTD = dataMSTD(round(DOWNSTATE_PERIOD(1) / dt):round(DOWNSTATE_PERIOD(2) / dt));
stdDataDownMSTD = std(dataDownMSTD);
meanDataDownMSTD = mean(dataDownMSTD);
deviationDataMSTD = (dataMSTD - meanDataDownMSTD) ./ meanDataDownMSTD;

figure(5); clf;
subplot(211);
plot(time, dataDetrended);
subplot(212);
plot(time, deviationDataMSTD);

%% ???

BINSIZE_STD = 0.02;
SEPARATION_STD = 2;
EXTENSION_THRESH_STD = 0.1;

figure(6); clf;
STD_THRESH = estimate_threshold(deviationDataMSTD, BINSIZE_STD, SEPARATION_STD, true);

[u_ons_std, u_off_std] = find_upstates(deviationDataMSTD, dt, STD_THRESH, MIN_UP_DUR, MIN_DOWN_DUR);
figure(7); clf;
plot_upstates(time, data, u_ons_std, u_off_std);

%% Calculating moving standard deviation based on Mann et al. (2009)

DOWNSTATE_PERIOD = [65 95];

dataDown = dataDetrended(round(DOWNSTATE_PERIOD(1) / dt):round(DOWNSTATE_PERIOD(2) / dt));
stdDataDown = std(dataDown);
meanDataDown = mean(dataDown);
deviationData = (dataDetrended - meanDataDown) ./ stdDataDown;

figure(5); clf;
subplot(211);
plot(time, dataDetrended);
subplot(212);
plot(time, deviationData);

%% Attempting

[data, dw, dd, hmfast, hmslow] = maudsStatesFest(data, samplingRate, 1);
u_ons_mauds = dw(1:end - 1, 2)';
u_off_mauds = dw(2:end, 1)';

%% Introducing crossover of moving averages:

EMA_WIDTH_SLOW = 6;  % 2-6
EMA_WIDTH_FAST = 0.1; % .025-.1

dataDetrendedSlowEMA = movmean_exp(dataDetrended, round(EMA_WIDTH_SLOW / dt));
dataDetrendedFastEMA = movmean_exp(dataDetrended, round(EMA_WIDTH_FAST / dt));

figure(5); clf;
p = plot(time, dataDetrended, 'k');
p.Color(4) = 0.2;
hold on;
plot(time, dataDetrendedFastEMA, 'g');
plot(time, dataDetrendedSlowEMA, 'r');

[u_ons_cema, u_off_cema] = find_upstates_ema_crossover1(data, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, .04, []);
dw_cema = [1 u_off_cema; u_ons_cema length(data)]';
dw_cema_filtered = filterShortStates(dw_cema, .04, samplingRate);
u_ons_cema_filtered = dw_cema_filtered(1:end - 1, 2)';
u_off_cema_filtered = dw_cema_filtered(2:end, 1)';

figure(6); clf;
u_ons_seq = {u_ons, u_ons_cema_filtered, u_ons_mauds};
u_off_seq = {u_off, u_off_cema_filtered, u_off_mauds};
labels = {'vanilla', 'CEMA', 'MAUDS'};
plot_upstate_comparison(time, data, u_ons_seq, u_off_seq, labels);


%% For future steps it may useful to have a version of the raw data in which spikes are removed.

% There are 3 approaches to this:
% 1) Median filtering the data at a moderate width.
% 2) Clipping the data above the spike threshold.
% 3) Detecting spikes, deleting them, and repairing the holes with linear interpolation.

CLIP_THRESH = -40;
dataClipped = data;
dataClipped(dataClipped > CLIP_THRESH) = CLIP_THRESH;

%% use a very slow moving average / median to detrend

SLOW_FILTER_WIDTH = 30;

dataClippedDetrend = detrend(dataClipped);
dataClippedSlowMedf = medfilt1(dataClipped, round(SLOW_FILTER_WIDTH / dt) + 1);
dataClippedSlowEMA = movmean_exp(dataClipped, round(SLOW_FILTER_WIDTH / dt) + 1);

%%

% useAmount = round(length(dataClipped) / 1000);
% (1:useAmount)
opol = 5;
[p, s, mu] = polyfit(time', dataClipped, opol);
dataClippedPolyTrend = polyval(p, time, [], mu)';

%%

figure(42); clf;
% figure; clf;
p = plot(time, dataClipped, 'k');
p.Color(4) = 0.1;
hold on;
plot(time, dataClipped - dataClippedDetrend, 'c');
plot(time, dataClippedSlowMedf, 'r');
plot(time, dataClippedSlowEMA, 'b');
plot(time, dataClippedPolyTrend, 'g');
legend('original', 'linear detrend', 'medf', 'EMA', 'poly detrend');
% legend('original', 'poly detrend');

%% plot various detrendings on top of each other

figure(43); clf;
p = plot(time, dataClipped, 'k');
p.Color(4) = 0.1;
hold on;
p = plot(time, data + dataClippedDetrend - dataClipped + vRestRaw, 'c');
p.Color(4) = 0.1;
p = plot(time, data - dataClippedSlowMedf + vRestRaw, 'r');
p.Color(4) = 0.1;
p = plot(time, data - dataClippedSlowEMA + vRestRaw, 'b');
p.Color(4) = 0.1;
p = plot(time, data - dataClippedPolyTrend + vRestRaw, 'g');
p.Color(4) = 0.1;
legend('original', 'linear detrend', 'medf', 'EMA', 'poly detrend');
hline(vRestRaw, 'k--');

%%

useDataLong = data;
useDataLongClipped = dataClipped;
vRest = mode(useDataLong);

%% create a spike-removed version of the original voltage time-series

% define threshold for spiking
SPIKE_THRESH = -20;
SPIKETHRESH_BACKSET = 0.0015; % 1.2
SPIKETHRESH_FORSET = 0.0055; % 2.2

dataNoSpikes = remove_spikes(useDataLong', dt, SPIKE_THRESH, SPIKETHRESH_BACKSET, SPIKETHRESH_FORSET);

%% determine the voltage threshold
% determine the range by finding the two largest histogram peaks
% that are at least 5 mV away from each other

BINSIZE_V = .1;
SEPARATION_V = 5;

figure(1); clf;
estimated_thresh = estimate_threshold(useDataLongClipped, BINSIZE_V, SEPARATION_V, true);

%% define upstate parameters

V_THRESH = estimated_thresh; % mV
DUR_THRESH = 0.5; % s
EXTENSION_THRESH = 0.1; % s
% EXTENSION_THRESH = 0.05; % s

%% investigate the distribution of durations spent above and below the threshold

[u_ons_inv, u_off_inv] = investigate_crossings(useDataLong', dt, V_THRESH);
[u_ons_inv_pts, u_off_inv_pts] = investigate_crossings_points(useDataLong', V_THRESH);
u_dur_inv = u_off_inv - u_ons_inv;
d_dur_inv = u_ons_inv(2:end) - u_off_inv(1:end - 1);
u_dur_inv2 = u_dur_inv(u_dur_inv > .035);
d_dur_inv2 = d_dur_inv(d_dur_inv > .035);
figure(2); clf;
subplot(211);
% histogram(u_dur_inv2, 0:.005:20);
histogram(u_dur_inv2, 0:.02:20);
xlim([0 8]);
subplot(212);
histogram(d_dur_inv2, 0:.05:20);
xlim([0 8]);

%% find upstates

[u_ons_inv, u_off_inv] = investigate_crossings(useDataLong', dt, V_THRESH);
u_dur_inv = u_off_inv - u_ons_inv;
u_dur_inv2 = u_dur_inv(u_dur_inv > .02);
[u_ons, u_off] = find_upstates(useDataLong', dt, V_THRESH, DUR_THRESH, EXTENSION_THRESH);
n_upstates = length(u_ons);

%% plot upstate periods

figure(7); clf;
subplot(211);
hold on;
plot(time, useDataLong);
% plot(use_vr + up_counter_history / running_dur_thresh * 30);
y1 = -100;
y2 = 100;
subplot(212);
hold on;
for ui = 1:n_upstates
    x1 = time(u_ons(ui));
    x2 = time(u_off(ui));
    subplot(212);
    patch('Vertices', [x1, y1; x2, y1; x2, y2; x1, y2], ...
        'Faces', [1, 2, 3, 4], ...
        'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeAlpha', 0);
    subplot(211);
    line([x1 x2], [-70 -70]);
end
ylim([-80, 20]);

%% plot upstate and downstate duration histograms

u_dur = u_off - u_ons;
d_dur = u_ons(2:end) - u_off(1:end - 1);
upstateDuration = u_dur * dt;
downstateDuration = d_dur .* dt;
shortUpstateEdges = 0.5:.05:2.2;
longUpstateEdges = 0.5:.1:15;
downstateEdges = 0:1:45;

figure(8); clf;
subplot(311);
% histogram(upstateDuration);
histogram(upstateDuration, shortUpstateEdges);
subplot(312);
% histogram(upstateDuration);
histogram(upstateDuration, longUpstateEdges);
subplot(313);
% histogram(downstateDuration);
histogram(downstateDuration, downstateEdges);

megaUpstateInds = upstateDuration > 2.2;

%% try sharpening onset / offset timing with slope

SLOPE_WIDTH = 0.002;
SLOPE_THRESH = 400;  % divide by dt to get true slope value across slope width.. i.e. 200 mV / s or 0.2 mV / ms
BASELINE_DISTANCE = EXTENSION_THRESH / 2;

useLimsInSeconds = [63 66];
useTime = useLimsInSeconds(1):dt:(useLimsInSeconds(2) - dt);
useSegmentNoSpikes = dataNoSpikes(useLimsInSeconds(1) / dt:useLimsInSeconds(2) / dt - 1);

[u_ons_seg, u_off_seg] = find_upstates(useSegmentNoSpikes, dt, V_THRESH, DUR_THRESH, EXTENSION_THRESH);
[u_ons_seg_sharp, u_off_seg_sharp] = sharpen_upstates_slope(useSegmentNoSpikes, dt, u_ons_seg, u_off_seg, ...
    SLOPE_WIDTH, SLOPE_THRESH, BASELINE_DISTANCE);

figure(58); clf;
sp1 = subplot(211);
plot(useTime, useSegmentNoSpikes);
hold on;
scatter(useTime(u_ons_seg), useSegmentNoSpikes(u_ons_seg));
scatter(useTime(u_ons_seg_sharp), useSegmentNoSpikes(u_ons_seg_sharp));

% Dvec1 = 
% Dvec1 = diff([zeros(1, SLOPE_WIDTH) useSegmentNoSpikes], SLOPE_WIDTH);
% Dvec1(1:SLOPE_WIDTH) = Dvec1(SLOPE_WIDTH + 1);
% Dvec2 = gradient(useSegmentNoSpikes);
Dvec3 = movingslope(useSegmentNoSpikes, round(SLOPE_WIDTH / dt) + 1, 1, dt);
sp2 = subplot(212);
% plot(useTime, Dvec1);
% hold on;
% plot(useTime, Dvec2);
plot(useTime, Dvec3);
hold on;
scatter(useTime(u_ons_seg), Dvec3(u_ons_seg));
scatter(useTime(u_ons_seg_sharp), Dvec3(u_ons_seg_sharp));

% legend({'diff', 'movingslope'});
linkaxes([sp1 sp2], 'x');

return

%% investigate the crossover of moving averages idea

% fest = 1;
% EMA_WIDTH_SLOW = max(ceil(10*dt),round((8 - (2/fest)) / dt));
% EMA_WIDTH_FAST = ceil(EMA_WIDTH_SLOW/60);

EMA_WIDTH_SLOW = 2;  % 2, 3, 6
EMA_WIDTH_FAST = 0.03; % 

dataClippedSlowEMA = movmean_exp(dataNoSpikes, round(EMA_WIDTH_SLOW / dt));
dataClippedFastEMA = movmean_exp(dataNoSpikes, round(EMA_WIDTH_FAST / dt));
% dataSlowEMA = movmean_exp(useDataLong, round(EMA_WIDTH_SLOW / dt));
% dataFastEMA = movmean_exp(useDataLong, round(EMA_WIDTH_FAST / dt));

% figure(61); clf;
% plot(time, dataClipped, 'k');
% hold on;
% plot(time, dataClippedSlowEMA, 'g');
% plot(time, dataClippedFastEMA, 'r');

% [u_ons_cema, u_off_cema] = find_upstates_ema_crossover1(useDataLong, dt, ...
%     EMA_WIDTH_SLOW, EMA_WIDTH_FAST);
[u_ons_cema, u_off_cema] = find_upstates_ema_crossover1(dataNoSpikes, dt, ...
    EMA_WIDTH_SLOW, EMA_WIDTH_FAST, DUR_THRESH, EXTENSION_THRESH);
n_upstates_cema = length(u_ons_cema);

%%

[u_ons_sharp, u_off_sharp] = sharpen_upstates_slope(dataNoSpikes, dt, ...
    u_ons, u_off, SLOPE_WIDTH, SLOPE_THRESH, BASELINE_DISTANCE);
[u_ons_cema_sharp, u_off_cema_sharp] = sharpen_upstates_slope(dataNoSpikes, dt, ...
    u_ons_cema, u_off_cema, SLOPE_WIDTH, SLOPE_THRESH, BASELINE_DISTANCE);

%% plot the result
 
figure(61); clf;
u_ons_seq = {u_ons, u_ons_cema};
u_off_seq = {u_off, u_off_cema};
labels = {'vanilla', 'CEMA'};
% u_ons_seq = {u_ons_sharp, u_ons_cema_sharp};
% u_off_seq = {u_off_sharp, u_off_cema_sharp};
% labels = {'vanilla sharp', 'CEMA sharp'};
% u_ons_seq = {u_ons, u_ons_sharp, u_ons_cema, u_ons_cema_sharp};
% u_off_seq = {u_off, u_off_sharp, u_off_cema, u_off_cema_sharp};
% labels = {'vanilla', 'vanilla sharp', 'CEMA', 'CEMA sharp'};
plot_upstate_comparison(time, dataNoSpikes, u_ons_seq, u_off_seq, labels);

%% work on some aggrement index for upstate onsets

u_ons1 = u_ons_cema_sharp;
u_ons2 = u_ons_sharp;

% [u_ons1, u_ons2, mapper] = align_upstates(u_ons1, u_ons2);

%% fuck it, use spike time tiling coefficient (STTC) to assess agreement between onsets

STTC_DT_ONS = .01;
STTC_DT_OFF = .05;

[u_ons, u_off] = find_upstates(dataNoSpikes', dt, V_THRESH, DUR_THRESH, EXTENSION_THRESH);
[u_ons_sharp, u_off_sharp] = sharpen_upstates_slope(dataNoSpikes, dt, ...
    u_ons, u_off, SLOPE_WIDTH, SLOPE_THRESH, BASELINE_DISTANCE);

% searchFastWindow = logspace(0.025, .4, 5)
% searchFastWindow = 0.025 * 2 .^ (0:5);
% searchFastWindow = 0.025 * 2 .^ (0:2);
searchFastWindow = .02:.005:.04;
searchSlowWindow = 1.5:.25:2.5;
% searchSlowWindow = [3 6 12];
saveSTTCOns = zeros(length(searchFastWindow), length(searchSlowWindow));
saveSTTCOff = zeros(length(searchFastWindow), length(searchSlowWindow));

for fastInd = 1:length(searchFastWindow)
for slowInd = 1:length(searchSlowWindow)
    [u_ons_cema, u_off_cema] = find_upstates_ema_crossover1(dataNoSpikes, dt, ...
        searchSlowWindow(slowInd), searchFastWindow(fastInd), DUR_THRESH, EXTENSION_THRESH);
%     [u_ons_cema_sharp, u_off_cema_sharp] = sharpen_upstates_slope(dataNoSpikes, dt, ...
%         u_ons_cema, u_off_cema, SLOPE_WIDTH, SLOPE_THRESH, BASELINE_DISTANCE);
    saveSTTCOns(fastInd, slowInd) = ...
        spike_time_tiling_coefficient(u_ons * dt, u_ons_cema * dt, time(1), time(end), STTC_DT_ONS);    
    saveSTTCOff(fastInd, slowInd) = ...
        spike_time_tiling_coefficient(u_off * dt, u_off_cema * dt, time(1), time(end), STTC_DT_OFF);    
end
end

saveSTTC = (saveSTTCOns + saveSTTCOff) / 2;

%% take a data segment

% useLimsInSeconds = [1 61];
useLimsInSeconds = [61 91];
useSegment = useDataLong(useLimsInSeconds(1) / dt:useLimsInSeconds(2) / dt - 1);
% useSegment = dataMedf2(useLimsInSeconds(1) / dt:useLimsInSeconds(2) / dt - 1);
useTime = time(1:length(useSegment));
% useTime = time(useLimsInSeconds(1) / dt:useLimsInSeconds(2) / dt - 1);

%% quick median filter test

MEDIAN_FILTER_WIDTH = 0.2;
useSegmentMedf = medfilt1(useSegment, ceil(MEDIAN_FILTER_WIDTH/dt) - 1);

figure(3); clf;
subplot(211);
hold on;
plot(useTime, useSegment, useTime, useSegmentMedf);
hline(V_THRESH, 'k--');
subplot(212);
hold on;
plot(useTime, useSegmentMedf);
hline(V_THRESH, 'k--');

%% quick moving STD test

useSegmentMSTD = movstd(useSegment, ceil(MEDIAN_FILTER_WIDTH/dt) - 1);
figure(4); clf;
subplot(211);
plot(useTime, useSegment);
subplot(212);
plot(useTime, useSegmentMSTD);

%% moving STD based on Mann et al. (2009)

dataMedf20 = medfilt1(useDataLong, 0.02 / dt - 1);
dataMSTD400 = movstd(dataMedf20, 0.4 / dt - 1);
useSegmentMedf20 = medfilt1(useSegment, 0.02 / dt - 1);
useSegmentMSTD400 = movstd(useSegmentMedf20, 0.4 / dt - 1);

figure(5); clf;
subplot(211);
plot(useTime, useSegmentMedf20);
subplot(212);
plot(useTime, useSegmentMSTD400);

%% estimate baseline mean and STD voltage using sub-threshold segments

BEFORE_REMOVE = 0.2;
AFTER_REMOVE = 0.2;
STD_THRESH = 5;
STD_THRESH_ONSET = 1;

% first construct the indices
downIndices = [];
for downstateInd = 1:length(u_ons_inv_pts) - 1
    if u_ons_inv_pts(downstateInd + 1) - (AFTER_REMOVE / dt) > u_off_inv_pts(downstateInd) + (BEFORE_REMOVE / dt)
        downIndices = [downIndices, ...
            u_off_inv_pts(downstateInd) + (BEFORE_REMOVE / dt): ...
            (u_ons_inv_pts(downstateInd + 1) - (AFTER_REMOVE / dt))];
    end
end

dataMedf20Down = dataMedf20(downIndices);
figure(55); clf;
plot(dataMedf20Down);

downMean = mean(dataMedf20Down);
downSTD = std(dataMedf20Down);

hold on;
hline(downMean, 'r');
hline(downMean + downSTD * STD_THRESH, 'r--');

%% detect upstates as extended period exceeding the SD threshold

% dataDeviation = (dataMedf20 - downMean) ./ downSTD;
dataDeviation = (dataMedf20 - vRest) ./ downSTD;
useSegmentDeviation = dataDeviation(useLimsInSeconds(1) / dt:useLimsInSeconds(2) / dt - 1);

figure(56); clf;
plot(useTime, useSegmentDeviation);

[u_ons_std, u_off_std] = find_upstates(dataDeviation', dt, STD_THRESH, DUR_THRESH, EXTENSION_THRESH);
% [u_ons_std_sharper, u_off_std_sharper] = find_upstates_sharp(dataDeviation', dt, ...
%     STD_THRESH, STD_THRESH_ONSET, DUR_THRESH, EXTENSION_THRESH);
[u_ons_std_sharpthresh, u_off_std_sharpthresh] = sharpen_upstates_thresh(dataDeviation', ...
    u_ons_std, u_off_std, STD_THRESH_ONSET);
[u_ons_sharpslope, u_off_sharpslope] = sharpen_upstates_slope(dataNoSpikes', ...
    dt, u_ons, u_off, SLOPE_WIDTH, SLOPE_THRESH, BASELINE_DISTANCE);

n_upstates_std = length(u_ons_std);
n_upstates_std_sharpthresh = length(u_ons_std_sharpthresh);
n_upstates_std_sharpslope = length(u_ons_sharpslope);

%% compare upstate timing

figure(57); clf;

sp1 = subplot(211);
hold on;
plot(time, useDataLong);
hold on;
scatter(time(u_ons), useDataLong(u_ons), 'b');
scatter(time(u_off), useDataLong(u_off), 'b');
scatter(time(u_ons_std_sharpthresh), useDataLong(u_ons_std_sharpthresh), 'g');
scatter(time(u_off_std_sharpthresh), useDataLong(u_off_std_sharpthresh), 'g');
scatter(time(u_ons_sharpslope), useDataLong(u_ons_sharpslope), 'r');
scatter(time(u_off_sharpslope), useDataLong(u_off_sharpslope), 'r');
y1a = -100;
y2a = -30;
y1b = -30;
y2b = 30;
y1c = 30;
y2c = 100;
sp2 = subplot(212);
hold on;
for ui = 1:n_upstates_std
    x1 = time(u_ons_std(ui));
    x2 = time(u_off_std(ui));
    subplot(212);
    patch('Vertices', [x1, y1a; x2, y1a; x2, y2a; x1, y2a], ...
        'Faces', [1, 2, 3, 4], ...
        'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeAlpha', 0);
    subplot(211);
    line([x1 x2], [-70 -70]);
end
for ui = 1:n_upstates_std_sharpthresh
    x1 = time(u_ons_std_sharpthresh(ui));
    x2 = time(u_off_std_sharpthresh(ui));
    subplot(212);
    patch('Vertices', [x1, y1b; x2, y1b; x2, y2b; x1, y2b], ...
        'Faces', [1, 2, 3, 4], ...
        'FaceColor', 'green', 'FaceAlpha', 0.2, 'EdgeAlpha', 0);
    subplot(211);
    line([x1 x2], [-69 -69]);
end
for ui = 1:n_upstates_std_sharpslope
    x1 = time(u_ons_sharpslope(ui));
    x2 = time(u_off_sharpslope(ui));
    subplot(212);
    patch('Vertices', [x1, y1c; x2, y1c; x2, y2c; x1, y2c], ...
        'Faces', [1, 2, 3, 4], ...
        'FaceColor', 'red', 'FaceAlpha', 0.2, 'EdgeAlpha', 0);
    subplot(211);
    line([x1 x2], [-68 -68]);
end
ylim([-80, 20]);
linkaxes([sp1 sp2], 'x');

return

%% do that more smartly

figure(50); clf;
u_ons_seq = {u_ons_std, u_ons_std_sharpthresh, u_ons_sharpslope};
u_off_seq = {u_off_std, u_off_std_sharpthresh, u_off_sharpslope};
plot_upstate_comparison(time, useDataLong, u_ons_seq, u_off_seq);

%% median filter (takes long)

% use odd # of points
dataMedf1 = medfilt1(useDataLong, 0.025 / dt - 1);
dataMedf2 = medfilt1(useDataLong, 0.05 / dt - 1);
dataMedf3 = medfilt1(useDataLong, 0.1 / dt - 1);
dataMedf4 = medfilt1(useDataLong, 0.2 / dt - 1);
% dataMedf1(1) = dataMedf1(2);
% dataMedf2(1) = dataMedf2(2);
% dataMedf3(1) = dataMedf3(2);
% dataMedf4(1) = dataMedf4(2);

%% visualize the resulting voltage histograms

if false
figure(51); clf;
subplot(411);
histogram(dataMedf1);
[N_medf1, edges] = histcounts(dataMedf1, LOWER_EDGE:BIN_WIDTH:UPPER_EDGE);
[~, i] = min(N_medf1);
v_thresh_medf1 = binCenters(i);
subplot(412);
histogram(dataMedf2);
[N_medf2, edges] = histcounts(dataMedf2, LOWER_EDGE:BIN_WIDTH:UPPER_EDGE);
[~, i] = min(N_medf2);
v_thresh_medf2 = binCenters(i);
subplot(413);
histogram(dataMedf3);
[N_medf3, edges] = histcounts(dataMedf3, LOWER_EDGE:BIN_WIDTH:UPPER_EDGE);
[~, i] = min(N_medf3);
v_thresh_medf3 = binCenters(i);
subplot(414);
histogram(dataMedf4);
[N_medf4, edges] = histcounts(dataMedf4, LOWER_EDGE:BIN_WIDTH:UPPER_EDGE);
[~, i] = min(N_medf4);
v_thresh_medf4 = binCenters(i);
end

%% visualize the voltage distributions as lines

if false
figure(52); clf;
hold on;
plot(binCenters, N, binCenters, N_medf1, binCenters, N_medf2, binCenters, N_medf3, binCenters, N_medf3);
legend('original', 'med1', 'med2', 'med3', 'med4');
end

%% calculate crossings on the various signals

[u_ons_medf1, u_off_medf1] = investigate_crossings(dataMedf1', dt, V_THRESH);
u_dur_medf1 = u_off_medf1 - u_ons_medf1;
d_dur_medf1 = u_ons_medf1(2:end) - u_off_medf1(1:end - 1);
[u_ons_medf2, u_off_medf2] = investigate_crossings(dataMedf2', dt, V_THRESH);
u_dur_medf2 = u_off_medf2 - u_ons_medf2;
d_dur_medf2 = u_ons_medf2(2:end) - u_off_medf2(1:end - 1);
[u_ons_medf3, u_off_medf3] = investigate_crossings(dataMedf3', dt, V_THRESH);
u_dur_medf3 = u_off_medf3 - u_ons_medf3;
d_dur_medf3 = u_ons_medf3(2:end) - u_off_medf3(1:end - 1);
[u_ons_medf4, u_off_medf4] = investigate_crossings(dataMedf4', dt, V_THRESH);
u_dur_medf4 = u_off_medf4 - u_ons_medf4;
d_dur_medf4 = u_ons_medf4(2:end) - u_off_medf4(1:end - 1);

%% calculate up/down histograms

[N_um, edges] = histcounts(u_dur_inv2, 0:.02:20);
[N_um1, edges] = histcounts(u_dur_medf1, 0:.02:20);
[N_um2, edges] = histcounts(u_dur_medf2, 0:.02:20);
[N_um3, edges] = histcounts(u_dur_medf3, 0:.02:20);
[N_um4, edges] = histcounts(u_dur_medf4, 0:.02:20);
binCentersUp = (edges(1:end - 1) + edges(2:end)) / 2;

[N_dm, edges] = histcounts(d_dur_inv2, 0:.1:20);
[N_dm1, edges] = histcounts(d_dur_medf1, 0:.1:20);
[N_dm2, edges] = histcounts(d_dur_medf2, 0:.1:20);
[N_dm3, edges] = histcounts(d_dur_medf3, 0:.1:20);
[N_dm4, edges] = histcounts(d_dur_medf4, 0:.1:20);
binCentersDown = (edges(1:end - 1) + edges(2:end)) / 2;

%% visualize up/down duration distributions for each

figure(6); clf;
subplot(211);
% plot(binCentersUp, N_um, binCentersUp, N_um1, binCentersUp, N_um2, binCentersUp, N_um3, binCentersUp, N_um4);
plot(binCentersUp, N_um1, binCentersUp, N_um2, binCentersUp, N_um3, binCentersUp, N_um4);
% plot(binCentersUp, N_um1, binCentersUp, N_um2, binCentersUp, N_um3);
legend('med1', 'med2', 'med3', 'med4');
% legend('med1', 'med2', 'med3');
xlim([0 2])
subplot(212);
% plot(binCentersDown, N_dm, binCentersDown, N_dm1, binCentersDown, N_dm2, binCentersDown, N_dm3, binCentersDown, N_dm4);
plot(binCentersDown, N_dm1, binCentersDown, N_dm2, binCentersDown, N_dm3, binCentersDown, N_dm4);
% plot(binCentersDown, N_dm1, binCentersDown, N_dm2, binCentersDown, N_dm3);
legend('med1', 'med2', 'med3', 'med4');
% legend('med1', 'med2', 'med3');
xlim([0 8])
ylim([0 40])

%% i like the 50 ms median filtered version

% idea: divide "upstates" from "events" based on the minimum at 470 ms
% so up periods that last longer than 470 ms are upstates
% and up periods that last less are events

%% reshape data to extract upstates

% trial limits
PRE_TRIAL = -0.4;
POS_TRIAL = 2.1;
SPIKE_THRESH = -20;

t_trial = linspace(PRE_TRIAL, POS_TRIAL, (POS_TRIAL - PRE_TRIAL)/dt+1);
t_trial = t_trial(1:end-1);
n_samps_per_trial = length(t_trial);
pre_trial_pts = sum(t_trial < 0);
t_trial_post = t_trial(t_trial >= 0);

vUpstates = zeros(n_upstates, n_samps_per_trial);
vUpstatesNoSpikes = zeros(n_upstates, n_samps_per_trial);
vUpstatesForCorr = nan(n_upstates, n_samps_per_trial - pre_trial_pts);
upstate_spike_times = cell(n_upstates, 1);
for ui = 1:n_upstates
    vUpstates(ui, :) = useDataLong(u_ons(ui) - pre_trial_pts : u_ons(ui) + n_samps_per_trial - pre_trial_pts - 1);
    vUpstatesNoSpikes(ui, :) = dataNoSpikes(u_ons(ui) - pre_trial_pts : u_ons(ui) + n_samps_per_trial - pre_trial_pts - 1);
    current_dur = min([u_dur(ui) n_samps_per_trial - pre_trial_pts]);
    postStimPart = useDataLong(u_ons(ui):u_ons(ui) + current_dur - 1);
    vUpstatesForCorr(ui, 1:current_dur) = postStimPart;
    currentSpikeTimes = find_spikes2(vUpstates(ui, :), SPIKE_THRESH);
    upstate_spike_times{ui} = t_trial(currentSpikeTimes);
end
upstate_spike_times_ravel = [upstate_spike_times{:}];

%% sort by duration

[~, durationSortOrder] = sort(upstateDuration);
vUpstatesDurSort = vUpstates(durationSortOrder, :);

%% plot that shit

vUpstatesTrialMed = median(vUpstatesNoSpikes, 1);
vUpstatesTrialMean = mean(vUpstatesNoSpikes, 1);
vUpstatesTrialSEM = SEM(vUpstatesNoSpikes, 1);

% KERNEL_START = -.1;
% KERNEL_END = -.03;
KERNEL_START = -.05;
KERNEL_END = 0.001;
[~, kStart] = min(abs(t_trial - KERNEL_START));
[~, kEnd] = min(abs(t_trial - KERNEL_END));

figure(9); clf;
subplot(311);
plot(t_trial, mean(vUpstates, 1));
hold on;
plot(t_trial, vUpstatesTrialMed);
plot(t_trial, vUpstatesTrialMed - vUpstatesTrialSEM, 'k--');
plot(t_trial, vUpstatesTrialMed + vUpstatesTrialSEM, 'k--');
subplot(312);
plot(t_trial, vUpstatesTrialSEM);
subplot(313);
hold on;
plot(t_trial(kStart:kEnd), vUpstatesTrialMed(kStart:kEnd));
plot(t_trial(kStart:kEnd), vUpstatesTrialMed(kStart:kEnd) - vUpstatesTrialSEM(kStart:kEnd), 'k--');
plot(t_trial(kStart:kEnd), vUpstatesTrialMed(kStart:kEnd) + vUpstatesTrialSEM(kStart:kEnd), 'k--');

figure(10); clf;
plot(t_trial, vUpstates');

%% try now to identify upstates by convolving the data
% with a "snapshot" of the average / median upstate onset

uKernel = vUpstatesTrialMed(kStart:kEnd);
convLong = conv(dataNoSpikes, uKernel, 'same');

%% re-plot previous estimates of the upstate onsets / offsets to compare
figure(11); clf;
hold on;
plot(time, normalize_minmax(useDataLong));
% plot(time, normalize_minmax(convLong));
% plot(use_vr + up_counter_history / running_dur_thresh * 30);
y1 = 0;
y2 = 1;
for ui = 1:n_upstates
    x1 = time(u_ons(ui));
    x2 = time(u_off(ui));
    patch('Vertices', [x1, y1; x2, y1; x2, y2; x1, y2], ...
        'Faces', [1, 2, 3, 4], ...
        'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeAlpha', 0);
    line([x1 x2], [-.1 -.1]);
end
% ylim([-80, 20]);


%% correlate all pairs of upstates, baby

% takes a long time
rho = corr(vUpstatesForCorr', 'rows', 'pairwise');

%%
rho(rho == 1) = NaN;

% calculate mean correlation of each upstate to all other upstates
meanPairwiseCorr = nanmean(rho);
[~, meanCorrSortOrder] = sort(meanPairwiseCorr);
vUpstatesCorrSort = vUpstates(meanCorrSortOrder, :);


% return
%% cluster the early part of the upstates using the "clustergram"

% takes a long time
vUpstatesForCorrShort = vUpstatesForCorr(:, 1:5000);
CG = clustergram(vUpstatesForCorrShort');
clusterSortOrder = cell2mat(cellfun(@str2double, CG.ColumnLabels, 'uni', 0));
vUpstatesClusterSort = vUpstates(clusterSortOrder, :);

%% image plot of all upstates sorted by duration

figure(12); clf;
imagesc(t_trial, 1:size(vUpstatesDurSort, 1), vUpstatesDurSort)
% imagesc(t_trial, 1:size(vUpstates, 1), vUpstates)
% imagesc(t_trial, 1:size(vUpstatesCorrSort, 1), vUpstatesCorrSort)
% imagesc(t_trial, 1:size(vUpstatesClusterSort, 1), vUpstatesClusterSort)
% imagesc(t_trial, 1:size(vUpstatesClusterSort2, 1), vUpstatesClusterSort2)
caxis([-65 -47]);

%% remove upper triangular part and plot

rhoTril = rho;
rhoTril(rhoTril == triu(rhoTril, 1)) = NaN;

figure(13); clf;
imagesc_cb(rhoTril);
% imagesc(rhoTril);

%% get a sorted list of all pairs of upstates in order of how correlated they are

pairwiseCorrSortOrder = nd_argsort(rhoTril);
numActualCorrValues = (size(rhoTril, 1) .* (size(rhoTril, 1) - 1)) / 2;
pairwiseCorrSortOrder(numActualCorrValues + 1:end, :) = [];
pairwiseCorrSortOrder = flipud(pairwiseCorrSortOrder);

% corrSortOrderLong = reshape(corrSortOrder.', 1, []);
% corrSortOrderLong = fliplr(remove_redundant_entries(fliplr(corrSortOrderLong)));

%% plot the first several pairs of upstates to see why they were considered to be correlated

PAIR_INDS = 1:15;

figure(14); clf;
pairDummy = 0;
for pairInd = PAIR_INDS
    pairDummy = pairDummy + 1;
    currentUpstateInds = pairwiseCorrSortOrder(pairInd, :);
    subplot(5, 3, pairDummy);
    hold on;
    plot(t_trial, vUpstates(currentUpstateInds(1), :));
    plot(t_trial, vUpstates(currentUpstateInds(2), :));
    hold off;
end

%% pick out some of the best looking pairs of upstates and look at them more closely

bestLookingPairInds = [4 5 8 9 11 15 16];
usePair = 8;

figure(15); clf;
hold on;
plot(t_trial, vUpstates(pairwiseCorrSortOrder(usePair, 1), :));
plot(t_trial, vUpstates(pairwiseCorrSortOrder(usePair, 2), :));
legend(num2str(pairwiseCorrSortOrder(usePair, 1)), num2str(pairwiseCorrSortOrder(usePair, 2)));

%% histogram of spike times in upstates

all_spike_times = find_spikes(useDataLong', SPIKE_THRESH);
n_all_spikes = length(all_spike_times);

figure(16); clf;
histogram(upstate_spike_times_ravel);

%% raster of spike times

LineFormat = struct();
LineFormat.Color = [0 0 0];
LineFormat.LineWidth = 2;

f = figure(17); clf;
currentPlotSpikes = upstate_spike_times(durationSortOrder);
plotSpikeRaster(currentPlotSpikes, 'PlotType', 'vertline', 'LineFormat', LineFormat);
hold on;

% plot timepoint 0 as dashed line
vline(0, 'k--');
% plot the point after which the "mega-upstates" started
hline(n_upstates - sum(megaUpstateInds) + 0.5, 'r');
hold off;

%% do PCA of spike time space
