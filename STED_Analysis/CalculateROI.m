function [sumROI, numROI, results_cell] = CalculateROI(PunCoor, VisImage, radii, roiSize)

% Get the size of the original image
originalSize = size(VisImage);

% Calculate the target size (10 times bigger)
targetSize = originalSize * 10;

%Resize visualizing image
resizedVisImage = imresize(VisImage, targetSize, 'nearest');

%Extract coordinates
centroidX = PunCoor.centroidX;
centroidY = PunCoor.centroidY;

% Initialize a matrix to store the averaged ROI values
sumROI = zeros(roiSize, roiSize);

% Initialize a counter for the number of ROIs processed
numROI = 0;

% Create a grid of coordinates
[X, Y] = meshgrid(1:roiSize, 1:roiSize);

%Determine center of ROI
center_x = (roiSize-1)/2 + 1; % X-coordinate of the center
center_y = center_x; % Y-coordinate of the center
% Calculate distance from the center
distance_from_center = sqrt((X - center_x).^2 + (Y - center_y).^2);

% Initialize a cell array to store results
results_cell = cell(0, 2 * length(radii));

% Loop through each centroid
for i = 1:length(centroidX)
    % Calculate the coordinates for the ROI boundaries based on the centroid
    xStart = max(round(centroidX(i) - roiSize / 2), 1);
    xEnd = min(round(centroidX(i) + roiSize / 2 - 1), size(resizedVisImage, 2));
    yStart = max(round(centroidY(i) - roiSize / 2), 1);
    yEnd = min(round(centroidY(i) + roiSize / 2 - 1), size(resizedVisImage, 1));
    
    % Extract the ROI from the original image
    roi = resizedVisImage(yStart:yEnd, xStart:xEnd);
    
    % Check if the ROI size matches the expected size (401x401)
    [roiHeight, roiWidth] = size(roi);
    if roiHeight == roiSize && roiWidth == roiSize
        % Add the ROI values to the averagedROIs matrix
        sumROI = sumROI + double(roi);
        %count the ROI
        numROI = numROI + 1;

        % Temporary array to store results for the current ROI
        current_results = zeros(1, 2 * length(radii));

        % Loop through each radius for the current ROI
        for j = 1:length(radii)

            % Identify pixels within and outside the circle for the current radius
            pixels_within_circle = distance_from_center <= radii(j);
            pixels_outside_circle = ~pixels_within_circle;

            % Extract pixel values within and outside the circle from the current ROI
            pixels_in_circle_values = double(roi(pixels_within_circle));
            pixels_outside_circle_values = double(roi(pixels_outside_circle));

            % Calculate the average intensity inside and outside the circle
            current_results(2 * j - 1) = mean(pixels_in_circle_values(:));
            current_results(2 * j) = mean(pixels_outside_circle_values(:));
        end

        % Add current results to the cell array
        results_cell = [results_cell; {current_results}];
    end
        
    end
end