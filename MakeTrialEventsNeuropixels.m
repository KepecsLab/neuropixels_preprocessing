function MakeTrialEventsNeuropixels(Directory)

%% Load the behavioral file; % Uses a string that is specific to the behaviour file name (depends on task)
disp('Loading behavior file');
cd(Directory)
BehaviorFiles = getDir(Directory,'file','Dual2AFC');

[~,FileIdx] = max(cellfun(@(x) str2num(x(end-4)),BehaviorFiles));
BehaviorFileName = BehaviorFiles{FileIdx};

load(BehaviorFileName);
TEbis=SessionData;
TE=SessionData;

save(fullfile(Directory,'TE.mat'),'TE');

%% Make the trial events

disp('Aligning to Trodes events')

try
    MakeTrialEvents2_TorbenNP(Directory)
catch ME
    BehaviorFileName2 = BehaviorFiles{max([1,FileIdx-1])};
    fprintf('Warning: TTL alignment failed for %s. Trying %s...\n',BehaviorFileName,BehaviorFileName2);
    
    load(BehaviorFileName2);
    TEbis=SessionData;
    TE=SessionData;
    save(fullfile(Directory,'TE.mat'),'TE');
    MakeTrialEvents2_TorbenNP(Directory)
    
end

%% Create additional fields in the Trial Event structure
disp('Creating additional fields in the Trial Event structure')

TEbis=load(fullfile(Directory,'TrialEvents.mat'));
TE=TEbis;

WT_low_threshold=0; % Lower cut off for waiting time turning all to NaN

%nTrial
nTrials = TE.nTrials-1;
TEbis.nTrials=nTrials;
TEbis.TrialNumber = 1:nTrials;
%discrimination measures
%TEbis.OmegaDiscri=2*abs(TE.Custom.AuditoryOmega(1:nTrials)-0.5);
%TEbis.NRightClicks = cellfun(@length,TE.Custom.RightClickTrain(1:nTrials));
%TEbis.NLeftClicks = cellfun(@length,TE.Custom.LeftClickTrain(1:nTrials));
%TEbis.RatioDiscri=log10(TEbis.NRightClicks./TEbis.NLeftClicks);
%TEbis.BetaDiscri=(TEbis.NRightClicks-TEbis.NLeftClicks)./(TEbis.NRightClicks+TEbis.NLeftClicks);
%TEbis.AbsBetaDiscri=abs(TEbis.BetaDiscri);
%TEbis.AbsRatioDiscri=abs(TEbis.RatioDiscri);
%chosen direction
TEbis.ChosenDirection = 3*ones(1,nTrials);
TEbis.ChosenDirection(TE.Custom.ChoiceLeft==1)=1;%1=left; 2=right
TEbis.ChosenDirection(TE.Custom.ChoiceLeft==0)=2;
% Correct and error trials
TEbis.CorrectChoice=TE.Custom.ChoiceCorrect(1:nTrials);
TEbis.PunishedTrial=TE.Custom.ChoiceCorrect(1:nTrials)==0;
%most click side
%TEbis.MostClickSide(TEbis.NRightClicks>TEbis.NLeftClicks) = 2;
%TEbis.MostClickSide(TEbis.NRightClicks<TEbis.NLeftClicks) = 1;
%TEbis.MostClickSide(TEbis.NRightClicks==TEbis.NLeftClicks)  = 3;
% Trial where rat gave a response
TEbis.CompletedTrial= ~isnan(TE.Custom.ChoiceLeft(1:nTrials)) & TEbis.TrialNumber>30;
% Rewarded Trials
TEbis.Rewarded=TE.Custom.Rewarded(1:nTrials)==1;
% Trials where rat sampled but did not respond
TEbis.UnansweredTrials=(TEbis.CompletedTrial(1:nTrials)==0 & TE.Custom.EarlyWithdrawal(1:nTrials)==1);
%CatchTrial
TEbis.CatchTrial = TE.Custom.CatchTrial(1:nTrials);
% Correct catch trials
TEbis.CompletedCatchTrial=TEbis.CompletedTrial(1:nTrials)==1 & TE.Custom.CatchTrial(1:nTrials)==1 ;
% Correct trials, but rat was waiting too short
TEbis.CorrectShortWTTrial=TE.Custom.ChoiceCorrect(1:nTrials)==1 & TE.Custom.FeedbackTime(1:nTrials)<0.5;
% These are all the waiting time trials (correct catch and incorrect trials)
TEbis.CompletedWTTrial= (TEbis.CompletedCatchTrial(1:nTrials)==1 | TEbis.PunishedTrial(1:nTrials)==1) & TEbis.CompletedTrial(1:nTrials);

% Trials were rat answered but did not receive reward
WTTrial=TEbis.CompletedTrial(1:nTrials)==1 & (TEbis.PunishedTrial(1:nTrials)==1 | TE.Custom.CatchTrial(1:nTrials)==1);

TEbis.WaitingTimeTrial=WTTrial;

% Waiting Time
TEbis.WaitingTime=TE.Custom.FeedbackTime;

% Threshold for waiting time
TEbis.WaitingTime(TEbis.WaitingTime<WT_low_threshold)=NaN;

% This is to indicate whether choice matches actual click train (important for difficult trials)
%TEbis.ChoiceGivenClick=TEbis.MostClickSide==TEbis.ChosenDirection;
%modality
TEbis.Modality = 2*ones(1,nTrials);
%% Conditioning the trials
for nt=1:nTrials
    
    % Defining trial types
    % Defining DecisionType
    % 0 = Non-completed trials
    % 1 = Correct given click and not rewarded (catch trials consisting
    % of real catch trials and trials that are statistically incorrect but correct
    % given click, later ones are most likely 50/50 trials)
    % 2 = Correct given click and rewarded
    % 3 = Incorrect given click and not rewarded
 %   if TEbis.CompletedTrial(nt)==0
 %       TEbis.DecisionType(nt)=NaN;
 %   elseif (TEbis.CompletedCatchTrial(nt)==1 || (TEbis.Rewarded(nt)==0 && TEbis.CompletedTrial(nt)==1)) && TEbis.ChoiceGivenClick(nt)==1
 %       TEbis.DecisionType(nt)=1;
 %   elseif TEbis.Rewarded(nt)==1
 %       TEbis.DecisionType(nt)=2;
 %   elseif (TEbis.CompletedCatchTrial(nt)==1 || (TEbis.Rewarded(nt)==0 && TEbis.CompletedTrial(nt)==1)) && TEbis.ChoiceGivenClick(nt)==0
 %       TEbis.DecisionType(nt)=3;
 %   end
    
    if TEbis.Rewarded(nt)==1 && TEbis.Modality(nt)==1
        TEbis.SideReward(nt)=1;
    elseif TEbis.Rewarded(nt)==1  && TEbis.Modality(nt)==2
        TEbis.SideReward(nt)=2;
    elseif TEbis.Rewarded(nt)==0 && TEbis.CompletedTrial(nt)==1  && TEbis.Modality(nt)==1
        TEbis.SideReward(nt)=3;
    elseif TEbis.Rewarded(nt)==0 && TEbis.CompletedTrial(nt)==1  && TEbis.Modality(nt)==2
        TEbis.SideReward(nt)=4;
    else
        TEbis.SideReward(nt)=NaN;
    end
    
    % Defining ChosenDirection
    % 1 = Left
    % 2 = Right
    if TEbis.CompletedTrial(nt)==1 && TEbis.ChosenDirection(nt)==1
        TEbis.CompletedChosenDirection(nt)=1;
    elseif TEbis.CompletedTrial(nt)==1 && TEbis.ChosenDirection(nt)==2
        TEbis.CompletedChosenDirection(nt)=2;
    end
    
    % Defining SideDecisionType
    % 1 = Left catch trials
    % 2 = Right catch trials
    % 3 = Left correct trials
    % 4 = Right correct trials
    % 5 = Incorrect left trials
    % 6 = Incorrect right trials
    % 7 = all remaining trials
%    if TEbis.DecisionType(nt)==1 && TEbis.ChosenDirection(nt)==1
%        TEbis.SideDecisionType(nt)=1;
%    elseif TEbis.DecisionType(nt)==1 && TEbis.ChosenDirection(nt)==2
%        TEbis.SideDecisionType(nt)=2;
%    elseif TEbis.DecisionType(nt)==2 && TEbis.ChosenDirection(nt)==1
%        TEbis.SideDecisionType(nt)=3;
%    elseif TEbis.DecisionType(nt)==2 && TEbis.ChosenDirection(nt)==2
%        TEbis.SideDecisionType(nt)=4;
%    elseif TEbis.DecisionType(nt)==3 && TEbis.ChosenDirection(nt)==1
%        TEbis.SideDecisionType(nt)=5;
%    elseif TEbis.DecisionType(nt)==3 && TEbis.ChosenDirection(nt)==2
%        TEbis.SideDecisionType(nt)=6;
%    else
%        TEbis.SideDecisionType(nt)=7;
%    end
    
    if TEbis.Modality(nt)==1 && TEbis.ChosenDirection(nt)==1 && TEbis.CompletedTrial(nt)==1
        TEbis.ModReward(nt)=1;
    elseif TEbis.Modality(nt)==2 && TEbis.ChosenDirection(nt)==1 && TEbis.CompletedTrial(nt)==1
        TEbis.ModReward(nt)=2;
    elseif TEbis.Modality(nt)==1 && TEbis.ChosenDirection(nt)==2 && TEbis.CompletedTrial(nt)==1
        TEbis.ModReward(nt)=3;
    elseif TEbis.Modality(nt)==2 && TEbis.ChosenDirection(nt)==2 && TEbis.CompletedTrial(nt)==1
        TEbis.ModReward(nt)=4;
    else
        TEbis.ModReward(nt)=NaN;
    end
    
end

%waiting time split
TEbis.WaitingTimeSplit=NaN(size(TEbis.ChosenDirection));

Long=TEbis.CompletedTrial==1 & TEbis.Rewarded==0 & TEbis.WaitingTime>=6.5;
MidLong=TEbis.CompletedTrial==1 & TEbis.Rewarded==0 & TEbis.WaitingTime<6.5 & TEbis.WaitingTime>=5.5 ;
MidShort=TEbis.CompletedTrial==1 & TEbis.Rewarded==0 & TEbis.WaitingTime<5.5 & TEbis.WaitingTime>=4;
Short=TEbis.CompletedTrial==1 & TEbis.Rewarded==0 & TEbis.WaitingTime<4 & TEbis.WaitingTime>=2.5;

TEbis.WaitingTimeSplit(Short)=1;
TEbis.WaitingTimeSplit(MidShort)=2;
TEbis.WaitingTimeSplit(MidLong)=3;
TEbis.WaitingTimeSplit(Long)=4;


%% Saving conditioned trials
save(fullfile(Directory,'TEbis.mat'),'TEbis')
save(fullfile(Directory,  'TrialEvents.mat'),'-struct','TEbis')


%% Defining ResponseOnset, ResponseStart and ResponseEnd
TEbis.ResponseStart=zeros(1,TEbis.nTrials);
TEbis.ResponseEnd=zeros(1,TEbis.nTrials);
TEbis.PokeCenterStart=zeros(1,TEbis.nTrials);
TEbis.StimulusOnset=zeros(1,TEbis.nTrials);
 TEbis.LaserTrialTrainLength=zeros(1,TEbis.nTrials);

for nt=1:TEbis.nTrials
    TEbis.StimulusOnset(nt)=TE.RawEvents.Trial{nt}.States.stimulus_delivery_min(1);
    TEbis.PokeCenterStart(nt)=TE.RawEvents.Trial{nt}.States.stay_Cin(1);
    if ~isnan(TE.RawEvents.Trial{nt}.States.start_Rin(1))
        TEbis.ResponseStart(nt)=TE.RawEvents.Trial{nt}.States.start_Rin(1);
        TEbis.ResponseEnd(nt)=TE.RawEvents.Trial{nt}.States.start_Rin(1) + TE.Custom.FeedbackTime(nt);
    elseif ~isnan(TE.RawEvents.Trial{nt}.States.start_Lin(1))
        TEbis.ResponseStart(nt)=TE.RawEvents.Trial{nt}.States.start_Lin(1);
        TEbis.ResponseEnd(nt)=TE.RawEvents.Trial{nt}.States.start_Lin(1) + TE.Custom.FeedbackTime(nt);
        %     elseif ~isnan(TE.RawEvents.Trial{nt}.States.PunishStart(1)) && isnan(TE.RawEvents.Trial{nt}.States.StillWaiting(end))
        %         TEbis.ResponseStart(nt)=TE.RawEvents.Trial{nt}.States.PunishStart(1);
        %         TEbis.ResponseEnd(nt)=(TE.RawEvents.Trial{nt}.States.Punish(end));
        %     elseif ~isnan(TE.RawEvents.Trial{nt}.States.PunishStart(1))
        %         TEbis.ResponseStart(nt)=TE.RawEvents.Trial{nt}.States.PunishStart(1);
        %         TEbis.ResponseEnd(nt)=(TE.RawEvents.Trial{nt}.States.StillWaiting(end));
    else
        TEbis.ResponseStart(nt)=NaN;
        TEbis.ResponseEnd(nt)=NaN;
    end
    if isfield(TE.TrialSettings(nt).GUI,'LaserTrials')
    if TE.TrialSettings(nt).GUI.LaserTrials>0
        if isfield(TE.TrialSettings(nt).GUI,'LaserTrainDuration_ms')
            TEbis.LaserTrialTrainLength(nt) = TE.TrialSettings(nt).GUI.LaserTrainDuration_ms;
        else %old version
            TEbis.LaserTrialTrainLength(nt)=NaN ;
        end
    end
    else %not even Laser Trials settings, very old version
        TEbis.LaserTrialTrainLength(nt)=NaN;
    end
end
TEbis.SamplingDuration = TE.Custom.ST(1:nTrials);
TEbis.StimulusOffset=TEbis.StimulusOnset+TEbis.SamplingDuration;

TEbis.ChosenDirectionBis=TEbis.ChosenDirection;
TEbis.ChosenDirectionBis(TEbis.ChosenDirectionBis==3)=NaN;

%correct length of TrialStartAligned
TEbis.TrialStartAligned = TEbis.TrialStartAligned(1:TEbis.nTrials);
TEbis.TrialStartTimestamp = TEbis.TrialStartTimestamp(1:TEbis.nTrials);
TEbis.TrialSettings = TEbis.TrialSettings(1:TEbis.nTrials);

%laser trials
if  isfield(TE.Custom,'LaserTrial') && sum(TE.Custom.LaserTrial)>0
if isfield (TE.Custom,'LaserTrialTrainStart')
TEbis.LaserTrialTrainStart = TE.Custom.LaserTrialTrainStart(1:TEbis.nTrials);
TEbis.LaserTrialTrainStartAbs = TEbis.LaserTrialTrainStart+TEbis.ResponseStart;
TEbis.LaserTrial =double( TE.Custom.LaserTrial(1:TEbis.nTrials));
TEbis.LaserTrial (TEbis.CompletedTrial==0)=0;
TEbis.LaserTrial (TEbis.LaserTrialTrainStartAbs>TEbis.ResponseEnd)=0;
TEbis.LaserTrialTrainStartAbs(TEbis.LaserTrial~=1)=NaN;
TEbis.LaserTrialTrainStart (TEbis.LaserTrial~=1)=NaN;

TEbis.CompletedWTLaserTrial = TEbis.LaserTrial;
TEbis.CompletedWTLaserTrial(TEbis.CompletedWTTrial~=1)=NaN;
else %old version, laser during entire time investment
TEbis.LaserTrialTrainStart=zeros(1,TEbis.nTrials);
TEbis.LaserTrialTrainStartAbs=TEbis.ResponseStart;
TEbis.LaserTrial =double( TE.Custom.LaserTrial(1:TEbis.nTrials));
TEbis.LaserTrial (TEbis.CompletedTrial==0)=0;
TEbis.LaserTrialTrainStartAbs(TEbis.LaserTrial~=1)=NaN;
TEbis.LaserTrialTrainStart (TEbis.LaserTrial~=1)=NaN;
end

else
TEbis.LaserTrialTrainStart = nan(1,TEbis.nTrials);
TEbis.LaserTrialTrainStartAbs = nan(1,TEbis.nTrials);
TEbis.LaserTrial = zeros(1,TEbis.nTrials);
TEbis.CompletedWTLaserTrial = nan(1,TEbis.nTrials);
TEbis.CompletedWTLaserTrial(TEbis.CompletedWTTrial==1) = 0;
end


save(fullfile(Directory,'TEbis.mat'),'TEbis')
save(fullfile(Directory,  'TrialEvents.mat'),'-struct','TEbis')

disp('Additional events created and Trial Event saved')