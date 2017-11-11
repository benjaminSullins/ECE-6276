clear; clc;

%%
num_col = 160;              % Number of Columns in Image
num_row = 120;              % Number of Rows in Image

t = dlmread('image_data.txt');              % Test Image
% Copy and paste below output files from simulation directory to 
% this scripts local directory
h = uint8(dlmread('horz_filter_output_data.txt')); % Sobel horz output
v = uint8(dlmread('vert_filter_output_data.txt')); % Sobel vert output
s = uint8(dlmread('sum_filter_output_data.txt'));  % Sobel sum output

t = reshape(t, [num_col num_row])';
v = reshape(v, [num_col num_row])';
h = reshape(h, [num_col num_row])';
s = reshape(s, [num_col num_row])';

imwrite(v, 'vert_output_image', 'PNG');
imwrite(h, 'horz_output_image', 'PNG');
imwrite(s, 'sum_output_image', 'PNG');

subplot(2,2,1); imshow(t);
subplot(2,2,2); imshow(h);
subplot(2,2,3); imshow(v);
subplot(2,2,4); imshow(s);