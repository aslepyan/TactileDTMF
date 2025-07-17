clear; clc;

dataFolder = 'saved_data_ROBOT';

dataFiles = dir(fullfile(dataFolder, '*_aDTMF.mat'));

num_objects = length(dataFiles);            
num_experiments_per_object = 40;            
sensor_grid_size = 256;                                     
num_frames_to_select = 30; 
binarization_threshold = 200; 

allData = {}; 
labels = [];   

for i = 1:num_objects
    fileName = fullfile(dataFolder, dataFiles(i).name);
    loadedData = load(fileName);
    objectData = loadedData.all_trials; % [40 x 256 x 816]

    for j = 1:num_experiments_per_object
        trialData = squeeze(objectData(j, :, :)); % [256 x 816]
        frame_magnitudes = sum(abs(trialData), 1); % [1 x 816]

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
            frame_data = trialData(:, frame_idx); % [256 x 1]

            binary_frame = double(frame_data > binarization_threshold);

            allData{end+1} = binary_frame';
            labels(end+1, 1) = i;
        end
    end
end

X = cell2mat(allData');
Y = labels;             
X = double(X);

fprintf('Total number of samples: %d\n', size(X, 1));

cv = cvpartition(Y, 'HoldOut', 0.2);
XTrain = X(training(cv), :);
YTrain = Y(training(cv));
XTest = X(test(cv), :);
YTest = Y(test(cv));

k_neighbors = 5;
knnModel = fitcknn(XTrain, YTrain, 'NumNeighbors', k_neighbors);

predictedLabels = predict(knnModel, XTest);

accuracy = sum(predictedLabels == YTest) / numel(YTest) * 100;
fprintf('Classification Accuracy: %.2f%%\n', accuracy);

%%
% DTMF sensor data
dataFolder = 'saved_data_ROBOT';
dataFiles = dir(fullfile(dataFolder, '*_aDTMF.mat'));

num_objects = length(dataFiles);            
num_experiments_per_object = 40;                                             

num_frames_to_select = 36;
allData = {}; 
labels = [];   

for i = 1:num_objects
    fileName = fullfile(dataFolder, dataFiles(i).name);
    loadedData = load(fileName);
    objectData = loadedData.all_trials; % [40 x 32 x 816]

    for j = 1:num_experiments_per_object
        trialData = squeeze(objectData(j, :, :)); % [32 x 816]

        trialData = trialData'; % [816 x 32]

        frame_magnitudes = sum(trialData, 2); % [816 x 1]
        avg_magnitude = mean(frame_magnitudes);
        frames_above_avg = frame_magnitudes > avg_magnitude;
        contact_blocks = bwlabel(frames_above_avg);

        block_lengths = arrayfun(@(x) sum(contact_blocks == x), unique(contact_blocks(contact_blocks > 0)));

        block_ids = unique(contact_blocks(contact_blocks > 0));
        if ~isempty(block_ids) && block_ids(1) == 1
            first_block_indices = find(contact_blocks == 1);
            if ~isempty(first_block_indices) && first_block_indices(1) == 1
                block_ids = block_ids(block_ids > 1);
            end
        end
                    
        if ~isempty(block_ids)
            block_lengths_filtered = arrayfun(@(x) sum(contact_blocks == x), block_ids);
            [~, longest_block_idx_filtered] = max(block_lengths_filtered);
        
            longest_block_id = block_ids(longest_block_idx_filtered);
            frame_indices = find(contact_blocks == longest_block_id);
        else
            continue;
        end

        sorted_magnitudes = sort(frame_magnitudes);
        percentile_20_idx = round(0.2 * length(sorted_magnitudes));
        thres_low_mag = sorted_magnitudes(percentile_20_idx); 
        
        search_start_idx = frame_indices(1);
        
        exact_start_idx = search_start_idx; 
        for idx = search_start_idx:-1:1
            if frame_magnitudes(idx) < thres_low_mag
                exact_start_idx = idx + 1; 
                break;
            end
        end
        
        start_idx = exact_start_idx;

        if start_idx < 2
            continue;
        end

        if start_idx - 1 + num_frames_to_select > 442
            continue;
        end

        selected_indices = ((start_idx - 1) : (start_idx - 2 + num_frames_to_select))';

        for k = 1:length(selected_indices)
            frame_idx = selected_indices(k);
            frame_data = trialData(frame_idx, :); % [1 x 32]
            
            if sum(frame_data) < thres_low_mag
                frame_data = zeros(size(frame_data));
            end

            allData{end+1} = frame_data;
            labels(end+1, 1) = i;
        end
    end
end

X = cell2mat(allData');
X = normalize(X);
Y = labels;             

if isempty(X) || isempty(Y)
    allAccuracies_DTMF(end+1) = NaN;
end

cv = cvpartition(Y, 'HoldOut', 0.2);
XTrain = X(training(cv), :);
YTrain = Y(training(cv));
XTest = X(test(cv), :);
YTest = Y(test(cv));

k_neighbors = 5;
knnModel = fitcknn(XTrain, YTrain, 'NumNeighbors', k_neighbors);

predictedLabels = predict(knnModel, XTest);

unique_objects = unique(YTest); 
num_objects_test = numel(unique_objects); 

object_accuracy = sum(predictedLabels == YTest) / numel(YTest) * 100;

object_accuracy

%% Plot the confusion matrix
figure;
cm = confusionchart(YTest, predictedLabels);
cm.Title = 'KNN Classification for Reconstructed aDTMF Data';

% Remove all cell labels (numbers inside blocks)
texts = findall(cm, 'Type', 'Text');
for i = 1:length(texts)
    if isprop(texts(i), 'String')
        texts(i).String = '';
    end
end

%%
C = confusionmat(YTest, predictedLabels);

h = heatmap(1:size(C,1), 1:size(C,1), C, ...
    'Colormap', parula, ...       % or use 'gray', 'hot', 'cool'
    'GridVisible', 'on');

h.Title = 'KNN Classification for Reconstructed DTMF Data';
h.XLabel = 'Predicted Class';
h.YLabel = 'True Class';

h.XDisplayLabels = string(1:size(C,1));
h.YDisplayLabels = string(1:size(C,1));

