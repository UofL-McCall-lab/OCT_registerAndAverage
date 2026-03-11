%{
% batchRegisterAndAverage.m
% 
% PURPOSE: Read raw OCT images and register + average them in sets.
% 
% INPUTS: See INPUTS/CONTROLS section of code.
% 
% OUTPUTS: Averaged/aligned grayscale images in outputPath.
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2020b but may work
% 	on earlier versions). Also the Image processing/parallel processing
%   toolboxes plus the following:
%   - getFiles_F.m function
%   - parfor_progress folder (shows current progress in command window)
% 
% AUTHOR: David C Alston (david.alston@louisville.edu) 1-2021.
% 
% NOTES:
%   - Input images should be just a number etc with nothing else present (so
%     that the program can do them in order).
%       -- 1.png is the same as 0001.png, the program can handle both.
%       -- It converts the filename directly to an integer and sorts by
%          that integer to determine the raw image order.
%
%   - Can handle up to 9999 images. More will require minor edits to code.
%
%   - The averaged images will appear in a semi random order while
%     processing. This is normal and due to the way parallel processing works.
%
%   - In order to reduce memory use this reads images from image files, 
%     not the .oct itself (would have to load the entire OCT into memory).
%
%   - Supports any image formats supported by Matlab function imread() (see
%     online documentation for this function).
%
%   - Assumes grayscale images. If reads RGBA, throws out all but one layer.
%
%   - If you use all your cores, this computer will be unresponsive until 
%     processing is finished (no other work will be possible until it is done).
%       -- NumCores - 1 is a good default.
%
%   - To find the number of cores avaialble, type disp(feature('numcores'))
%     into the command window and hit enter.
%}
clc
close all
clear
%% INPUTS/CONTROLS
inputPath = 'C:\Users\dalst\Desktop\inFldr\F1'; % Folder with just input raw images and nothing else
outPath = 'C:\Users\dalst\Desktop\outFldr';  % Empty folder for output
outExtension = '.png'; % Any format supported by imwrite() Matlab function ('.png', '.tif', etc)
numCores = 9;          % Integer number of CPU cores to use. Number of cores - 1 is a good default. Depends heavily on available RAM
iterPerRaw = 300;      % # of iterations of optimizer per raw image in registration. Smaller = faster but less accurate. 300 default.
batchSize = 10;        % How many raw images to align/average together to produce 1 averaged image. 10 default
%% MAIN PROGRAM
addpath('parfor_progress');
[optimizer, metric] = imregconfig('monomodal');
optimizer.MaximumIterations = iterPerRaw;
optimizer.MinimumStepLength = 5e-4; % Default 5e-4
rawIms = getFiles_F(inputPath, '0');
for B = 1:size(rawIms, 1) % Sort by ID in case names are just 1.png, 2.png etc
    [~, fName, ~] = fileparts(rawIms{B, 1});
    rawIms{B, 3} = str2double(fName);
end
rawIms = sortrows(rawIms, 3);
numFiles = size(rawIms, 1); % This /batchSize is how many images will be made
if numFiles == 0
    beep;
    disp('ERROR:: No files found in inputPath. Check that it is correct. Closing...');
    return
end
if mod(numFiles, batchSize) ~= 0
    beep;
    disp('ERROR:: There are not a multiple of batchSize images in inputPath. Closing...');
    return
end
disp('Processing started at:');
disp(datetime('now'));
currentParPool = parpool(numCores); % Initializes parallel pool
try
    parfor_progress(numFiles/batchSize);
    parfor N = 1:(numFiles/batchSize)
        endIdx = N*batchSize; % Average/align in groups of batchSize
        startIdx = endIdx-(batchSize-1);
        image1 = imread(rawIms{startIdx, 1}); %#ok<PFBNS> % First image in set
        if numel(size(image1)) > 1 % RGB/RGBA image. Throw out all but first layer
            image1 = image1(:, :, 1);
        end
        myAvg = double(image1);    % Initialize average with first image
        fixedImg = double(image1); % Set fixed image as first image as well
        for V = (startIdx+1):endIdx
            movImg = imread(rawIms{V, 1});
            if numel(size(movImg)) > 1 % RGB/RGBA image. Throw out all but first layer
                movImg = movImg(:, :, 1);
            end
            moved = imregister(double(movImg), fixedImg, 'rigid', optimizer, metric); % Rigid = translation + rotation only
            myAvg = myAvg+moved;
        end
        myAvg = myAvg/batchSize;
        outFName = strcat(num2str(N, '%.4i'), outExtension); %.4i limits max image number to 9999
        outFull = fullfile(outPath, outFName);
        imwrite(mat2gray(myAvg), outFull);
        parfor_progress;
    end
    parfor_progress(0);
    delete(currentParPool);
catch % Delete the parallel pool if something goes wrong
    beep;
    disp('ERROR:: Something went wrong during processing. Closing parallel pool...');
    parfor_progress(0);
    delete(currentParPool);
    return
end
disp('Processing succesfully finished at:');
disp(datetime('now'));