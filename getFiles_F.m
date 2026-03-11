function [files] = getFiles_F(folderPath, extFilt)
%{
% getFiles_F
% 
% PURPOSE: Get file names and paths as two columns of cells
% 
% INPUTS: 
%   - folderPath = Char path to the folder containing files
%   - extensionFilter = Filter of files you want in a folder
%       -- '.jpg' for example
%       -- '0' if no fiter
% 
% OUTPUTS: 
%   - files = 2xN cell of N filepaths and file names
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2019b but may work
% 	on earlier versions).
% 
% AUTHOR: David C Alston (david.alston@louisville.edu) 2020.
% 
% NOTES:
%}
currDir = dir(folderPath);
currDir(1:2, :) = []; % Remove . and ..
files{:} = '';
n = 0;
indx = 0;
if ~strcmp(extFilt, '0')
    for i = 1:1:numel(currDir)
        currFile = currDir(i).name;
        if ~endsWith(currFile, extFilt, 'IgnoreCase', true)
            n = n+1;
            indx(n, 1) = i; %#ok<AGROW>
        end
    end
    if ~(indx == 0); currDir(indx) = []; end
    if numel(currDir) == 0
        disp('WARNING:: No files found with that extension');
        numFiles = 0; %#ok<NASGU>
        return
    end
end
numFiles = numel(currDir);
for n = 1:1:numFiles
    files{n,1} = strcat(currDir(n).folder, '\', currDir(n).name); 
    files{n,2} = currDir(n).name;
end
end