%Converts 6 analog channels to TTL-like event times in seconds

%requires export of dio in Trodes (should be replaced by command function
%calls when SPikeGadgets fixes their shit)

%LC/QC/TO 2018-21

function [Events_TTL, Events_TS] = extractTTLs(fname1, fname2, offset, kfolder)
% fname is a .rec file (full path)
%requires Trodes2MATLAB package from Trodes

%first extract required datafiles from .rec Trodes recording file
% using Trodes2MATLAB package

gaps = load(kfolder);

[datafolder, filemask] = fileparts(fname1);

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



[datafolder2, filemask2] = fileparts(fname2);

cd(datafolder2) %Trodes forces you to do that

% DIO
% extractTimeBinaryFile(filemask)
% extractDioBinaryFiles(filemask)

cd([filemask2,'.DIO']) %Trodes forces you to do that

% each analog MCU input pin will have its own .dat file
flist = dir('*Din*.dat');
num_Din2 = length(flist);
TTLs_ts2 = [];
for i=1:num_Din2
    Din_each2 = readTrodesExtractedDataFile(flist(i).name);
    if (isempty(Din_each2))
        disp(['File read error: ',flist]);
        return;
    end
    Din_cell2{i} = double(Din_each2.fields(2).data);
    ts_Din_cell2{i} = double(Din_each2.fields(1).data)/Din_each2.clockrate;

    TTLs_ts2 = [TTLs_ts2; ts_Din_cell2{i}];
end

TTLs_ts2 = unique(TTLs_ts2)';
TTLs2 = zeros(size(TTLs_ts2));
Din_matrix2 = zeros(num_Din2, length(TTLs_ts2));

% Din matrix
for j=1:num_Din2
    for i=1:length(TTLs_ts2)
        idx = find(ts_Din_cell2{j} == TTLs_ts2(i),1);
        %ts_tmp = TTLs_ts(i);

        if ~isempty(idx)
            Din_matrix2(j,i) = Din_cell2{j}(idx);
        else
            Din_matrix2(j,i) = Din_matrix2(j,i-1);
        end

    end
    Din_matrix2(j,:) = Din_matrix2(j,:) * 2^(j-1);   % Convert it to decimal
end
TTLs2 = sum(Din_matrix2,1);

TTLs_ts2 = TTLs_ts2 + double(offset);



TTLs = [TTLs TTLs2 repmat([-1], [1, length(gaps.gaps_ts)])];
TTLs_ts = [TTLs_ts TTLs_ts2 gaps.gaps_ts'];

[TTLs_ts, sort_ind] = sort(TTLs_ts);
TTLs = TTLs(sort_ind);
    
% change formats for Cellbase process
Events_TTL = TTLs;
Events_TS = TTLs_ts;

end