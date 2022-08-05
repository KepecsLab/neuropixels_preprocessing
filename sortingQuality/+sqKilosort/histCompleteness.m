function histC = histCompleteness(resultsDirectory)
%estimates "histogram completeness" of the histogram of spike amplitudes in
%each cluster.
%histC is a number between 0.5 and 1, 1=histogram complete, 0.5=50% of
%spikes "missing"
%assumes a unimodal distribution of amplitudes.
%finds the tail of the histogram and estimates the percentage of "cutoff",
%i.e. missing, spikes based on the histogram's falloff. 
%Will fail for small number of spikes (less than a few hundred) or, more
%generally, when histogram cannot be well estimated.
%TO 2021

AmplitudesPath = fullfile(resultsDirectory,'amplitudes.npy');
spikeClustersPath = fullfile(resultsDirectory,'spike_clusters.npy');

%load cluster list
spike_clusters = readNPY(spikeClustersPath);
spike_clusters = spike_clusters + 1; % because in Python indexes start at 0
clusterIDs = unique(spike_clusters);
nClusters = length(clusterIDs);

histC = nan(nClusters,1);

%load amplitudes

amplitudes = readNPY(AmplitudesPath);

for i = 1:nClusters
    
    amps = amplitudes(spike_clusters == clusterIDs(i));
    
    %calculate histogram completeness of amplitudes for this clusters
    try
        comp = calculate_completeness(amps);
    catch
        fprintf('Calculate completeness failed for cluster %i\n',clusterIDs(i));
        comp = NaN;
    end
    
    histC(i)=comp;
    
end


function comp = calculate_completeness(x)
AvgBin=3; %free param!
NBin = (max(x)-min(x)) ./ (2*diff(quantile(x,[0.25,0.75]))/nthroot(length(x),3)) ; %Freedman Diaconis' rule



%method for estimating percentage of missing data
if NBin <= 2*AvgBin || isnan(NBin)
    Missing = NaN;
else
    edges = linspace(min(x),max(x),round(NBin)+1);
    hi = histogram(x,edges);
    hi=hi.Values;
    
    N_L = mean(hi(1:AvgBin));
    N_R = mean(hi(end-AvgBin+1:end));
    Tail_R_idx  = find(hi>N_L,1,'last');
    if Tail_R_idx < length(hi)
        Tail_L_missing = sum(hi(Tail_R_idx:end))/(sum(hi)+sum(hi(Tail_R_idx:end)));
    else
        Tail_L_missing=0;
    end
    Tail_L_idx  = find(hi>N_R,1,'first');
    if Tail_L_idx > 1
        Tail_R_missing = sum(hi(1:Tail_L_idx))/(sum(hi)+sum(hi(1:Tail_L_idx)));
    else
        Tail_R_missing=0;
    end
    Missing = sum([Tail_L_missing,Tail_R_missing]);
end

comp = 1-Missing;