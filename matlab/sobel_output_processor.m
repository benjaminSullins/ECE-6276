clear; clc;
%% Set Up
% Copy and paste below output files from Xilinx simulation directory to this
% scripts local directory 'output_files' folder
%       output_files\image_data.txt
%       output_files\horz_filter_output_data.txt
%       output_files\vert_filter_output_data.txt
%       output_files\sum_filter_output_data.txt
%%
num_col = 160;              % Number of Columns in Image
num_row = 120;              % Number of Rows in Image

id = fopen('output_files\image_data.txt');
t = textscan(id, '%q');
fclose(id);

id = fopen('output_files\vert_filter_output_data.txt');
v = textscan(id, '%q');
fclose(id);

id = fopen('output_files\horz_filter_output_data.txt');
h = textscan(id, '%q');
fclose(id);

id = fopen('output_files\sum_filter_output_data.txt');
s = textscan(id, '%q');
fclose(id);

t = cell2mat(t{:});
v = cell2mat(v{:});
h = cell2mat(h{:});
s = cell2mat(s{:});

t = bin2dec(t);
v = bin2dec(v);
h = bin2dec(h);
s = bin2dec(s);

t = uint8(t);
v = uint8(v);
h = uint8(h);
s = uint8(s);

t = reshape(t, [num_col num_row])';
v = reshape(v, [num_col num_row])';
h = reshape(h, [num_col num_row])';
s = reshape(s, [num_col num_row])';

imwrite(v, 'output_files\vert_output_image', 'PNG');
imwrite(h, 'output_files\horz_output_image', 'PNG');
imwrite(s, 'output_files\sum_output_image', 'PNG');

figure('Name', 'Simulation Output');
subplot(2,2,1); imshow(t);
subplot(2,2,2); imshow(v);
subplot(2,2,3); imshow(h);
subplot(2,2,4); imshow(s);
print('output_files\sobel_sim_output_images.png', '-dpng');