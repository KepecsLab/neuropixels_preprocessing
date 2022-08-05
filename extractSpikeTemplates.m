% extractSpikeTemplates

session = 'Z:\NeuroData\TQ03\20210618_121836\20210618_121836.25kilosort_1blocks_2ndprobe';

%load templates
T = readNPY(fullfile(session,'templates.npy'));


% Phy curing table
PhyLabels = tdfread(fullfile(session,'cluster_info.tsv'));

% get index of good units and save *time* of spies
good_idx = find(all((PhyLabels.group(:,1:4)=='good'),2));
good = PhyLabels.id( good_idx ); %Phy cluster id labelled as 'good'

WF=zeros(length(good_idx),size(T,2));
for k =1:length(good)
    idx = good_idx(k);
    ch = PhyLabels.ch(idx);
    wf = squeeze(T(idx,:,ch));
    WF(k,:)=wf;
end

save(fullfile(session,'CuredClusterTemplate.mat'),'WF');