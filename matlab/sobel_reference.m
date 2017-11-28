clear; clc;

%% Build a Test Image
num_rows = 120;                         % Number of Rows
num_vcol = 160;                         % Valid Columns
num_icol = 0;                          % Invalid/padding Columns
num_cols = num_vcol + num_icol;

% Build a test image
% test_imag = uint8([128*ones(59, 79), 32*ones(59, 2), 128*ones(59,79);
%                    32*ones(2, 160);
%                    128*ones(59, 79), 32*ones(59, 2), 128*ones(59, 79)]);                 
                   
% test_imag = uint8(rgb2gray(imread('diamond.png')));

% test_imag = uint8(rgb2gray(imread('baymax.jpg')));

% test_imag = uint8(rgb2gray(imread('fishy.jpeg')));

% test_imag = imread('coins.png');

% test_imag = uint8(rgb2gray(imread('input_files\effiel_1.jpg')));

% test_imag = uint8(rgb2gray(imread('input_files\effiel_2.jpg')));

 test_imag = uint8(rgb2gray(imread('input_files\golden_gate_bridge_1.jpg')));

% test_imag = uint8(rgb2gray(imread('input_files\golden_gate_bridge_2.jpg')));

% test_imag = uint8(rgb2gray(imread('input_files\golden_gate_bridge_3.jpg')));

% test_imag = uint8(rgb2gray(imread('input_files\chess_board_calibration.jpg')));

% test_imag = uint8(rgb2gray(imread('input_files\mario.png')));

% test_imag = uint8(rgb2gray(imread('input_files\moon.jpg')));

% test_imag = uint8(rgb2gray(imread('input_files\face.jpg')));

% test_imag = uint8(rgb2gray(imread('input_files\yoshi.jpg')));

test_imag = imresize(test_imag, [num_rows num_vcol]);
padding = uint8(255*(ones(num_rows, num_icol)));
test_imag = [padding test_imag];

% Write image to text file for external processing on FPGA, output from FPGA can 
% be compared to output of this script for reference/verification
data = dec2bin(test_imag', 8);
dlmwrite('output_files\image_data.txt', data, 'delimiter', '');
%% Sobel Algorithm
gx = [1 0 -1;
      2 0 -2;
      1 0 -1];
  
gy = [-1 -2 -1;
       0  0  0;
       1  2  1];  
  
[w, l] = size(test_imag);                        % Get image dimensions

test_output_x = double(0*test_imag);             % Create output array for x-dir
test_output_y = double(0*test_imag);             % Create output array for y-dir

% test_output_x = (0*test_imag);             % Create output array for x-dir
% test_output_y = (0*test_imag);             % Create output array for y-dir

% X-Dir
% For each column, exclude border to avoid out-of-bounds indexing
for c = 2:l-2
    % For each row, exclude border to avoid out-of-bounds indexing
    for r = 2:w-2
        for m = c-1:c+1
            for n = r-1:r+1
                test_output_x(r,c) = test_output_x(r,c) + (gx(n-r+2, m-c+2) * double(test_imag(n,m)));
%                 test_output_x(r,c) = test_output_x(r,c) + (gx(n-r+2, m-c+2) * (test_imag(n,m)));
            end
        end
    end
end

% Y-Dir
% For each column, exclude border to avoid out-of-bounds indexing
for c = 2:l-2
    % For each row, exclude border to avoid out-of-bounds indexing
    for r = 2:w-2
        for m = c-1:c+1
            for n = r-1:r+1
                test_output_y(r,c) = test_output_y(r,c) + (gy(n-r+2, m-c+2) * double(test_imag(n,m)));
%                 test_output_y(r,c) = test_output_y(r,c) + (gy(n-r+2, m-c+2) * (test_imag(n,m)));
            end
        end
    end
end

figure('Name', 'Sobel Algorithm Reference');
subplot(2,2,1); imshow(test_imag);
subplot(2,2,2); imshow(uint8(test_output_x));
subplot(2,2,3); imshow(uint8(test_output_y));
subplot(2,2,4); imshow(uint8(test_output_x) + uint8(test_output_y));
print('output_files\sobel_algorithm_reference_images.png', '-dpng');

%% Using MATLAB DIP Functions

[edge_v, th_v] = edge(test_imag, 'sobel', 'vertical');
[edge_h, th_h] = edge(test_imag, 'sobel', 'horizontal');
[edge_hv, th_hv] = edge(test_imag, 'sobel',  'both');

figure('Name', 'MATLAB DIP Functions References');
subplot(2,2,1); imshow(test_imag);
subplot(2,2,2); imshow(edge_v);
subplot(2,2,3); imshow(edge_h);
subplot(2,2,4); imshow(edge_hv);
print('output_files\matlab_dip_funs_reference_images.png', '-dpng');