% folder is the data folder of the recording. Just navigate to this folder
% in matlab and run the script. Trodes to Matlab needs to be in the path.
% V. A. Normand 2020. 
function getChanMap(varargin)

if ~isempty(varargin)
    sessionpath = varargin{1};
else
    sessionpath = pwd;
end

[~,ks_folder] = fileparts(sessionpath);
ks_file = fullfile(sessionpath, strcat(ks_folder, '.kilosort'), strcat(ks_folder, '.channelmap_probe1.dat'));
ks_struct = readTrodesExtractedDataFile(ks_file);
nchan = length(ks_struct.fields(1).data);
chanMap = (1:1:nchan)';
chanMap0ind = chanMap -1;
connected = ones(nchan, 1);
shankInd = ones(nchan, 1);
xcoords = double(ks_struct.fields(1).data);
ycoords = double(ks_struct.fields(2).data);
save(fullfile(sessionpath, 'channelMap.mat'), 'chanMap', 'chanMap0ind', 'connected', 'shankInd', 'xcoords', 'ycoords')

end