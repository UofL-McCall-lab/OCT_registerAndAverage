%{
Demo of using cpselect() to register images. Requires image processing toolbox.
10-2020 David Alston
david.alston@louisville.edu
%}
clc
close all
clear
%% Load the two images from current folder. The 'movingImg' image will be moved to align with the 'fixedImg' image
fixedImg = imread('7944 OS VSC+VSN+bleb.png');
movingImg = imread('7944 OS VSC reg 351.png');
%% Open cpselect tool plus a montage showing both images together
montageHandle = imshowpair(fixedImg, movingImg, 'montage');
title(gca, 'Fixed vs moving image pre-registration');
[movingPts, fixedPts] = cpselect(movingImg, fixedImg, 'Wait', true); % Open cpselect tool here
close all
% cpselect usage notes:
%{
 For this demo, you need at least three pairs of points

 Left click places a point on one image, click the same "feature" on the
 other image to finish a pair (indicated by the same integer identifying
 pairs)

 By checking the lock ratio checkbox you can zoom both in/out at the same
 level to more precisely place control points.

 When finished, in the cpselect tool go to file -> close control point selection tool

 If multiple images need the same exact transform, it is trivial to take
 myTransform and apply it to many images in a loop
%}
%% Generate transform and align images. See 'transform type' table of the fitgeotrans() function page.
% Transformation info:
%{
% Transformation type controls the minimum number of pairs needed to generate transform.
% In this case, there must be at least three pairs to generate a transform ('similarity')

% See which kind of transformation you need and change accordinly (is there
% warping between the images or is just translation, rotation, and scaling
% all that is needed? etc etc).
%}
myTransform = fitgeotrans(movingPts, fixedPts, 'similarity');
%% Finally, align images and show the transform with the moved image
movedImg = imwarp(movingImg, myTransform, 'nearest', 'OutputView', imref2d(size(fixedImg)));
imshowpair(fixedImg, movedImg);
title(gca, 'Fixed vs moved image post-registration');
%% Optionally, save image to new file
imwrite(movedImg, '7944 OCT crop.png');
saveas(gcf,'7944 OS VSC vsn bleb OCT with r1-4 lines swapped.png');
