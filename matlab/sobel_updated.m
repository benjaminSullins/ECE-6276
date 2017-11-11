
clear; clc;
close all;

%% Build a Test Image
test_imag = uint8([128*ones(121, 148), 32*ones(121, 4),128*ones(121,148);
                   32*ones(4, 300);
                   128*ones(121, 148), 32*ones(121, 4), 128*ones(121,148)]);

% test_imag = imread('coins.png');
% [edge_v, th_v] = edge(imag, 'sobel', 'vertical');
% [edge_h, th_h] = edge(imag, 'sobel', 'horizontal');
% [edge_hv, th_hv] = edge(imag, 'sobel',  'both');

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

% X-Dir
% For each column, exclude border to avoid out-of-bounds indexing
for c = 2:l-1
    % For each row, exclude border to avoid out-of-bounds indexing
    for r = 2:w-1
        
        % In every clock cycle you will be grabbing all 3x3 elements that
        % you've buffered up.
        image_kernel = cast( test_imag(r-1:r+1, c-1:c+1), 'double');
        
        % You will then apply the sobel kernel element values to the
        % image_kernel in order to generate the center kernel elements
        % value. The double sum is just so matlab can reduce all of the
        % multiplications into a single pixel element.
        test_output_x(r,c) = sum(sum( image_kernel .* gx ));
        
    end
end

test_final_out = uint8(sqrt(test_output_x.^2 + test_output_y.^2));

subplot(2,2,1); imshow(test_imag);
subplot(2,2,2); imshow(uint8(test_output_x));
subplot(2,2,3); imshow(uint8(test_output_y));
subplot(2,2,4); imshow(test_final_out);
%% Using MATLAB DIP Functions

[edge_v, th_v] = edge(test_imag, 'sobel', 'vertical');
[edge_h, th_h] = edge(test_imag, 'sobel', 'horizontal');
[edge_hv, th_hv] = edge(test_imag, 'sobel',  'both');

figure;
subplot(2,2,1); imshow(test_imag);
subplot(2,2,2); imshow(edge_v);
subplot(2,2,3); imshow(edge_h);
subplot(2,2,4); imshow(edge_hv);