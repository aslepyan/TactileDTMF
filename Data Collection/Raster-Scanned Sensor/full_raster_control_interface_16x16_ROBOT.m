%% Classification data
clc
clear s
clear all
close all
port = '/dev/tty.usbmodem103296801';
%port = 'COM10';
s = serialport(port,12E6); %open serial port, change for your computer
% Re run this for new data
flush(s)
%imgs = zeros(16,16,442,64); 
%times = zeros(64,442);

%%
filename = 'foam_toy_raster.mat';
close all
flush(s)
numtrials = 40;

all_trials = zeros(numtrials,256,442);
all_times = zeros(numtrials,442);
long_data = [];

for i = 1:numtrials
    input = double(split(readline(s),','));
    input = input(1:end-1); % removing /n  

    input = reshape(input, [257,442]); %257 data points, 442 time stamps
    times = input(257,:); % in microseconds, the last point %Extract all elements of 257th row
    magnitudes = input(1:256,:);

    all_trials(i,:,:) = magnitudes;
    all_times(i,:) = times;

    long_data = [long_data, magnitudes];

end

save(filename,'all_trials','all_times','long_data');
plot(squeeze(long_data)')
%% Look as animation
close all
for j = 1:length(all_trials(:,1,1))
    for i = 1:5:442
        img = squeeze(all_trials(j,:,i));
        img = reshape(img',[16 16]);
        img = rot90(img,-2);
        img(3:11,:) = flipud(img(3:11,:));

        image(fliplr(img'))
        title([num2str(j),',',num2str(i)])
        drawnow
    end
end
%% Plot
close all
for i = 1:numtrials
    plot(squeeze(all_trials(i,:,:))')
    hold on
end