%% photoresistor sensor 5 rows * 14 cols
% Collect data in 2 second intervals

clc
clear s
clear all
close all
% port = 'COM8';
port = '/dev/tty.usbmodem130787101';
baudRate = 115200;
s = serialport(port,baudRate); %open serial port, change for your computer
%% Re run this for new data
close all
flush(s)

message = ' ';
writeline(s,message); % Send message to Teensy to start

input = double(split(readline(s),','));
input = input(1:end-1); % removing /n      

num_freqs = 19;
num_points = 4082; % want this to be 2000 frames

input = reshape(input, [num_freqs+1,num_points]); %257 data points, 442 time stamps
times = input(num_freqs+1,:); % in microseconds, the last point %Extract all elements of 257th row
magnitudes = input(1:num_freqs,:);
% without pressure, magnitude are all below 200 -->
% for repetitive measurements --> if a change is detected from high value
% to low value --> record for 2 seconds... then send answers...

subplot(4,1,1)
imagesc(magnitudes(1:5,:)); colorbar
title('Rows')
subplot(4,1,2)
imagesc(magnitudes(6:end,:)); colorbar
title('Cols')
subplot(4,1,3)
plot(cumsum(times)/1e6)
ylabel('Time (sec)')
subplot(4,1,4)
imagesc(magnitudes(1:5,end)*magnitudes(6:19,end)')
%% Save the above data
filename = 'aDTMF_test.mat';
save(filename,'magnitudes','times');

%% Look as animation
mx = 0;
close all
for i = 1:4082
    mags = squeeze(magnitudes(:,i));
    rows = mags(1:5);
    cols = mags(6:end);
    img = rows*cols';
    imagesc(img.^10)
    colorbar()

    title([num2str(i)])
    drawnow
end
mx