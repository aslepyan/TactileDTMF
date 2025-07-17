%% aDTMF sensor matrix 16x16 ROBOT Collection
% Collect data in 2 second intervals using Robot
clc
clear s
clear all
close all
port = 'COM5';
% port = '/dev/tty.usbmodem130787101';
s = serialport(port,12E6); %open serial port, change for your computer
%% Re run this for new data
close all
flush(s)
numtrials = 1;
num_freqs = 32;
num_points = 816;

all_trials = zeros(numtrials,32,num_points);
all_times = zeros(numtrials, num_points);

for i = 1:numtrials
    input = double(split(readline(s),','));
    input = input(1:end-1); % removing /n  

    input = reshape(input, [num_freqs+1,num_points]); %257 data points, 442 time stamps
    times = input(num_freqs+1,:); % in microseconds, the last point %Extract all elements of 257th row
    magnitudes = input(1:num_freqs,:);
    % magnitudes = [zeros(1,816); magnitudes];

    all_trials(i,:,:) = magnitudes;
    all_times(i,:) = times;

end

filename = 'round_object_verysmall.mat';
save(filename,'all_trials','all_times');

%% Look as animation
close all
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