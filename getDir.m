function [folders,fullpath]=getDir(path,type,varargin)
%optional third argument specifying string requirement to filter
%file/folder names
folders=dir(path);
dirs=[folders.isdir];
folders={folders.name};

if ~isempty(folders)
idx=cellfun(@strncmp,folders,repmat({'.'},1,length(folders)),repmat({1},1,length(folders)));

if strcmpi(type,'folder')
    folders(idx|~dirs)=[];
elseif strcmpi(type,'file')
    folders(idx|dirs)=[];
else
    error('Unknown content type.')
end

if ~isempty(varargin)
    cond = cellfun(@strfind,folders,repmat(varargin(1),1,length(folders)),'UniformOutput',0);
    cond = ~cellfun(@isempty,cond);
    folders(~cond)=[];
end
fullpath = cellfun(@(x,p) fullfile(p,x),folders,repmat({path},1,length(folders)),'UniformOutput',0);
end
end