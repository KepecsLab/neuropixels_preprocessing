%% you need to change most of the paths in this block
clear all
close all
clc
reset(gpuDevice);

delete_previous_KS_run = false; %WARNING deletes all files in data folder except for Trodes-specific files

addpath(genpath('C:\Users\Adam\Documents\Kilosort-3.0')) % path to kilosort folder
addpath('C:\Users\Adam\Documents\npy-matlab') % for converting to Phy
rootZ = 'D:\Neurodata\TQ02\20210513_151122'; % the raw data binary file is in this folder
% rootH = 'D:\'; % path to temporary binary file (same size as data, should be on fast SSD)
pathToYourConfigFile = 'C:\Users\Adam\Documents\Kilosort-2.5\configFiles'; % take from Github folder and put it somewhere else (together with the master_file)
% chanMapFile = 'neuropixPhase3B1_kilosortChanMapTORBEN.mat';
chanMapFile = 'channelMap.mat';

%make chan map 
getChanMap(rootZ); %spikegadgets tool

%kilosort subfolder for KS output
[~,ss] = fileparts(rootZ);
kfolder = strcat(ss,'.3kilosort');
if ~isfolder(fullfile(rootZ,kfolder)),mkdir(fullfile(rootZ,kfolder)), end

%if delete_previous_KS_run
%   delete_KS_files(fullfile(rootZ,kfolder));
%end


%kilosort subfolder containing Trodes binary data file (Trodes will make a
%subfolder when exporting binary data file for kilosort)
ksdatafolder = strcat(ss,'.kilosort');

%make config struct
%if delete_previous_KS_run
%   delete_KS_files(fullfile(rootZ,kfolder));
%end

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
ops.fproc   = fullfile(rootZ, kfolder, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = fullfile(rootZ, chanMapFile);

%% this block runs all the steps of the algorithm

% main parameter changes from Kilosort2 to v2.5
ops.sig        = 20;  % spatial smoothness constant for registration
ops.fshigh     = 300; % high-pass more aggresively
ops.nblocks    = 5; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 

% main parameter changes from Kilosort2.5 to v3.0
ops.Th       = [9 9];

% binary dat file
kfile = strcat(ss,'.probe1.dat');
ops.fbinary = fullfile(rootZ, ksdatafolder, kfile);

rez                = preprocessDataSub(ops);



rez                = datashift2(rez, 1);


%start here


[rez, st3, tF]     = extract_spikes(rez);



rez                = template_learning(rez, tF, st3);



[rez, st3, tF]     = trackAndSort(rez);



rez                = final_clustering(rez, tF, st3);


rez                = find_merges(rez, 1);

rootZ = fullfile(rootZ, 'kilosort3');
mkdir(rootZ)
rezToPhy2(rez, rootZ);

%% 