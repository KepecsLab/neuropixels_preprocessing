%load('E:\Data\Session-20210608_SCR16_test2\SCR16_Dual2AFC_Jun08_2021_Session1');
%save_name = 'E:\Data\Session-20210608_SCR16_test2\behavmat';
function extract_behavior(behav_file, save_name, opto)
    SessionData = load(behav_file);%.SessionData;
    SessionData = SessionData.SessionData;
    states = SessionData.RawData.OriginalStateData;
    named_states = SessionData.RawData.OriginalStateNamesByNumber;
    choice = SessionData.Custom.ChoiceLeft;
    correct = SessionData.Custom.ChoiceCorrect;
    rewarded = SessionData.Custom.Rewarded;
    wait_time = SessionData.Custom.FeedbackTime;
    DV = SessionData.Custom.DV;
    catch_trials = SessionData.Custom.CatchTrial;
    
    if opto
        opto_trial = SessionData.Custom.LaserTrial;
        save(save_name, 'choice', 'correct', 'DV', 'named_states', 'states', 'wait_time', 'catch_trials', 'opto_trial');
    else
        save(save_name, 'choice', 'correct', 'DV', 'named_states', 'states', 'wait_time', 'catch_trials');
    end
end