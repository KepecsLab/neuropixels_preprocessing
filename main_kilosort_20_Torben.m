%% you need to change most of the paths in this block

delete_previous_KS_run = true; %WARNING deletes all files in data folder except for Trodes-specific files

addpath(genpath('C:\Users\Adam\Documents\Kilosort-2.0')) % path to kilosort folder
addpath('C:\Users\Adam\Documents\npy-matlab') % for converting to Phy
rootZ = 'D:\Neurodata\TQ01\20201224_165624'; % the raw data binary file is in this folder
% rootH = 'D:\'; % path to temporary binary file (same size as data, should be on fast SSD)
pathToYourConfigFile = 'C:\Users\Adam\Documents\Kilosort-2.0\configFiles'; % take from Github folder and put it somewhere else (together with the master_file)
% chanMapFile = 'neuropixPhase3B1_kilosortChanMapTORBEN.mat';
chanMapFile = 'channelMap.mat';

%make chan map 
getChanMap(rootZ); %spiekgadgets tool

%kilosort subfolder (specific to Trodes kilosort export function)
[~,ss] = fileparts(rootZ);
kfolder = strcat(ss,'.20kilosort');
if ~isfolder(fullfile(rootZ,kfolder)),mkdir(fullfile(rootZ,kfolder)), end

%kilosort subfolder containing Trodes binary data file (Trodes will make a
%subfolder when exporting binary data file for kilosort)
ksdatafolder = strcat(ss,'.kilosort');

%make config struct
if delete_previous_KS_run
   delete_KS_files(fullfile(rootZ,kfolder));
end

%make a copy of this script for reference
scriptpath = mfilename('fullpath'); scriptpath= [scriptpath,'.m'];
[~,scriptname]=fileparts(scriptpath); scriptname= [scriptname,'.m'];
ff = fullfile(rootZ,kfolder,scriptname);
ops.main_kilosort_script = ff;
copyfile(scriptpath,ff);

%KS ops
ops.trange = [0 Inf]; % time range to sort
ops.NchanTOT    = 384; % total number of channels in your recording

run(fullfile(pathToYourConfigFile, 'StandardConfig_384Kepecs.m'))
ops.fproc       = fullfile(rootZ, kfolder, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = fullfile(rootZ, chanMapFile);

%% this block runs all the steps of the algorithm

% find the binary file
kfile = strcat(ss,'.probe1.dat');
ops.fbinary = fullfile(rootZ, ksdatafolder, kfile);

% preprocess data to create temp_wh.dat
rez = preprocessDataSub(ops);

% time-reordering as a function of drift
rez = clusterSingleBatches(rez);

% saving here is a good idea, because the rest can be resumed after loading rez
save(fullfile(rootZ, kfolder, 'rez.mat'), 'rez', '-v7.3');

% main tracking and template matching algorithm
rez = learnAndSolve8b(rez);

% OPTIONAL: remove double-counted spikes - solves issue in which individual spikes are assigned to multiple templates.
% See issue 29: https://github.com/MouseLand/Kilosort2/issues/29
%rez = remove_ks2_duplicate_spikes(rez);

% final merges
rez = find_merges(rez, 1);

% final splits by SVD
rez = splitAllClusters(rez, 1);

% final splits by amplitudes
rez = splitAllClusters(rez, 0);

% decide on cutoff
rez = set_cutoff(rez);

fprintf('found %d good units \n', sum(rez.good>0))

% write to Phy
fprintf('Saving results to Phy  \n')
rezToPhy(rez, fullfile(rootZ,kfolder));

%% if you want to save the results to a Matlab file...

% discard features in final rez file (too slow to save)
rez.cProj = [];
rez.cProjPC = [];

% final time sorting of spikes, for apps that use st3 directly
[~, isort]   = sortrows(rez.st3);
rez.st3      = rez.st3(isort, :);

% Ensure all GPU arrays are transferred to CPU side before saving to .mat
rez_fields = fieldnames(rez);
for i = 1:numel(rez_fields)
    field_name = rez_fields{i};
    if(isa(rez.(field_name), 'gpuArray'))
        rez.(field_name) = gather(rez.(field_name));
    end
end

% save index times for spike number in extra mat file (since rez2.mat is
% superlarge)
spikeTimes = uint64(rez.st3(:,1));
fname = fullfile(rootZ,kfolder, 'spike_times.mat');
save(fname, 'spikeTimes', '-v7.3');

% save final results as rez2
fprintf('Saving final results in rez2  \n')
fname = fullfile(rootZ, kfolder, 'rez2.mat');
save(fname, 'rez', '-v7.3');
