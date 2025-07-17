clc
clear all
close all
clear vars

s = serialport(serialportlist, 12E6);

% Define finger mappings for rows and columns
finger_mapping = struct(...
    'thumb', struct('rows', [31, 32, 33], 'cols', [20, 21, 22]), ...
    'index', struct('rows', [20, 21, 22], 'cols', [1, 2, 3]), ...
    'middle', struct('rows', [20, 21, 22], 'cols', [6, 7, 8]), ...
    'ring', struct('rows', [20, 21, 22], 'cols', [12, 13, 14]), ...
    'pinky', struct('rows', [20, 21, 22], 'cols', [17, 18, 19]));

% Define palm mapping in a specific section of the 14x22 grid
palm_rows = 23:1:33;
palm_columns = 1:1:19;

figure;
set(gcf, 'Position', [100 100 1000 600]);

% Initialize data storage for 800 frames
num_frames = 1600;
frames = NaN(15, 23, num_frames); % 3D matrix to store each frame
frame_count = 0;

while frame_count < num_frames
    try
        % Read a line with 408 frames of data
        data_line = readline(s);
        split = strsplit(data_line, ',');

        % Check if we have enough data points for 408 frames (34 values per frame)
        if length(split) < 408 * 34
            warning('Incomplete data line, skipping...');
            continue;
        end

        % Process each frame from the line
        for i = 1:408
            % Extract the first 33 values for the current frame, ignoring the 34th value
            vals = str2double(split((i - 1) * 34 + 1 : i * 34 - 1));

            % Calculate max_mag as the product of the two highest magnitudes in vals
            sorted_vals = sort(abs(vals), 'descend');
            max_mag = sorted_vals(1) * sorted_vals(2);

            % Initialize a 15x23 main matrix for displaying all values
            main_matrix = NaN(15, 23);

            % Place each finger matrix into the main_matrix based on its mapping
            main_matrix([13, 14, 15], [1, 2, 3]) = ...
                get_finger_matrix(finger_mapping.thumb.rows, finger_mapping.thumb.cols, vals);

            main_matrix([1, 2, 3], [5, 6, 7]) = ...
                get_finger_matrix(finger_mapping.index.rows, finger_mapping.index.cols, vals);

            main_matrix([1, 2, 3], [10, 11, 12]) = ...
                get_finger_matrix(finger_mapping.middle.rows, finger_mapping.middle.cols, vals);

            main_matrix([1, 2, 3], [16, 17, 18]) = ...
                get_finger_matrix(finger_mapping.ring.rows, finger_mapping.ring.cols, vals);

            main_matrix([1, 2, 3], [21, 22, 23]) = ...
                get_finger_matrix(finger_mapping.pinky.rows, finger_mapping.pinky.cols, vals);

            % Create palm matrix and place it into the designated section of main_matrix
            palm_matrix = zeros(11, 19);
            for r = 1:11
                for c = 1:19
                    palm_matrix(r, c) = vals(palm_rows(r)) * vals(palm_columns(c));
                end
            end
            main_matrix(5:1:15, 5:1:23) = palm_matrix;
            main_matrix(13:1:15, 5:1:15) = NaN;

            % Save the current frame to frames array
            frame_count = frame_count + 1;
            frames(:, :, frame_count) = main_matrix;

            % Exit if we have collected the required 800 frames
            if frame_count >= num_frames
                break;
            end
        end

        % Display the last processed frame
        if frame_count <= num_frames
            imagesc(main_matrix);
            colorbar;
            caxis([0 max_mag]);
            title('15x23 Matrix Representation of Hand Sensor Data');
            drawnow;
        end

    catch
        warning('Error reading data or processing frames, resetting connection');
        s = serialport('COM5', 12E6);
    end
end

% Save the collected frames as a .mat file
save('palm2.mat', 'frames');
