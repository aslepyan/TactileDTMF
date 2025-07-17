%% DTMF desktop data collection visualization
load('./saved_data_ROBOT/triangle_aDTMF.mat'); % change the file name to visualize other data
for j = 1:length(all_trials(:,1,1))
    for i = 1:816
        mags = squeeze(all_trials(j,:,i));
        rows = mags(1:16);
        cols = mags(17:end);
        img = rows'*cols;
        imagesc(img)
        colorbar()

        title([num2str(j),',',num2str(i)])
        drawnow
    end
end

%% Raster scan sensor data collection visualization
load('./saved_data_ROBOT/triangle_raster.mat'); % change the file name to visualize other data
for j = 1:length(all_trials(:,1,1))
    for i = 1:442
        img = squeeze(all_trials(j,:,i));
        img = reshape(img',[16 16]);
        img = rot90(img,-2);
        img(3:11,:) = flipud(img(3:11,:));

        image(fliplr(img'))
        %image(img)
        title([num2str(j),',',num2str(i)])
        drawnow
    end
end

%% Plot the TASKA hand sensor data
load('palm2.mat');
% uncomment the following line to load the other data
% load('palm.mat');
% load('palm2.mat');
num_frames = size(frames, 3);
pause_duration = 0.05;

figure;
set(gcf, 'Position', [100, 100, 1000, 600]);

for i = 1:num_frames
    imagesc(frames(:, :, i),'AlphaData',~isnan(frames(:, :, i)));
    colorbar;
    max_val = max(frames(:, :, i), [], 'all');
    if max_val == 0
        max_val = 1e-5;
    end
    
    caxis([0, max_val]);
    title(['Frame ', num2str(i), ' of ', num2str(num_frames)]);
    drawnow;
    pause(pause_duration);
end

%% Plot photoresistive sensor data (animation)
load('photoresistor_sensor_data3.mat');
close all;

for i = 1:length(frames)
    img = frames{i};
    transformedImg = img.^10; 
    imagesc(transformedImg);
    colorbar();
    xlabel('Columns');
    ylabel('Rows');
    title(['Frame ', num2str(i)]);
    drawnow;
end

%% Plot photoresistive sensor data (static)
load('photoresistor_sensor_data2.mat');
close all;

totalMagnitudes = zeros(size(frames{1}));

for i = 1200:length(frames)
    totalMagnitudes = totalMagnitudes + frames{i};
end

totalMagnitudes(5, :) = totalMagnitudes(5, :) * 0.7;

totalMagnitudes = totalMagnitudes - min(totalMagnitudes(:)); 
totalMagnitudes = totalMagnitudes / max(totalMagnitudes(:));
totalMagnitudes = totalMagnitudes .^ 0.3; 

imagesc(totalMagnitudes);
colorbar();
xlabel('Columns');
ylabel('Rows');
title('Total Magnitudes Across All Frames');