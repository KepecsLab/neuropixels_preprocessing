%% you need to change most of the paths in this block
%currently all output saves in the last folder in the list of files
%this could be changed to a separate config option!

clear all
close all
clc

delete_previous_KS_run = false; %WARNING deletes all files in data folder except for Trodes-specific files

addpath(genpath('C:\Users\Adam\Documents\Kilosort-3.0')) % path to kilosort folder
addpath('C:\Users\Adam\Documents\npy-matlab') % for converting to Phy

session_dat_folders = {'D:\Neurodata\TQ01\20210115_172624' }; % raw binary dat-files to combine (SSD or HHD)
combined_dat_folder = 'E:\Neurodata\TQ01\20210115\'; % output folder for merged binary (SSD or HDD)
ks_output_folder = 'D:\Neurodata\TQ01\20210115\'; % saves large temp file and small(er) output files (SSD)

pathToYourConfigFile = 'C:\Users\Adam\Documents\Kilosort-2.5\configFiles'; % take from Github folder and put it somewhere else (together with the master_file)
% chanMapFile = 'neuropixPhase3B1_kilosortChanMapTORBEN.mat';
chanMapFile = 'channelMap.mat';

%make output folders
if ~isfolder(combined_dat_folder),mkdir(combined_dat_folder), end
if ~isfolder(ks_output_folder),mkdir(ks_output_folder), end
   
%combined binary data file
ops.fbinary = fullfile(combined_dat_folder,'combined.mat');
if exist(ops.fbinary,'file')~=2
    file_lens = concat_dat_files(session_dat_folders,ops.fbinary);
    %make combined data file
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


%KS ops
ops.trange    = [0 Inf]; % time range to sort
ops.NchanTOT  = 384; % total number of channels in your recording

% main parameter changes from Kilosort2.5 to v3.0
ops.Th       = [9 9];

%make config file
run(fullfile(pathToYourConfigFile, 'StandardConfig_384Kepecs.m'))

%This is the where the concatenated file goes, if we want it on
%the HDD change it here!!
%ops.fproc   = fullfile(rootZ{i}, kfolder, 'temp_wh.dat'); % proc file on a fast SSD
ops.fproc  = fullfile(ks_output_folder, 'temp_wh.dat'); % proc file on a fast SSD

ops.chanMap = fullfile(ks_output_folder, chanMapFile);
%we assume that the same whitenign matrix and same channel map is used for
%all files. 

%% this block runs all the steps of the algorithm

% main parameter changes from Kilosort2 to v2.5
ops.sig        = 20;  % spatial smoothness constant for registration
ops.fshigh     = 300; % high-pass more aggresively
ops.nblocks    = 5; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 

% preprocess data to create temp_wh.dat
% rez = preprocessDataSub(ops);
rez = preprocessDataSub(ops);

%
% NEW STEP TO DO DATA REGISTRATION
rez = datashift2(rez, 1); % last input is for shifting data

                 
% main tracking and template matching algorithm
[rez, st3, tF]     = extract_spikes(rez);

rez                = template_learning(rez, tF, st3);

[rez, st3, tF]     = trackAndSort(rez);

%start running from here
rez                = final_clustering(rez, tF, st3);

rez                = find_merges(rez, 1);


rezToPhy2(rez, ks_output_folder);
figHandles = get(0, 'Children');  
saveFigPNG(ks_output_folder,figHandles(end-2:end));
