% ------------------------------------------------------
%  Company: Georgia Tech
%  Engineer: Gregory H. Walls
% 
%  Create Date: 11/16/2017
%  Design Name: video_transpose (MATLAB model)
%  Project Name: VGA Image Transpose and Edge Detection
% ------------------------------------------------------

function [tran_imag_hor, tran_imag_ver, tran_imag_yoshi] = transpose_model(orig_imag_hor, orig_imag_ver, orig_imag_yoshi, wid, len)

% close all; clear; clc;

% wid = 160; % image width
% len = 120; % image length

% ---------------------
% Horizontal Test Image
% ---------------------
% Original Image
% orig_imag_hor = uint8(zeros(len,wid));
% for i = 1:len
%     for j = 1:wid
%         orig_imag_hor(i,j) = uint8(j);
%     end
% end
% Transpose Image
tran_imag_hor = tran(len, wid, orig_imag_hor);

% -------------------
% Vertical Test Image
% -------------------
% Original Image
% orig_imag_ver = uint8(zeros(len,wid));
% for i = 1:len
%     for j = 1:wid
%         orig_imag_ver(i,j) = uint8(i);
%     end
% end
% Transpose Image
tran_imag_ver = tran(len, wid, orig_imag_ver);

% ----------------
% Yoshi Test Image
% ----------------
% Original Image
% yoshi = imread('yoshi.png');
% orig_imag_yoshi = yoshi(:,:,1);
% Transpose Image
tran_imag_yoshi = tran(len, wid, orig_imag_yoshi);

figure('Name', 'Transpose Circuit');

subplot(3,2,1)
imshow(orig_imag_hor, [])
title('Horizontal Test -- Original Image')
subplot(3,2,2)
imshow(tran_imag_hor, [])
title('Horizontal Test -- Transpose Image')

subplot(3,2,3)
imshow(orig_imag_ver, [])
title('Vertical Test -- Original Image')
subplot(3,2,4)
imshow(tran_imag_ver, [])
title('Vertical Test -- Transpose Image')

subplot(3,2,5)
imshow(orig_imag_yoshi, [])
title('Yoshi Test -- Original Image')
subplot(3,2,6)
imshow(tran_imag_yoshi, [])
title('Yoshi Test -- Transpose Image')

end

function tran_imag = tran(len,wid,orig_imag)
tran_imag = uint8(zeros(len,wid));
for i = 1:len
    for j = 1:len
        tran_imag(i,j) = orig_imag(j,i);
    end
end
end