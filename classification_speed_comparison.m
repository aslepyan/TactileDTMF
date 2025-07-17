% DTMF sensor data
dataFolder = 'saved_data_ROBOT';
dataFiles = dir(fullfile(dataFolder, '*_aDTMF.mat'));

num_objects = length(dataFiles);            
num_experiments_per_object = 40;                                             

allAccuracies_DTMF = []; 
frame_range = 1:36; 

for num_frames_to_select = frame_range
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
    Y = labels;             

    if isempty(X) || isempty(Y)
        allAccuracies_DTMF(end+1) = NaN;
        continue;
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

    allAccuracies_DTMF(end+1) = object_accuracy;
end

% Raster scan sensor data
dataFolder = 'saved_data_ROBOT';
dataFiles = dir(fullfile(dataFolder, '*_raster.mat'));

num_objects = length(dataFiles);            
num_experiments_per_object = 40;            
sensor_grid_size = 256;                                   

allAccuracies_raster = []; 
frame_range = 1:20; 

for num_frames_to_select = frame_range
    allData = {}; 
    labels = [];   

    for i = 1:num_objects
        fileName = fullfile(dataFolder, dataFiles(i).name);
        loadedData = load(fileName);
        objectData = loadedData.all_trials; % [40 x 256 x 442]

        for j = 1:num_experiments_per_object
            trialData = squeeze(objectData(j, :, :)); % [256 x 442]

            trialData = trialData'; % [442 x 256]

            frame_magnitudes = sum(abs(trialData), 2); % [442 x 1]
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
                original_frame = trialData(frame_idx, :); % [1 x 256]

                if sum(abs(original_frame)) < thres_low_mag
                    original_frame= zeros(size(original_frame));
                end

                downsampled_vector = original_frame;
                allData{end+1} = downsampled_vector;
                
                labels(end+1, 1) = i;
            end
        end
    end

    X = cell2mat(allData');
    Y = labels;  

    if isempty(X) || isempty(Y)
        allAccuracies_raster(end+1) = NaN;
        continue;
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

    allAccuracies_raster(end+1) = object_accuracy;
end

%% Combined Plot
freq_raster = 221;
freq_DTMF = 408;

time_raster = (0:length(allAccuracies_raster) - 1) / freq_raster;
time_dtmf = (0:length(allAccuracies_DTMF) - 1) / freq_DTMF; 

figure;
plot(time_raster, allAccuracies_raster, '-o', 'DisplayName', 'Raster Scan (221 Hz)');
hold on;
plot(time_dtmf, allAccuracies_DTMF, '-s', 'DisplayName', 'DTMF (408 Hz)');
hold off;

xlabel('Time (seconds)');
ylabel('Classification Accuracy (%)');
title('Classification Speed Comparison for Raster Scan and DTMF Sensors');
legend('show');
grid on;
