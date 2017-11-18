% ------------------------------------------------------
%  Company: Georgia Tech
%  Engineer: Everybody In The Group
% 
%  Create Date: 11/16/2017
%  Design Name: Main (MATLAB model)
%  Project Name: VGA Image Transpose and Edge Detection
% ------------------------------------------------------
clear all;
close all;
clc;

%% Fake Camera Simulator
num_bits = 8;
vpix     = 160;
ipix     = 0;
vlin     = 120;
vga_pix  = 640;
vga_lin  = 480;

% Create the test Images
hori_image = zeros(vlin, vpix+ipix);
vert_image = zeros(vlin, vpix+ipix);
test_image = zeros(vlin, vpix+ipix);

for j = 1:vlin
    for i = ipix+1:vpix
        hori_image(j, i) = i - ipix;
        vert_image(j, i) = j;
    end
end

load_image = imread('yoshi.png');
load_image = rgb2gray(load_image);
load_image = imresize((load_image),[vlin vpix]);

test_image(:, ipix+1:vpix+ipix) = load_image;

% Convert to bit width
hori_image = cast(hori_image, 'uint8');
vert_image = cast(vert_image, 'uint8');
test_image = cast(test_image, 'uint8');

figure('Name', 'Fake Camera');
subplot(3,1,1); imshow(hori_image, []); title('Horizontal Test');
subplot(3,1,2); imshow(vert_image, []); title('Vertical Test');
subplot(3,1,3); imshow(test_image, []); title('Yoshi.png');

%% Transpose Circuit
[tran_imag_hor, tran_imag_ver, tran_imag_yoshi] = transpose_model(hori_image, vert_image, test_image, vpix, vlin);

%% Sobel Filter
sobel_imag_hor   = tran_imag_hor;
sobel_imag_ver   = tran_imag_ver;
sobel_imag_yoshi = tran_imag_yoshi;

%% VGA Circuit
[vga_imag_hor, vga_imag_ver, vga_imag_yoshi] = vga_model(sobel_imag_hor, sobel_imag_ver, sobel_imag_yoshi, vpix, vlin, vga_pix, vga_lin);

%% Colormap

figure('Name', 'Colormap');
colormap('pink');
subplot(3,1,1); imagesc(vga_imag_hor);   title('Horizontal Test');
subplot(3,1,2); imagesc(vga_imag_ver);   title('Vertical Test');
subplot(3,1,3); imagesc(vga_imag_yoshi); title('Yoshi.png');




