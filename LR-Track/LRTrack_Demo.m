function LRTrack_Demo()
% This is an example code for the Low-Rank Sparse Tracking published in the following paper:
% Tianzhu Zhang, Bernard Ghanem, Si Liu, Narendra Ahuja."Low-Rank Sparse Learning for Robust Visual Tracking", 
% ECCV, 2012.
% If you use the code and compare with our LRST trackers, please cite the above  papers.

clc;clear all;close all;
addpath('LRT_Toolbox');

% %% video frames
video_name = 'people2';
video_path = fullfile('.\data\',video_name);
m_start_frame = 1;  %starting frame number
nframes		= 30; %393;	 %number of frames to be tracked
Imgext		= 'jpg';				%image format
numzeros	= 1;	%number of digits for the frame index
all_images	= cell(nframes,1);
nz			= strcat('%0',num2str(numzeros),'d'); %number of zeros in the name of image
for t=1:nframes
    image_no	= m_start_frame + (t-1);
    fid			= sprintf(nz, image_no);
    all_images{t}	= strcat(video_path,'\',fid,'.',Imgext);
end

%% initialize bounding box
% m_boundingbox = [75,129,25,19];  % [left-top-x, left-top-y, width, height];
% init_pos = [m_boundingbox(2)   m_boundingbox(2)+m_boundingbox(4)  m_boundingbox(2) ;
%             m_boundingbox(1)   m_boundingbox(1)                   m_boundingbox(1)+m_boundingbox(3)];

init_pos	= SelectTarget(all_images{1});  % automatically get bounding box
m_boundingbox = [init_pos(2,1) init_pos(1,1) init_pos(2,3)-init_pos(2,2) init_pos(1,2)-init_pos(1,1)];
% init_pos =  [p1 p2 p3];
% 			  p1-------------------p3
% 				\					\
% 				 \       target      \
% 				  \                   \
% 				  p2-------------------\  
opt.init_pos = double(init_pos);  %  initialization bounding box

width = m_boundingbox(3);
height = m_boundingbox(4);
%% 	set object size including height and width based on the initialization		
if min( 0.5*[height width]) < 25
    sz_T = 1.0 * [height width];
    if height > 80
        sz_T =  [ 0.5 *height width];  
    end
else
    sz_T = 0.5 * [height width];
end
sz_T = ceil(sz_T);
if min(sz_T>32)
    sz_T = [32 32];
end


%% LRT tracking Parameters
opt.n_sample = 400;		% number of particles   400
opt.sz_T= sz_T;         % object size
%opt.tracker_type = 'L21';  opt.lambda = 0.01; % three different trackers: L21, L11, L01(denote L\infinity 1);
% opt.tracker_type = 'L11';  opt.lambda = 0.005;
% opt.tracker_type = 'L01';  opt.lambda = 0.2;
% opt.eta  = 0.01;
% opt.obj_fun_th = 1e-3;
% opt.iter_maxi = 100; % lambda, eta,obj_fun_th, and iter_maxi are parameters for Accelerated Proximal Gradient (APG) Optimization. Please refer to our paper for details.
opt.rel_std_afnv =  [0.005,0.0005,0.0005,0.005,4,4]; % affine parameters for particle sampling

opt.lambda = [1 1 1];
opt.m_theta = 0.7;  % [0 1] decide object template update
% opt.show_optimization = false; % show optimization results to help tue eta and lambda for APG optimization.
% opt.show_time = true; % show optimization speed

%% Run LRT tracking. To get better results for different videos, we can change sz_T, rel_std_afnv, lambda, and m_theta.
% m_track: tracking result;

[tracking_res] = LRT_Tracking(all_images,opt);


%% Save tracking results
all_results_path = '.\LRT_Results\';
if ~exist([all_results_path video_name])
    mkdir([all_results_path video_name]);
end
all_rect = [];
for t = 1:nframes
    img_color	= imread(all_images{t});
    img_color	= double(img_color);
    imshow(uint8(img_color));
    text(5,10,num2str(t),'FontSize',18,'Color','r');
    color = [1 0 0];
    map_afnv	= tracking_res(:,t)';
    rect=drawAffine(map_afnv, sz_T, color, 2);
    all_rect =[all_rect; rect(2,1) rect(1,1) rect(2,3)-rect(2,1) rect(1,2)-rect(1,1)];
    
    s_res	= all_images{t}(1:end-4);
    s_res	= fliplr(strtok(fliplr(s_res),'/'));
    s_res	= fliplr(strtok(fliplr(s_res),'\'));
    s_res	= [s_res '_LRT.png'];
    f = getframe(gcf);
    imwrite(uint8(f.cdata), [all_results_path video_name '\' s_res]);
end


