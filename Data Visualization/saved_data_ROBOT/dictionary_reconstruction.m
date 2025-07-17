%% Dictionary based reconstruction
clear all 
close all
% add ksvd box to path
addpath 'ksvdbox13'
% add omp box to path
addpath 'ksvdbox13/ompbox10'
%% load raster scanned data
% all_trials (raster) = [40 x 256 x 442]
%             40 trials x 256 sensors x 442 frames

all_data = [];
filenames = dir;
for i = 1:length(filenames)
    if filenames(i).isdir == 0
        name = filenames(i).name;
        if contains(name,'raster')
            load(name)
            all_trials = permute(all_trials, [2 3 1]);
            object_data = reshape(all_trials, [256, 442*40]);

            all_data = [all_data, object_data];

            %cat(1,all_data,all_trials);
        end
    end
end
v = all_data;
%animate(0, 0, reshape(all_data, [16 16 512720]))
%% Learn a dictionary using KSVD on the raster scan data
close all
%all_data = v(:,1:1e4); %smaller to run faster
all_data = v;
trace = sum(all_data);
thres_value = min(trace) + range(trace) * 0.12;
indices_good = find(trace > thres_value);
good_data = all_data(:,indices_good);
%plot(trace)
%hold on
%yline(thres_value,'r')
%animate(0,0,reshape(good_data, [16 16 length(good_data)]))
%%
all_data = good_data;
sz = length(all_data(1,:));
params.data = all_data;
params.Tdata = 8; %desired sparsity
params.dictsize = 1000; %size of dictionary

[Dksvd,g,err] = ksvd(params,''); %Dksvd is dictionary by ksvd
dictimg = showdict(Dksvd,[16 16],round(sqrt(params.dictsize)),round(sqrt(params.dictsize)),'lines','highcontrast');
imagesc(dictimg)
title('Learned dictionary')
D = Dksvd;
% each tile is an element of the dictionary (consider patch based)
% consider doing x/y shift of dictionary...
%% Try reconstructing DTMF data
% all_trials (aDTMF) = [40 x 32 x 816]
%             40 trials x 32 magnitudes x 442 frames
close all
A = make_A(2,16,16);
S = 8;
for i = 1:length(filenames)
    if filenames(i).isdir == 0
        name = filenames(i).name;
        if contains(name,'aDTMF')
            name
            load(name)
            reconDTMF = zeros(40,256,816);
            for j = 1:length(all_trials(:,1,1))
                trial = squeeze(all_trials(j,:,:));
                for k = 1:length(trial(1,:))
                    frame = trial(:,k);
                    x_hat = D*OMP_tran(A*D,frame,S);
                    reconDTMF(j,:,k) = x_hat;
                end
            end
            save([name(1:end-4),'_recon.mat'],'reconDTMF','all_times')
        end
    end
end
%% Calculate MSE
% mse = 0; 
% for i = 1:length(recon(1,:))
%     j = ceil(i * length(all_data(1, :)) / length(recon(1, :)));
%     mse = mse + mean((all_data(1:256,j) - recon(1:256, i)).^2);
% end
% mse = mse / length(all_data(1,:));
% disp(['MSE for DTMF data: ', num2str(mse)])

%%
%% Adding some common dictionaries (optional)
load('patternRBIO33_2D.mat')
D = D(:,:,257:384); %remove some elements
D = reshape(D, [256 length(D(1,1,:))]);
D = [D, eye(256)]; %adding identity matrix
%D = normc(D);
D = [Dksvd,D];

%%
trial_to_plot = 1; % Choose the trial number to visualize
    figure;
    for k = 1:20:size(reconDTMF, 3)
        % Reshape the frame for plotting (assuming it represents a 16x16 grid)
        frame_data = reshape(reconDTMF(trial_to_plot, :, k), [16, 16]);
        
        % Plot the frame
        imagesc(frame_data);
        colormap;
        colorbar;
        title(['Reconstructed Frame ', num2str(k)]);
        pause(0.1); % Pause to create an animation effect
    end