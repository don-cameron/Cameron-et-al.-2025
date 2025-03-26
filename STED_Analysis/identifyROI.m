function [colorImage,centroidY,centroidX] = identifyROI(NucImage,PunImage)

%Identify nucleus, select only the largest nucleus

%Threshold and create binary image
[~,threshold] = edge(NucImage,'sobel');
fudgeFactor = 1.3; %Adjust if necessary MED4 = 0.9, H3.3 = 1.3
binary_img = edge(NucImage,'sobel',threshold * fudgeFactor);
se90 = strel('line',5,90);
se0 = strel('line',5,0);
binary_img = imdilate(binary_img, [se90 se0])
%remove small debris
minObjectSize = 1000; % Adjust as needed
binary_img = bwareaopen(binary_img, minObjectSize);
%imshow(binary_img)
%fill in only small holes by inverting back and forward
binary_img = ~binary_img;
minObjectSize = 2000; % Adjust as needed
binary_img = bwareaopen(binary_img, minObjectSize);
binary_img = ~binary_img;
%smooth
seD = strel('diamond',1);
binary_img = imerode(binary_img,seD);
BWfinal = imerode(binary_img,seD);
%imshow(BWfinal)
%keep only biggest structure, removed for now as sometimes it loses half of
%main nucleus
%labeledMask = bwlabel(BWfinal)
%component_areas = regionprops(labeledMask, 'Area');
%[~, largest_component_label] = max([component_areas.Area]);
%BWfinal(labeledMask ~= largest_component_label) = 0;

PunImagedb = double(PunImage)

% Define the standard deviation (sigma) for the Gaussian filter
sigma = 0.7; % Adjust this value as needed

% Apply Gaussian smoothing to the image
smoothedImage = imgaussfilt(PunImagedb, sigma);

% LoG filtering
kernel = fspecial('log', [10 10],0.5)
filteredImage = imfilter(smoothedImage, kernel)

%figure;
%subplot(3, 2, 1);
%imshow(smoothedImage, []);
%title('smoothedImage');

%subplot(1, 2, 2);
%imshow(filteredImage, []);
%title('LoG filtering');

% Get the size of the original image
originalSize = size(filteredImage);

% Calculate the target size (10 times bigger)
targetSize = originalSize * 10;

% Resize the image to the target size using bilinear interpolation
resizedImage = imresize(filteredImage, targetSize, 'bilinear');

% Define the standard deviation (sigma) for the Gaussian filter on resized
% image
sigmaresized = 7;

% Apply Gaussian smoothing to the image
finalImage = imgaussfilt(resizedImage, sigmaresized);

% Set a threshold value (adjust as needed)
pixelthreshold = 1; % Example threshold value

% Define the size of the comparison window (15x15 in this case)
windowSize = 300;

% Create a disk-shaped structuring element to define the window
SE = strel('disk', floor(windowSize/2));

% Dilate the LoG image using the structuring element
dilatedImage = imdilate(finalImage, SE);

%Expand nuclear mask
resizedBWfinal = imresize(BWfinal, targetSize, 'nearest');

% Find local maxima by comparing the dilated image and the original LoG image
localMaxima = (finalImage == dilatedImage);

% Apply the threshold to retain only local maxima above the threshold
localMaxima = localMaxima & (finalImage > pixelthreshold);

% Select only local Maxima within nuclear mask
localMaxima = bsxfun(@and, localMaxima, resizedBWfinal);

resizedPunImage = imresize(PunImage, targetSize, 'nearest');

% Create a color version of the original image (for overlay)
colorImage = cat(3, resizedPunImage, resizedPunImage, resizedPunImage);

% Display the original image
%imshow(colorImage, []);
%hold on;

% Define the structuring element (21x21 ones)
se = strel('square', 21);

% Perform dilation on the binary matrix
expandedLocMax = imdilate(localMaxima, se);

% Display the expanded matrix
%imshow(expandedLocMax, 'InitialMagnification', 'fit');

% Create a mask for red pixels based on local Maxima
Mask = cat(3, expandedLocMax, false(size(expandedLocMax)), false(size(expandedLocMax)));

% Set the corresponding pixels in the color image to red 
colorImage(Mask) = 255;  % Set channels to maximum value

% Display the resulting image
%imshow(colorImage, []);
%title('Spot Predictions');

% Get the coordinates of the centroids from the binary matrix
[centroidY, centroidX] = find(localMaxima);