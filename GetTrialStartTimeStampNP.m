function [NlxEvents] = GetTrialStartTimeStampNP(EventTTL, EventTimestamps)

target= 1; %trialStart (WaitForInitialPoke)
ref_target =0; %no state (between trials)
ref2_target = 2; %state that is always followed by target state

inxx=find(EventTTL==target);

firsttarget = inxx(1);

% Break Nlx events into a cell array by trials
nTrials = 0;
nEvents = 0;
NlxEvents = cell(1,1);
for x = firsttarget:length(EventTTL)-1  %
    if EventTTL(x) == target && (EventTTL(x-1)==ref_target && EventTTL(x+1)==ref2_target) %trialStart(Wait for initial poke)
        % AND preceding event is ref target
        nTrials = nTrials + 1;
        nEvents = 0;
        NlxEvents{1,nTrials} = [];
        NlxEvents{2,nTrials} = [];
    elseif EventTTL(x)==1 %&& EventTTL(x-1)==4
        %CORRECT state 2^5+1=33 - SPECIFIC TO STATE MATRIX!
        EventTTL(x)=33;
    end
    nEvents = nEvents + 1;
    NlxEvents{1,nTrials} = [NlxEvents{1,nTrials} EventTTL(x)];
    NlxEvents{2,nTrials} = [NlxEvents{2,nTrials} EventTimestamps(x)];
end

% size(NlxEvents)

% nT=EventTimestamps(EventTTL==target);
% nT_z=nT-nT(1);
% di=nT_z(2:end)-nT_z(1:end-1);

