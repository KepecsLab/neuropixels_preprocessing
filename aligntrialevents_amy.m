clear all;
%dir = 'F:\Neurodata\TQ02\KS_bin\cellbase2425\TrialEvents.mat';
load('./TrialEvents.mat');

completed_trials = ~isnan(Custom.ChoiceLeft);  
trial_starts = TrialStartAligned(completed_trials);
trial_ends = trial_starts + Custom.ResolutionTime(completed_trials);
choice_times = Custom.ResolutionTime(completed_trials) - Custom.FeedbackTime(completed_trials);
choice_correct = Custom.ChoiceCorrect(completed_trials);
was_rewarded = Custom.ChoiceCorrect(completed_trials) | Custom.CatchTrial(completed_trials); 

DV = Custom.DV(completed_trials);

EDGES = trial_starts(1) - 2:.05: trial_ends(end) + 2;
listing = sort(getDir('.', 'file', 'TT')); 
fns = [];

for fn = 1:length(listing)
    TS = load(listing{fn}).TS1;
    
    fns = [fns, listing{fn}];
    
    [N, ~] = histcounts(TS, EDGES);

    TS_trialaligned = {};
    for tn = 1:(length(trial_starts) - 1)
        I = find(EDGES > trial_starts(tn) & EDGES < trial_ends(tn) + 2);
        spike_counts = N(I);
        TS_trialaligned{tn} = spike_counts;
    end
    
    save(strcat(string(fn), 'np'), 'TS_trialaligned');
end

save('rec_behav', 'choice_correct', 'choice_times', 'DV', 'was_rewarded', 'fns');