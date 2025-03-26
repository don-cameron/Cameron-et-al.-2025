clear all

% Create a message dialog with an "OK" button
message = ['1: Select directory for nucleus detection', newline, ...
           '2: Select directory for puncta detection', newline, ...
           '3: Select output directory'];
dlgTitle = 'Information';
btn = 'OK';

% Display the dialog box and wait for the user to click "OK"
choice = questdlg(message, dlgTitle, btn, btn);

% Check if the user clicked "OK" and continue with your code
if strcmp(choice, btn)
    disp('User clicked OK. Continue with your code.');
end

% Prompt the user for the nucleus detection directory
NucDirectory = uigetdir('', 'Select directory for nucleus detection');
if NucDirectory == 0
    disp('User canceled the nucleus directory selection. Exiting...');
    return;
end

% Prompt the user for the puncta detection directory
PunDirectory = uigetdir('', 'Select directory for puncta detection');
if PunDirectory == 0
    disp('User canceled the puncta directory selection. Exiting...');
    return;Nuc
end


% Prompt the user for the output directory
OutDirectory = uigetdir('', 'Please choose the output directory');
if OutDirectory == 0
    disp('User canceled the output directory selection. Exiting...');
    return;
end

% List the files in each directory
NucFiles = dir(fullfile(NucDirectory, '*.tif'));
PunFiles = dir(fullfile(PunDirectory, '*.tif'));

% Sort the files alphabetically
NucFiles = sort({NucFiles.name});
PunFiles = sort({PunFiles.name});

% Create subfolders
punDetectionSubfolder = fullfile(OutDirectory, 'PunDetection');
coordinatesSubfolder = fullfile(OutDirectory, 'Coordinates');
mkdir(punDetectionSubfolder);
mkdir(coordinatesSubfolder);

% Get the folder names
pathParts = strsplit(NucDirectory, '/');
nucFolderName = pathParts{end};
pathParts = strsplit(PunDirectory, '/');
punFolderName = pathParts{end};

% Loop through each image
for i = 1:numel(NucFiles)
    % Generate the file paths for the current set of images
    NucImage = fullfile(NucDirectory, NucFiles{i});
    PunImage = fullfile(PunDirectory, PunFiles{i});

    % Read the images from the file paths (you may need to adjust this part)
    NucImage = imread(NucImage);
    PunImage = imread(PunImage);

    % Call the punctaROI function with the current set of images
    [colorImage,centroidY,centroidX] = identifyROI(NucImage, PunImage);

    %Save image with puncta predictions in output directory
    outputFilename = fullfile(punDetectionSubfolder, sprintf('Nuc_%s_Pun_%s_PunDetection_%d.tif', nucFolderName, punFolderName, i));
    imwrite(colorImage, outputFilename);

    %Save puncta coordinates in output direction
    outputFilename = fullfile(coordinatesSubfolder, sprintf('Nuc_%s_Pun_%s_coordinates_%d.mat', nucFolderName, punFolderName, i));
    save(outputFilename, 'centroidY', 'centroidX');

end



