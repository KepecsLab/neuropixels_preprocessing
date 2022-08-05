session0path = 'TQ02_Dual2AFC_May21_2021_Session1.mat';
session1path = 'TQ02_Dual2AFC_May21_2021_Session2.mat';

session0 = load(session0path);
session1 = load(session1path);

session0 = session0.SessionData;
session1 = session1.SessionData;

fnm = {'nTrials', 'RawEvents', 'RawData', 'TrialStartTimestamp'};
SessionData = struct([]);

for k = 1:length(fnm)
   SessionData(1).(fnm{k}) = [session0.(fnm{k}) session1.(fnm{k})]; 
end

fnm = fieldnames(session0.Custom);
for k = 1:length(fnm)
    try
       SessionData.Custom.(fnm{k}) = [session0.Custom.(fnm{k}) session1.Custom.(fnm{k})];
    catch
       fprintf(['missing field ' fnm{k} ' \n'])
    end
end

fnm = fieldnames(session0.Settings);
for k = 1:length(fnm)
    try
       SessionData.Settings.(fnm{k}) = [session0.Settings.(fnm{k}) session1.Settings.(fnm{k})];
    catch
       fprintf(['missing field ' fnm{k} ' \n'])
    end
end

fnm = fieldnames(session0.TrialSettings);
for k = 1:length(fnm)
    try
       SessionData.TrialSettings.(fnm{k}) = [session0.TrialSettings.(fnm{k}) session1.TrialSettings.(fnm{k})];
    catch
       fprintf(['missing field ' fnm{k} ' \n'])
    end
end

save('.\Dual2AFC12', 'SessionData');
