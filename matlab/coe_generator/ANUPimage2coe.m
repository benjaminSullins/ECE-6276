% Image to text conversion


% Read the image from the file
 [filename, pathname] = uigetfile('*.bmp;*.tif;*.jpg;*.pgm','Pick an M-file');
img = imread(strcat(pathname, filename));
img = imresize((img),[160 120]);
[ row col p ] =size(img);

if p == 3
    img = rgb2gray(img);
end

% Image Transpose
imgTrans = img';
% iD conversion
img1D = imgTrans(:);
% Decimal to Hex value conversion
imgHex = dec2hex(img1D);
% New txt file creation
fid = fopen('fakeCameraImage.coe', 'wt');
% Hex value write to the txt file
fprintf(fid,'memory_initialization_radix=16;\n');
fprintf(fid,'memory_initialization_vector=\n');
fprintf(fid, '%x\n', img1D);
% Close the txt file
fclose(fid)