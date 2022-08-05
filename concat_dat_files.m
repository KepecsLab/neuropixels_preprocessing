function [ops] =  concat_dat_files(ops, fbinary, fproc, stub)
% fbinary: cell list of paths to Trodes recording session FOLDERS (will assume .kilosort subfolder with extracted binary raw data file)
% fproc: path to merged output binary data FILE

% fbinary = {'D:\Neurodata\TQ01\20210107_172745\20210107_172745.kilosort\20210107_172745.probe1.dat', 'D:\Neurodata\TQ01\20210108_164001\20210108_164001.kilosort\20210108_164001.probe1.dat'};
% fproc = 'E:\Neurodata\20210107_172745_20210108_164001\combined.dat';

NchanTOT = 384;

fidW = fopen(fproc,   'a+'); % open for writing processed data   
if fidW<3
    error('Could not open %s for writing.',ops.fproc);    
end
tic;
file_lens = [];
for i = 1:length(fbinary)
    fprintf('Time %3.0fs. concatenating file... \n', toc);
    %path to file
    [~,ss] = fileparts(fbinary{i});
    ksdatafolder = strcat(ss,'.kilosort');
    kfile = strcat(ss,'.probe2.dat');
    datafile = fullfile(fbinary{i}, ksdatafolder, kfile);
    
    bytes       = get_file_size(datafile); % size in bytes of raw binary
    NT       = ops.NT ; % number of timepoints per batch
    NchanTOT = ops.NchanTOT; % total number of channels in the raw binary file, including dead, auxiliary etc

    
    if stub
         %only making small snippet of file, should be 60 batches!
        %NT = 40*(65600*2*NchanTOT);
        bytes = NT*100*2*NchanTOT;
    end
    
    nTimepoints = floor(bytes/NchanTOT/2); % number of total timepoints
    ops.tstart  = ceil(ops.trange(1) * ops.fs); % starting timepoint for processing data segment
    ops.tend    = min(nTimepoints, ceil(ops.trange(2) * ops.fs)); % ending timepoint
    ops.sampsToRead = ops.tend-ops.tstart; % total number of samples to read
    Nbatch      = ceil(ops.sampsToRead /NT);

    %if i == 1
    %    ops.midpoint = Nbatch;
    %end
    file_lens = [file_lens, bytes];
    %nTimepoints = nTimepoints + floor(bytes/NchanTOT/2); % number of total timepoints
    
    %ok we have to do something about this... woudl these parameters be per
    %file?
    %50 == reading larger chunks!
   % NT = 40*(65600*2*NchanTOT); % 2seconds * 30khz * 2bytes
   % Nbatch = ceil(bytes / 2*NchanTOT*NT);
    
    fid         = fopen(datafile, 'r'); % open for reading raw data
    if fid<3
        error('Could not open %s for reading.',ops.fbinary);
    end
    
   
    
    c = 0;
    for ind = 0:NT:bytes
        
        
        offset = ind;
        fseek(fid, offset, 'bof');
        
        %if we're at the end of the file only read the up to the end of the
        %file!
        if ind + NT >= bytes
            toread = bytes - ind;
        else
            toread = NT;
        end
        
        buff = fread(fid, toread / 2, '*int16');
        
        if isempty(buff)
            break; % this shouldn't really happen, unless we counted data batches wrong
        end
        

        count = fwrite(fidW, buff, 'int16'); % write this batch to binary file
        c = c+ count;
        if count~=numel(buff)
            error('Error writing batch %g to %s. Check available disk space.',ind,fproc);
        end
        
        
    end
    if ~(c == bytes / 2)
        error('Did not write the correct number of bytes.');
    end
    
    fclose(fid);
end

fclose(fidW);
