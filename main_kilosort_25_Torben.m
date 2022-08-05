%% you need to change most of the paths in this block

delete_previous_KS_run = true; %WARNING deletes all files in data folder except for Trodes-specific files

addpath('C:\Users\Adam\Documents\MATLAB\neuropixels_preprocessing\sortingQuality')
addpath('C:\Users\Adam\Documents\MATLAB\neuropixels_preprocessing\sortingQuality\core')
addpath('C:\Users\Adam\Documents\MATLAB\neuropixels_preprocessing\sortingQuality\helpers')
addpath(genpath('C:\Users\Adam\Documents\Kilosort-2.5')) % path to kilosort folder
addpath('C:\Users\Adam\Documents\npy-matlab') % for converting to Phy, https://github.com/kwikteam/npy-matlab

rootZ = 'D:\Neurodata\TQ02\20210416_162720'; % the raw data binary file is in this folder CANT HAVE TRAILING SLASH
rootH = 'D:\Neurodata\TQ02\20210416_162720'; % path to temporary binary file (same size as data, should be on fast SSD)

pathToYourConfigFile = 'C:\Users\Adam\Documents\Kilosort-2.5\configFiles'; % take from Github folder and put it somewhere else (together with the master_file)
% chanMapFile = 'neuropixPhase3B1_kilosortChanMapTORBEN.mat';
chanMapFile = 'channelMap.mat';

%make chan map 
getChanMap(rootZ); %spikegadgets tool

%kilosort subfolder for KS output
[~,ss] = fileparts(rootZ);
kfolder = strcat(ss,'.kilosort');
if ~isfolder(fullfile(rootH,kfolder)),mkdir(fullfile(rootH,kfolder)), end
if ~isfolder(fullfile(rootZ,kfolder)),mkdir(fullfile(rootZ,kfolder)), end

%kilosort subfolder containing Trodes binary data file (Trodes will make a
%subfolder when exporting binary data file for kilosort)
ksdatafolder = strcat(ss,'.kilosort');

%make config struct
if delete_previous_KS_run
   delete_KS_files(fullfile(rootZ,kfolder));
   delete_KS_files(fullfile(rootH,kfolder));
end

%make a copy of this script for reference
scriptpath = mfilename('fullpath'); scriptpath= [scriptpath,'.m'];
[~,scriptname]=fileparts(scriptpath); scriptname= [scriptname,'.m'];
ff = fullfile(rootZ,kfolder,scriptname);
ops.main_kilosort_script = ff;
copyfile(scriptpath,ff);

%KS ops
ops.trange    = [0 Inf]; % time range to sort
ops.NchanTOT  = 384; % total number of channels in your recording

run(fullfile(pathToYourConfigFile, 'StandardConfig_384Kepecs.m'))
ops.fproc   = fullfile(rootH, kfolder, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = fullfile(rootZ, chanMapFile);

%% this block runs all the steps of the algorithm

% main parameter changes from Kilosort2 to v2.5
ops.sig        = 20;  % spatial smoothness constant for registration
ops.fshigh     = 300; % high-pass more aggresively
ops.nblocks    = 1; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 
%jesus remember to remove this amy, trying a test for torben!


% binary dat file
kfile = strcat(ss,'.probe1.dat');
ops.fbinary = fullfile(rootZ, ksdatafolder, kfile);
%ops.fbinary = 'E:\Neurodata\20210107_172745_20210108_164001\combined.dat';

% preprocess data to create temp_wh.dat
% rez = preprocessDataSub(ops);
rez = preprocessDataSub(ops);

%
% NEW STEP TO DO DATA REGISTRATION
  % last input is for shifting data
rez = datashift2(rez, 1);
% ORDER OF BATCHES IS NOW RANDOM, controlled by random number generator
iseed = 1;
                 
% main tracking and template matching algorithm
rez = learnAndSolve8b(rez, iseed);
% check_rez(rez);

% OPTIONAL: remove double-counted spikes - solves issue in which individual spikes are assigned to multiple templates.
% See issue 29: https://github.com/MouseLand/Kilosort/issues/29
%rez = remove_ks2_duplicate_spikes(rez);

% final merges
rez = find_merges(rez, 1);
% check_rez(rez);

% final splits by SVD
rez = splitAllClusters(rez, 1);
% check_rez(rez);

% decide on cutoff
rez = set_cutoff(rez);
% check_rez(rez);

% eliminate widely spread waveforms (likely noise)
rez.good = get_good_units(rez);

fprintf('found %d good units \n', sum(rez.good>0))

% write to Phy
fprintf('Saving results to Phy  \n')
rezToPhy(rez, fullfile(rootH,kfolder));

% compute quality metrics
[cids, uQ, cR, isiV, histC] = sqKilosort.computeAllMeasures(fullfile(rootH, kfolder));

sqKilosort.metricsToPhy(rez, fullfile(rootH, kfolder), cids, uQ, isiV, cR, histC);
%save them for phy

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
% superlarge & slow)
spikeTimes = uint64(rez.st3(:,1));
fname = fullfile(rootH,kfolder, 'spike_times.mat');
save(fname, 'spikeTimes', '-v7.3');

% save final results as rez2
fprintf('Saving final results in rez2  \n')
fname = fullfile(rootH,kfolder, 'rez2.mat');
save(fname, 'rez', '-v7.3');

%save KS figures
fname = fullfile(rootH,kfolder);
figHandles = get(0, 'Children');  
saveFigPNG(fname,figHandles(end-2:end));