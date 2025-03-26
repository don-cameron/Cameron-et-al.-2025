clear all

% Create a message dialog with an "OK" button
message = ['1: Select directory for puncta coordinates', newline, ...
           '2: Select directory for visualization', newline, ...
           '3: Select output directory'];
dlgTitle = 'Information';
btn = 'OK';

% Display the dialog box and wait for the user to click "OK"
choice = questdlg(message, dlgTitle, btn, btn);

% Check if the user clicked "OK" and continue with your code
if strcmp(choice, btn)
    disp('User clicked OK. Continue with your code.');
end

% Prompt the user for the puncta detection directory
PunDirectory = uigetdir('', 'Select directory for puncta coordinates');
if PunDirectory == 0
    disp('User canceled the puncta coordinate selection. Exiting...');
    return;
end

% Prompt the user for the visualization directory
VisDirectory = uigetdir('', 'Select directory for vshuisualization');
if VisDirectory == 0
    disp('User canceled the visualization directory selection. Exiting...');
    return;
end

% Prompt the user for the output directory
OutDirectory = uigetdir('', 'Please choose the output directory');
if OutDirectory == 0
    disp('User canceled the output directory selection. Exiting...');
    return;
end

% List the files in each directory
CoorFiles = dir(fullfile(PunDirectory, '*.mat'));
VisFiles = dir(fullfile(VisDirectory, '*.tif'));

% Sort the files alphabetically
CoorFiles = {CoorFiles.name};
customSortFunction = @(x) str2double(regexp(x, '_([\d.]+)\.mat', 'tokens', 'once'));
numericValues = cellfun(customSortFunction, CoorFiles);
[~, sortedIndices] = sort(numericValues);
CoorFiles = CoorFiles(sortedIndices);
VisFiles = sort({VisFiles.name});

% Initialize variables to store the total results
totalSumROI = zeros(size(401,401)); % Initialize with the size of initialSumROI
totalNumROI = 0; % Initialize with the size of initialNumROI

% Set the radii for which you want to calculate average intensities
radii = [10, 20, 30, 40, 50];

% Prepare full results table
total_results_cell = {};

% Define the size of the ROI (401x401 pixels)
roiSize = 401;

% Loop through each image
for i = 1:numel(CoorFiles)
    % Generate the file paths for the current set of images
    PunFile = fullfile(PunDirectory, CoorFiles{i});
    VisImage = fullfile(VisDirectory, VisFiles{i});

    % Read the images from the file paths
    PunCoor = load(PunFile);
    VisImage = imread(VisImage);

    % Call the punctaROI function with the current set of images
    [sumROI, numROI, results_cell] = CalculateROI(PunCoor, VisImage, radii, roiSize);

    % Accumulate the results
    totalSumROI = totalSumROI + sumROI;
    totalNumROI = totalNumROI + numROI;

    %Save average measurements in output directory
    results_table = cell2table(results_cell);
    outputFilename = fullfile(OutDirectory, sprintf('Intensity_measurements_%d.xlsx', i));
    writetable(results_table, outputFilename);

    %Compile full result table
    total_results_cell{end+1} = results_cell;
end

%Save total measurements in output directory
total_results_cell = vertcat(total_results_cell{:});
total_results_table = cell2table(total_results_cell); 
outputFilename = fullfile(OutDirectory, 'All_Intensity_measurements.xlsx');
writetable(total_results_table, outputFilename);

% Divide the summed ROI values by the number of ROIs to get the average
averagedROI = totalSumROI / totalNumROI; % Divide by the number of valid ROIs

% Define the desired mapping range
minValueInDouble = 0;  % Minimum value in doubleMatrix
maxValueInDouble = 200;  % Maximum value in doubleMatrix
minValueInUint16 = 0;  % Minimum value in uint16 range (0)
maxValueInUint16 = 65535;  % Maximum value in uint16 range (65535)

% Transpose the matrix if needed
transposedMatrix = averagedROI';

% Scale and map the values to fit the uint16 data type range
ROI = uint16((transposedMatrix - minValueInDouble) / (maxValueInDouble - minValueInDouble) * (maxValueInUint16 - minValueInUint16) + minValueInUint16);

% Display the original and scaled matrices
%disp('Original Double Matrix:');
%disp(doubleMatrix);

%disp('Scaled uint16 Matrix:');
%disp(scaledMatrix);

% Get the folder names
pathParts = strsplit(VisDirectory, '/');
visFolderName = pathParts{end};

% Define the regular expression pattern
pattern = 'Nuc_(\w+)_Pun_(\w+)_coordinates_\d+\.mat';
match = regexp(PunFile, pattern, 'tokens', 'once');
NucPunName = sprintf('Nuc_%s_Pun_%s', match{1}, match{2});

% Define the output filename based on folder names
outputFilename = sprintf('%s_Vis_%s.tif', NucPunName, visFolderName);

% Save the image using imwrite
imwrite(ROI, fullfile(OutDirectory, outputFilename));

