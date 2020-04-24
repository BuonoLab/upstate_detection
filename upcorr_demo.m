%% Load the recording, define the time between samples, and define a time vector.

load('recording1_good.mat');
data = data';  % transpose for future convenience

dt = 1 ./ samplingRate;  % dt is the time between samples
time = dt:dt:dt*(length(data));  % this time vector will come in handy later!

% Note that I define time value in seconds, not milliseconds.
% This is simply my preference.

%% Find Up and Down transitions

% Detrend data.
vRestRaw = mode(data);  % resting membrane potential
dataDetrended = detrend(data) + vRestRaw;
vRestDetrended = mode(dataDetrended);

BINSIZE_V = .1;  % mV
SEPARATION_V = 7;  % mV
V_THRESH = estimate_threshold(dataDetrended, BINSIZE_V, SEPARATION_V, false);

MIN_UP_DUR = 0.5; % minimum Up state duration in seconds
MIN_DOWN_DUR = 0.1; % minimum Down state duration in seconds

% *** NOTE: I use dataDetrended rather than data ! ***
% V_THRESH = mode(dataDetrended) + 5;
[u_ons, u_off] = find_upstates(dataDetrended, dt, V_THRESH, MIN_UP_DUR, MIN_DOWN_DUR);
n_upstates = length(u_ons);

%% Segment each Up state out of the full recording into a 2D array

% Calculate duration.
u_dur = u_off - u_ons;

% Declare trial limits in seconds.
POS_TRIAL = max(u_dur .* dt);

% Calculate the time array for the trial.
t_trial = dt:dt:POS_TRIAL;
n_samps_per_trial = length(t_trial);

% Initalize a 2D array of NaNs that is nUpstates x nTimePointsInTrial
% Here I initialize two because I'm going to calculate the correlation in
% two different ways.
vOnlyUpstate = nan(n_upstates, n_samps_per_trial);
vUpstateAndAfter = nan(n_upstates, n_samps_per_trial);

% Fill in each 
for ui = 1:n_upstates
    current_dur = min([u_dur(ui) n_samps_per_trial]);
    vOnlyUpstate(ui, 1:current_dur) = dataDetrended(u_ons(ui):u_ons(ui) + current_dur - 1);
    
    % this if statement accounts for the possibility that the final Up state
    % occurs too close to the end of the recording, which would cause an
    % indexing error
    if u_ons(ui) + n_samps_per_trial - 1 > length(dataDetrended)
        vUpstateAndAfter(ui, 1:length(dataDetrended) - u_ons(ui) + 1) = dataDetrended(u_ons(ui):end);
    else
        vUpstateAndAfter(ui, :) = dataDetrended(u_ons(ui):u_ons(ui) + n_samps_per_trial - 1);
    end
end

%% Calculate correlation.

% Because this first array is filled with NaNs outside of the Up state duration,
% the corr function will not be able to calculate the correlation between
% time points beyond the shorter Up state in each pair. This is convenient
% if the goal is to calculate pairwise Up state correlation in which each
% correlation is based on the shorter Up state duration.
rhoShorterDur = corr(vOnlyUpstate', 'rows', 'pairwise');

% If we would like to calculate the correlation between pairs of Up states
% according to the LONGER Up state duration, we will have to do it for each
% pair of Up states separately. This is because for a given Up state (say,
% a medium-length one), when it is being correlated to shorter Up states,
% we will use the full length of its Up state, but when it is being correlated
% to longer Up states, we will additionally contribute the portion of its
% following Down state that overlaps with the duration of longer Up state.
% In other words, for a given Up state, the time series it contributes to
% its correlation with each other Up state will be slightly different.

% So, we have to tell MATLAB to specifically do this. The "corr" function
% cannot figure that out by itself.
upstateCombos = nchoosek(1:n_upstates, 2);

rhoLongerDur = nan(n_upstates, n_upstates);
for upstatePair = upstateCombos'
    firstUpstateInd = upstatePair(1);
    secondUpstateInd = upstatePair(2);
    useDuration = max([u_dur(firstUpstateInd), u_dur(secondUpstateInd)]);
    % Note when correlating two time series with corr, the two inputs
    % should be column vectors.
    currentRho = corr(vUpstateAndAfter(firstUpstateInd, 1:useDuration)', ...
                      vUpstateAndAfter(secondUpstateInd, 1:useDuration)');
    rhoLongerDur(firstUpstateInd, secondUpstateInd) = currentRho;
    rhoLongerDur(secondUpstateInd, firstUpstateInd) = currentRho;
end

% By definition the diagonal 1. This is meaningless as each upstate is
% perfectly correlated with itself. We will change these to NaNs for
% visualization.
rhoShorterDur(rhoShorterDur == 1) = NaN;
rhoLongerDur(rhoLongerDur == 1) = NaN;

%% plot the correlation matrices

figure(1); clf;
subplot(211);
imagesc(rhoShorterDur);
colorbar;
subplot(212);
imagesc(rhoLongerDur);
colorbar;

%% Correlated correlations?
% Are these two methods of calculating pairwise Up state correlation
% correlated with each other?

figure(2); clf;
hold on;
scatter(rhoShorterDur(:), rhoLongerDur(:));
refline(1, 0);
xlabel('Pearson Correlation based on shorter duration');
ylabel('Pearson Correlation based on longer duration');

%% Plot the most correlated pair of Up states
% Based on the shorter duration

rhoShorterDurTril = rhoShorterDur;
rhoShorterDurTril(rhoShorterDurTril == triu(rhoShorterDurTril, 1)) = NaN;

pairwiseCorrSortOrder = nd_argsort(rhoShorterDurTril);
numActualCorrValues = (size(rhoShorterDurTril, 1) .* (size(rhoShorterDurTril, 1) - 1)) / 2;
pairwiseCorrSortOrder(numActualCorrValues + 1:end, :) = [];
pairwiseCorrSortOrder = flipud(pairwiseCorrSortOrder);

usePair = 1;

figure(3); clf;
hold on;
plot(t_trial, vOnlyUpstate(pairwiseCorrSortOrder(usePair, 1), :));
plot(t_trial, vOnlyUpstate(pairwiseCorrSortOrder(usePair, 2), :));
text(0.55, -20, sprintf('corr. = %.3f', ...
    rhoShorterDur(pairwiseCorrSortOrder(usePair, 1), ...
    pairwiseCorrSortOrder(usePair, 2))));
ylabel('mV');
xlabel('Time (s)');
legend(num2str(pairwiseCorrSortOrder(usePair, 1)), num2str(pairwiseCorrSortOrder(usePair, 2)));
