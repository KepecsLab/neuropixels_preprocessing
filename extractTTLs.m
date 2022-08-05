%Converts 6 analog channels to TTL-like event times in seconds

%requires export of dio in Trodes (should be replaced by command function
%calls when SPikeGadgets fixes their shit)

%LC/QC/TO 2018-21

function [Events_TTL, Events_TS] = extractTTLs(fname, gaps_fn)
% fname is a .rec file (full path)
%requires Trodes2MATLAB package from Trodes

%first extract required datafiles from .rec Trodes recording file
% using Trodes2MATLAB package


[datafolder, filemask] = fileparts(fname);

gaps = load(gaps_fn);

cd(datafolder) %Trodes forces you to do that

% DIO
% extractTimeBinaryFile(filemask)
% extractDioBinaryFiles(filemask)

cd([filemask,'.DIO']) %Trodes forces you to do that

% each analog MCU input pin will have its own .dat file
flist = dir('*Din*.dat');
num_Din = length(flist);
TTLs_ts = [];
for i=1:num_Din
    Din_each = readTrodesExtractedDataFile(flist(i).name);
    if (isempty(Din_each))
        disp(['File read error: ',flist]);
        return;
    end
    Din_cell{i} = double(Din_each.fields(2).data);
    ts_Din_cell{i} = double(Din_each.fields(1).data)/Din_each.clockrate;
    
    TTLs_ts = [TTLs_ts; ts_Din_cell{i}];
end

TTLs_ts = unique(TTLs_ts)';
TTLs = zeros(size(TTLs_ts));
Din_matrix = zeros(num_Din,length(TTLs_ts));

% Din matrix
for j=1:num_Din
    for i=1:length(TTLs_ts)
        idx = find(ts_Din_cell{j} == TTLs_ts(i),1);
        ts_tmp = TTLs_ts(i);
        
        if ~isempty(idx)
            Din_matrix(j,i) = Din_cell{j}(idx);
        else
            Din_matrix(j,i) = Din_matrix(j,i-1);
        end
        
    end
    Din_matrix(j,:) = Din_matrix(j,:) * 2^(j-1);   % Convert it to decimal
end
TTLs = sum(Din_matrix,1);

TTLs = [TTLs repmat([-1], [1, length(gaps.gaps_ts)])];
TTLs_ts = [TTLs_ts gaps.gaps_ts'];

[TTLs_ts, sort_ind] = sort(TTLs_ts);
TTLs = TTLs(sort_ind);
    
% change formats for Cellbase process
Events_TTL = TTLs;
Events_TS = TTLs_ts;

end