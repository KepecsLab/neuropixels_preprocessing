function delete_KS_files(f)

%delete python files
fs = dir(fullfile(f, '*.npy'));
mydel(f,fs)

fs = dir(fullfile(f, '*.py'));
mydel(f,fs)

%delete log files
fs = dir(fullfile(f, '*.log'));
mydel(f,fs)

%delete m files
fs = dir(fullfile(f, '*.m'));
mydel(f,fs)

%delete mat files
fs = dir(fullfile(f, '*.mat'));
mydel(f,fs)

%delete cluster metrics files
fs = dir(fullfile(f, '*.tsv'));
mydel(f,fs)

%temp files
fs = dir(fullfile(f,'temp_wh.dat'));
mydel(f,fs)

%delete phy folder
if exist(fullfile(f, '.phy'), 'dir')
    rmdir(fullfile(f, '.phy'), 's');
end

function mydel(f,fs)

for i = 1:length(fs)
   delete(fullfile(f, fs(i).name));
end