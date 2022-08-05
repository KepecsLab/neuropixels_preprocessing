%Make spike time vectors for single unit recordings with Neuropixels and Trodes

%convert KS2.5 clustering results - cured in Phy - to spike times using
%Trode's timestamps

% TO Jan-Dec 2021

DATAPATH = 'D:\Neurodata';
rat = 'TQ02';
folder = '20210417_154058';
session = '20210417_154058';
kfolder = ['.kilosort'];
shank = str2double(kfolder(end)); % for using multiple probe shanks (NOT AUTOMATICALLY IMPLEMENTED!)

sf = 30000.0; %sampling frequency
threshold = .001;% %flag any sampling gaps larger than 1 ms

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%file pointer to raw/filtered data for waveform extraction
%this requires some parameters that might change!
nChInFile = 384; %only works if file and KS channel map has 384 channels, otherwise need to change a few thigns here
dataType = 'int16'; %data type of raw data file
BytesPerSample = 2; %
rawfilename = fullfile(DATAPATH,rat,folder,[session kfolder],'temp_wh.dat');
TotalBytes = get_file_size(rawfilename);
nSamp = TotalBytes/nChInFile/BytesPerSample;
mmf = memmapfile(rawfilename, 'Format', {dataType, [nChInFile, nSamp], 'x'});

% Phy's clustering results have to be converted to mat file before
%(cf convert_spikes.py)
PhySpikes = load(fullfile(DATAPATH,rat,folder,[session kfolder],'spikes_per_cluster.mat'));

%KS cluster id per spike
SpikeCluster = readNPY(fullfile(DATAPATH,rat,folder,[session kfolder],'spike_clusters.npy'));

% Phy curing table
PhyLabels = tdfread(fullfile(DATAPATH,rat,folder,[session kfolder],'cluster_info.tsv'));

% load KS timestamps (these are indices in reality!) for each spike index
KSspiketimes = load(fullfile(DATAPATH,rat,folder,[session kfolder],'spike_times.mat')); 
KSspiketimes = KSspiketimes.spikeTimes;

% load Trodes timestamps
time_file = fullfile(DATAPATH,rat,folder,[session,'.kilosort'],[session,'.timestamps.dat']);
Ttime = readTrodesExtractedDataFile(time_file); %>1GB variable for a 3h rec
Trodestimestamps = Ttime.fields.data; %>1GB variable for a 3h rec

% get index of good units and save *time* of spies
good_idx = find(all((PhyLabels.group(:,1:4)=='good'),2));
good = PhyLabels.id( good_idx ); %Phy cluster id labelled as 'good'
if ~isfolder(fullfile(DATAPATH,rat,folder,[session kfolder],'cellbase'))
    mkdir(fullfile(DATAPATH,rat,folder, [session kfolder],'cellbase'))
end
PhyLabels.cellbase_name = cell(length(PhyLabels.id),1);


for k =1:length(good)
    clu = good(k);
    Sind = PhySpikes.(['f',num2str(clu)]); %spike index per cluster
    KStime = KSspiketimes(Sind+1); %spike index to time index
    SpikeTimes = Trodestimestamps(KStime+1); %time index to time in Trodes format (this accounts for potential lost packages/data in Trodes)
    
    %actual spike times in seconds
    TS = double(SpikeTimes)/sf; %Trodes saves timestamp as index in sampling frequency
    
    %save in cellbase format - one mat file per unit (cellbase convention)
    unitname = strcat(num2str(shank),'_',num2str(k)); %cellbase convention: count ntrode/probe and unit within ntrode/probe
    fname = fullfile(DATAPATH,rat,folder,[session,kfolder],'cellbase',['TT',unitname,'.mat']);
    save(fname,'TS');
    
    PhyLabels.cellbase_name{good_idx(k)} = unitname; %save cellbase name to Phy labels for future provenance
    
    %extrace spike waveforms
    theseST = KSspiketimes(SpikeCluster==clu)+1; % spike times for specific cluster
    extractST = theseST(10:min(110,length(theseST))); %extract at most the first 100 spikes
    nWFsToLoad = length(extractST);
    wfWin = [-20:40]; % samples around the spike times to load
    nWFsamps = length(wfWin);
    theseWF = zeros(nWFsToLoad, nChInFile, nWFsamps);
    for i=1:nWFsToLoad
        tempWF = mmf.Data.x(1:nChInFile,extractST(i)+wfWin(1):extractST(i)+wfWin(end));
        theseWF(i,:,:) = tempWF;
    end
    %average spikes
    WFm=squeeze(mean(theseWF,1));
    %find maximum channel
    [~,midx]=max(max(WFm,[],2));
    WF=WFm(midx,:);
    fname = fullfile(DATAPATH,rat,folder,[session,kfolder],'cellbase',['WF',unitname,'.mat']);
    save(fname,'WF');    
end


gaps = double(diff(Trodestimestamps))/double(sf); %> threshold;
%gaps_ts should be the difference the timestamp where gaps *starts*
gaps_ts = double(Trodestimestamps(gaps > threshold)) / double(sf);
gaps = gaps(gaps > threshold);
gaps_ts = gaps_ts(gaps >threshold);

fname_gaps = fullfile(DATAPATH, rat, folder, [session, kfolder],'cellbase', 'GAPS.mat');
save(fname_gaps, 'gaps', 'gaps_ts')
%also save some info for later in cellbase folder

% save cluster quality metrics
fname = fullfile(DATAPATH,rat, folder,[session, kfolder],'cellbase',['PhyLabels_',num2str(shank),'.mat']);
save(fname,'PhyLabels');

% save TRODES analog input converted to TTL event
fname = fullfile(DATAPATH,rat,folder,[session,kfolder]);
[Events_TTL, Events_TS] = extractTTLs(fname,fname_gaps);
save(fullfile(DATAPATH,rat,folder ,[session, kfolder],'cellbase','EVENTS.mat'),'Events_TS', 'Events_TTL');

