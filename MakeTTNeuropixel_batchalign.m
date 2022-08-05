%Make spike time vectors for single unit recordings with Neuropixels and Trodes

%convert KS2.5 clustering results - cured in Phy - to spike times using
%Trode's timestamps

% TO Jan 2021

kdrive = 'D:\Neurodata\';
indrive1 = 'F:\Neurodata\';%'G:\';
indrive2 = 'F:\Neurodata\';

rat = 'TQ03';
session = '20210616_20210618';

session1 = '20210616_115352';
session2 = '20210618_121836';
cellbase = 'cellbase1618';

% load Trodes timestamps
time_file1 = fullfile(indrive1, rat, session1, [session1 '.kilosort'], [session1 '.timestamps.dat']);%F:\TQ02\20210526_154733\20210526_154733.kilosort\20210526_154733.timestamps.dat';
time_file2 = fullfile(indrive2, rat, session2, [session2 '.kilosort'], [session2 '.timestamps.dat']);
%behavior files
behav_file1 = fullfile(indrive1, rat, session1, [session1 '.DIO']);%'F:\TQ02\20210526_154733\20210526_154733.DIO';
behav_file2 = fullfile(indrive2, rat, session2, [session2 '.DIO']);

shank = 1; % for using multiple probe shanks (NOT FULLY IMPLEMENTED!)

sf = 30000.0; %sampling frequency
threshold = .001;% %flag any sampling gaps larger than 1 ms

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Phy's clustering results have to be converted to mat file before
%(cf convert_spikes.py)
PhySpikes = load(fullfile(kdrive,rat,session,'spikes_per_cluster.mat'));

% Phy curing table
PhyLabels = tdfread(fullfile(kdrive,rat,session,'cluster_info.tsv'));

% load KS timestamps (these are indices in reality!) for each spike index
KSspiketimes = load(fullfile(kdrive,rat,session,'spike_times.mat')); 
KSspiketimes = KSspiketimes.spikeTimes;


Ttime = readTrodesExtractedDataFile(time_file1); %>1GB variable for a 3h rec
Trodestimestamps1 = Ttime.fields.data; %>1GB variable for a 3h rec

last_time = max(Trodestimestamps1);

Ttime = readTrodesExtractedDataFile(time_file2); %>1GB variable for a 3h rec
Trodestimestamps2 = Ttime.fields.data; %>1GB variable for a 3h rec

Trodestimestamps = [Trodestimestamps1; Trodestimestamps2 + last_time];

% get index of good units and save *time* of spies
good_idx = find(all((PhyLabels.group(:,1:4)=='good'),2));
good = PhyLabels.id( good_idx ); %Phy cluster id labelled as 'good'
if ~isfolder(fullfile(indrive1,rat,session2,cellbase))
    mkdir(fullfile(indrive1,rat,session1,cellbase));
    mkdir(fullfile(indrive2, rat, session2, cellbase));
end
PhyLabels.cellbase_name = cell(length(PhyLabels.id),1);
for k =1:length(good)
    Sind = PhySpikes.(['f',num2str(good(k))]); %spike index per cluster
    KStime = KSspiketimes(Sind+1); %spike index to time index
    SpikeTimes = Trodestimestamps(KStime + 1); %time index to time in Trodes format (this accounts for potential lost packages/data in Trodes)
    
    
    %separate the spike times into files associated with +
    SpikeTimes1 = SpikeTimes(SpikeTimes <= last_time);
    SpikeTimes2 = SpikeTimes(SpikeTimes > last_time) - last_time;
    
    %actual spike times in seconds
    TS1 = double(SpikeTimes1)/sf; %Trodes saves timestamp as index in sampling frequency
    TS2 = double(SpikeTimes2)/sf;
    
    %save in cellbase format - one mat file per unit (cellbase convention)
    unitname = strcat(num2str(shank),'_',num2str(k)); %cellbase convention: count ntrode/probe and unit within ntrode/probe
    fname = fullfile(indrive1,rat,session1,cellbase,['TT',unitname,'.mat']);
    save(fname,'TS1');
    
    fname = fullfile(indrive2,rat,session2,cellbase,['TT',unitname,'.mat']);
    save(fname,'TS2');

    
    
    PhyLabels.cellbase_name{good_idx(k)} = unitname; %save cellbase name to Phy labels for future provenance
end


gaps1 = double(diff(Trodestimestamps1))/double(sf); %> threshold;
%gaps_ts should be the difference the timestamp where gaps *starts*
gaps_ts1 = double(Trodestimestamps1(gaps1 > threshold)) / double(sf);
gaps1 = gaps1(gaps1 > threshold);
gaps_ts1 = gaps_ts1(gaps1 > threshold);

gaps2 = double(diff(Trodestimestamps2))/double(sf); %> threshold;
%gaps_ts should be the difference the timestamp where gaps *starts*
gaps_ts2 = double(Trodestimestamps2(gaps2 > threshold)) / double(sf);
gaps2 = gaps2(gaps2 > threshold);
gaps_ts2 = gaps_ts2(gaps2 > threshold);

% save cluster quality metrics
fname = fullfile(kdrive, rat, session,'PhyLabels.mat');
save(fname,'PhyLabels');

gaps1_fn = fullfile(indrive1, rat, session1, 'GAPS.mat');
gaps = gaps1;
gaps_ts = gaps_ts1;
save(gaps1_fn, 'gaps', 'gaps_ts')

gaps2_fn = fullfile(indrive2, rat, session2, 'GAPS.mat');
gaps = gaps2;
gaps_ts = gaps_ts2;
save(gaps2_fn, 'gaps', 'gaps_ts')
%also save some info for later in cellbase folder

% save TRODES analog input converted to TTL event
%fname = fullfile(DATAPATH,rat,folder,[session,'.rec']);
%[Events_TTL, Events_TS] = extractTTLs_batch(behav_file1, behav_file2, offset/ double(sf), fname);
[Events_TTL1, Events_TS1] = extractTTLs(behav_file1, gaps1_fn);
save(fullfile(indrive1,rat,session1,cellbase,'EVENTS.mat'),'Events_TS1', 'Events_TTL1');

[Events_TTL2, Events_TS2] = extractTTLs(behav_file2, gaps2_fn);
save(fullfile(indrive2,rat,session2,cellbase,'EVENTS.mat'),'Events_TS2', 'Events_TTL2');
