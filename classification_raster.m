clear; clc;

dataFolder = 'saved_data_ROBOT'; 
dataFiles = dir(fullfile(dataFolder, '*_raster.mat'));

num_objects = length(dataFiles);
num_experiments_per_object = 40;
sensor_grid_size = 256;          
binarization_threshold = 0; 
num_frames_to_select = 30;

downsample_sizes = 1:16; 

accuracies = zeros(length(downsample_sizes), 1);

rng(0);

for ds_idx = 1:length(downsample_sizes)
    downsampled_size = [downsample_sizes(ds_idx), downsample_sizes(ds_idx)];
     
    allData = {};  
    labels = [];   

    for i = 1:num_objects
        fileName = fullfile(dataFolder, dataFiles(i).name);
        loadedData = load(fileName); 
        objectData = loadedData.all_trials; % [40 x 256 x 442]

        num_frames = size(objectData, 3);

        for j = 1:num_experiments_per_object
            trialData = squeeze(objectData(j, :, :)); % [256 x 442]

            trialData = trialData'; % [442 x 256]

            frame_magnitudes = sum(abs(trialData), 2); % [442 x 1]

            avg_magnitude = mean(frame_magnitudes);
            frames_above_avg = frame_magnitudes > avg_magnitude;
            frame_indices = find(frames_above_avg);

            num_available_frames = length(frame_indices);
            if num_available_frames >= num_frames_to_select
                selected_indices = randsample(frame_indices, num_frames_to_select);
            elseif num_available_frames > 0
                selected_indices = frame_indices;
            else
                continue;
            end

            for k = 1:length(selected_indices)
                frame_idx = selected_indices(k);
                original_frame = trialData(frame_idx, :); % [1 x 256]
                original_grid = reshape(original_frame, [16, 16]);
                downsampled_grid = imresize(original_grid, downsampled_size, 'bilinear');

                binary_grid = downsampled_grid > binarization_threshold;

                downsampled_vector = double(binary_grid(:))';
                allData{end+1} = downsampled_vector;
                labels(end+1, 1) = i;
            end
        end
    end

    X = cell2mat(allData'); 
    Y = labels;            

    fprintf('Downsample Size: %dx%d, Total Samples: %d\n', downsampled_size(1), downsampled_size(2), size(X, 1));

    cv = cvpartition(Y, 'HoldOut', 0.2);
    XTrain = X(training(cv), :);
    YTrain = Y(training(cv));
    XTest = X(test(cv), :);
    YTest = Y(test(cv));

    k_neighbors = 5;
    knnModel = fitcknn(XTrain, YTrain, 'NumNeighbors', k_neighbors);

    predictedLabels = predict(knnModel, XTest);

    accuracy = sum(predictedLabels == YTest) / numel(YTest) * 100;
    fprintf('Classification Accuracy for Downsample Size %dx%d: %.2f%%\n\n', downsampled_size(1), downsampled_size(2), accuracy);

    accuracies(ds_idx) = accuracy;
end

%% Plot the classification accuracies vs. downsample sizes
figure;
h1 = plot(downsample_sizes, accuracies, '-', 'LineWidth', 2);
xticks(downsample_sizes);
xticklabels(arrayfun(@(s) sprintf('%dx%d', s, s), downsample_sizes, 'UniformOutput', false));
xlabel('Downsample Size');
ylabel('Classification Accuracy (%)');
title('Classification Accuracy vs. Downsample Size');
grid on;

% Add horizontal reference line for aDTMF Classification Accuracy
hold on;
h2 = yline(95.60, '--r', 'LineWidth', 2);

% Interpolate accuracy at 5.65
interp_x = 5.65;
interp_y = interp1(downsample_sizes, accuracies, interp_x, 'linear');

% Plot star marker at (5.65, interpolated accuracy)
plot(interp_x, interp_y, 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'b');

% Add legend
legend([h1, h2], {'Raster Classification Accuracy', 'aDTMF Classification Accuracy (95.60%)'}, ...
       'Location', 'best');
hold off;
