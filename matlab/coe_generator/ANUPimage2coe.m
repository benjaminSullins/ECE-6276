%% Image to text conversion

% Read the image from the file
[filename, pathname] = uigetfile('*.bmp;*.tif;*.jpg;*.pgm','Pick an M-file');
img = imread(strcat(pathname, filename));
img = imresize((img),[120 160]);
[ row col p ] = size(img);

if p == 3
    img = rgb2gray(img);
end

% for i = 1:160
%     for j = 1:120
%         img(j,i) = i;
%     end
% end

% Image Transpose
imgTrans = img';

% 1D conversion
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
fclose(fid);

%% Create the colormapping
numVidBits = 8;
numVgaBits = 4;

myColormap = colormap('pink');
myRange    = cast(myColormap*(2^numVidBits), 'uint8') / (2^(numVidBits-numVgaBits));
myRange    = myRange - 1; myRange(myRange < 0) = 0;
myRangeHex = [ dec2hex(myRange(:,1)), dec2hex(myRange(:,2)), dec2hex(myRange(:,3))];
myMapTemp  = myRangeHex(1:(numVidBits-numVgaBits):end,:);
myMap      = myMapTemp';

% New txt file creation
fid = fopen('colorMapping.coe', 'wt');
% Hex value write to the txt file
fprintf(fid,'memory_initialization_radix=16;\n');
fprintf(fid,'memory_initialization_vector=\n');
fprintf(fid, '%c%c%c\n', myMap);
% Close the txt file
fclose(fid);
