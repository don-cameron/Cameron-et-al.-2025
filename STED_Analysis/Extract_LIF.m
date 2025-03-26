clear all
import loci.formats.*;
import java.io.File;

% Create a message dialog with an "OK" button
message = 'First prompt is for the .lif file. Second prompt is for the extraction directory. Then you need to name the channels.';
dlgTitle = 'Information';
btn = 'OK';

% Display the dialog box and wait for the user to click "OK"
choice = questdlg(message, dlgTitle, btn, btn);

% Check if the user clicked "OK" and continue with your code
if strcmp(choice, btn)
    disp('User clicked OK. Continue with your code.');
end

% Prompt the user to choose the .lif file
[lifFileName, lifPath] = uigetfile('*.lif', 'Select a .lif file');
if lifFileName == 0
    % User canceled, exit gracefully
    return;
end

% Create a Reader object
lifFilePath = fullfile(lifPath, lifFileName);
reader = bfGetReader(lifFilePath);

% Get the number of image series in the file
numSeries = reader.getSeriesCount();

% Prompt the user for the output directory
outputDirectory = uigetdir('', 'Please choose the output directory');
if outputDirectory == 0
    disp('User canceled the output directory selection. Exiting...');
    return;
end

% Create a directory for each channel
numChannels = reader.getSizeC();
channelDirectories = cell(1, numChannels);

for channelIndex = 1:numChannels
    % Prompt the user to enter the channel name
    prompt = ['Enter a name for Channel ' num2str(channelIndex) ':'];
    dlgTitle = 'Channel Name';
    numLines = 1;
    defaultChannelName = ['Channel ' num2str(channelIndex)];
    channelName = inputdlg(prompt, dlgTitle, numLines, {defaultChannelName});

    if isempty(channelName)
        % User canceled channel name input for this channel
        disp(['User canceled channel name input for Channel ' num2str(channelIndex)]);
        continue;
    end

    % Create a directory for the channel in the output directory
    channelDirectory = fullfile(outputDirectory, channelName{1});
    if ~exist(channelDirectory, 'dir')
        mkdir(channelDirectory);
    end

    channelDirectories{channelIndex} = channelDirectory;
end

% Loop through each series (assuming you want to read all of them)
for seriesIndex = 0:(numSeries - 1)
    % Set the current series
    reader.setSeries(seriesIndex);

    % Loop through each channel
    for channelIndex = 1:numChannels
        % Read the image for the current channel
        image = bfGetPlane(reader, channelIndex);

        % Specify the output filename for the channel
        outputFilename = fullfile(channelDirectories{channelIndex}, ...
            sprintf('Series%d_Channel%d.tif', seriesIndex, channelIndex));

        % Save the image as a TIFF file
        imwrite(image, outputFilename);

        % If you want to work with another channel in the same series, loop again.
    end
end

