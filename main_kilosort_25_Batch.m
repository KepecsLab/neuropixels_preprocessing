%% you need to change most of the paths in this block
%currently all output saves in the last folder in the list of files
%this could be changed to a separate config option!

clear all
close all
clc
%parallel.gpu.enableCUDAForwardCompatibility(true) 

delete_previous_KS_run = false; %WARNING deletes all files in data folder except for Trodes-specific files
addpath(genpath('C:\Users\Adam\Documents\Kilosort-2.5')) % path to kilosort folder
addpath('C:\Users\Adam\Documents\npy-matlab') % for converting to Phy
addpath('C:\Users\Adam\Documents\MATLAB\neuropixels_preprocessing\sortingQuality')

session_dat_folders = {'F:\Neurodata\TQ03\20210616_115352.rec', 'F:\Neurodata\TQ03\20210618_121836.rec' }; % raw binary dat-files to combine (SSD or HHD)
combined_dat_folder = 'I:\Neurodata\TQ03\20210616_20210618'; % output folder for merged binary (SSD or HDD)
ks_output_folder = 'D:\Neurodata\TQ03\20210616_20210618_2'; % saves large temp file and small(er) output files (SSD)

pathToYourConfigFile = 'C:\Users\Adam\Documents\Kilosort-2.5\configFiles'; % take from Github folder and put it somewhere else (together with the master_file)
% chanMapFile = 'neuropixPhase3B1_kilosortChanMapTORBEN.mat';
chanMapFile = 'channelMap.mat';

%make output folders
if ~isfolder(combined_dat_folder),mkdir(combined_dat_folder), end
if ~isfolder(ks_output_folder),mkdir(ks_output_folder), end
   
%combined binary data file
ops.session_dat_folders = session_dat_folders;
ops.combined_dat_folder = combined_dat_folder;
ops.ks_output_folder = ks_output_folder;
%KS ops
ops.trange    = [0 Inf]; % time range to sort
ops.NchanTOT  = 384; % total number of channels in your recording

ops.fbinary = fullfile(combined_dat_folder,'combined2.mat');
%make config file
run(fullfile(pathToYourConfigFile, 'StandardConfig_384Kepecs.m'))

if exist(ops.fbinary,'file')~=2
    ops = concat_dat_files(ops, session_dat_folders,ops.fbinary, false);
    %make combined data file
%else
   % [~,ss] = fileparts(session_dat_folders{1});
  %  ksdatafolder = strcat(ss,'.kilosort');
  %  kfile = strcat(ss,'.probe1.dat');
  %  datafile = fullfile(session_dat_folders{1}, ksdatafolder, kfile);
    
  %  bytes       = get_file_size(datafile); % size in bytes of raw binary
  %  NT       = ops.NT ; % number of timepoints per batch
  %  NchanTOT = ops.NchanTOT; % total number of channels in the raw binary file, including dead, auxiliary etc
 
  %  nTimepoints = floor(bytes/NchanTOT/2); % number of total timepoints
   % ops.tstart  = ceil(ops.trange(1) * ops.fs); % starting timepoint for processing data segment
  %  ops.tend    = min(nTimepoints, ceil(ops.trange(2) * ops.fs)); % ending timepoint
  %  ops.sampsToRead = ops.tend-ops.tstart; % total number of samples to read
  %  ops.midpoint      = ceil(ops.sampsToRead /NT); %number of bacthes in first file
end



%copy one chan map to output folder (assumes all session chan maps are the same)
getChanMap(session_dat_folders{end});
copyfile(fullfile(session_dat_folders{end},'channelMap.mat'),fullfile(ks_output_folder,'channelMap.mat'));

%make a copy of this script for reference
scriptpath = mfilename('fullpath'); scriptpath= [scriptpath,'.m'];
[~,scriptname]=fileparts(scriptpath); scriptname= [scriptname,'.m'];
ff = fullfile(ks_output_folder,scriptname);
ops.main_kilosort_script = ff;
copyfile(scriptpath,ff);


%make config file
%run(fullfile(pathToYourConfigFile, 'StandardConfig_384Kepecs.m'))

%This is the where the concatenated file goes, if we want it on
%the HDD change it here!!
%ops.fproc   = fullfile(rootZ{i}, kfolder, 'temp_wh.dat'); % proc file on a fast SSD
ops.fproc  = fullfile(ks_output_folder, 'temp_wh.dat'); % proc file on a fast SSD

ops.chanMap = fullfile(ks_output_folder, chanMapFile);
%we assume that the same whitenign matrix and same channel map is used for
%all files. 

%% this block runs all the steps of the algorithm

% main parameter changes from Kilosort2 to v2.5
ops.sig        = 30;  % spatial smoothness constant for registration
ops.fshigh     = 300; % high-pass more aggresively
ops.nblocks    = 1; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 

% preprocess data to create temp_wh.dat
% rez = preprocessDataSub(ops);
rez = preprocessDataSub(ops);

%
% NEW STEP TO DO DATA REGISTRATION
rez = datashift2(rez, 1); % last input is for shifting data

% ORDER OF BATCHES IS NOW RANDOM, controlled by random number generator
iseed = 1;
                 
% main tracking and template matching algorithm
rez = learnAndSolve8b(rez, iseed);

% OPTIONAL: remove double-counted spikes - solves issue in which individual spikes are assigned to multiple templates.
% See issue 29: https://github.com/MouseLand/Kilosort/issues/29
%rez = remove_ks2_duplicate_spikes(rez);

% final merges
rez = find_merges(rez, 1);

% final splits by SVD
rez = splitAllClusters(rez, 1);

% decide on cutoff
rez = set_cutoff(rez);

% eliminate widely spread waveforms (likely noise)
rez.good = get_good_units(rez);

fprintf('found %d good units \n', sum(rez.good>0))

%write to Phy 
fprintf('Saving results to Phy  \n')
rezToPhy(rez, ks_output_folder);

%% if you want to save the results to a Matlab file...

% discard features in final rez file (too slow to save)
rez.cProj = [];
rez.cProjPC = [];

% final time sorting of spikes, for apps that use st3 directly
[~, isort]   = sortrows(rez.st3);
rez.st3      = rez.st3(isort, :);

% Ensure all GPU arrays are transferred to CPU side before saving to .mat
rez_fields = fieldnames(rez);
for j = 1:numel(rez_fields)
    field_name = rez_fields{j};
    if(isa(rez.(field_name), 'gpuArray'))
        rez.(field_name) = gather(rez.(field_name));
    end
end

% save index times for spike number in extra mat file (since rez2.mat is
% superlarge & slow) 
spikeTimes = uint64(rez.st3(:,1));
fname = fullfile(ks_output_folder, 'spike_times.mat');
save(fname, 'spikeTimes', '-v7.3');

%save ops
fname = fullfile(ks_output_folder, 'ops.mat');
save(fname, 'ops', '-v7.3');

% save final results as rez2
fprintf('Saving final results in rez2  \n')
fname = fullfile(ks_output_folder, 'rez2.mat');
save(fname, 'rez', '-v7.3');

% compute quality metrics
[cids, uQ, cR, isiV, histC] = sqKilosort.computeAllMeasures(ks_output_folder);

sqKilosort.metricsToPhy(rez, ks_output_folder, cids, uQ, isiV, cR, histC);
%save them for phy

%save KS figures
figHandles = get(0, 'Children');  
saveFigPNG(ks_output_folder,figHandles(end-2:end));
