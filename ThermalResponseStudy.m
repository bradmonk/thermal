%% THERMAL RESPONSE STUDY SCOTT

%%%%%% This script is for Day 1 of the fear conditioning experiment %%%%%%
clc; close all; clear all;
thisFolder=fileparts(which('ThermalResponseStudy.m'));
% addpath(thisFolder);
cd(thisFolder);

% Delete any active connection with the device
imaqreset

% Randomize the seed
rand('seed',sum(100*clock));

% Enter subject number info
subject_id = input('What is the subject number? ');
subject_id = sprintf('%d',subject_id);
sub_dir = [pwd,'/data/', 's' subject_id];

if ~exist(sub_dir)

  warn1 = sprintf(' Execution aborted. Subdirectory ''./data\'' not found \n');
  warn2 = sprintf(' Potential reasons for error: \n');
  warn3 = sprintf('   1. You are currently in the wrong working directory \n');
  warn4 = sprintf('   2. You have not created a subject folder: ''./data\'' \n');
  error([warn1 warn2 warn3 warn4])

end

send_to_daq('initialize');

%% Experiment parameters
% shock_dur = 0.5;
SampleRate = 10000;
TimeValue = 4;
TimeValueShock = TimeValue - 0.5;
Samples = 0:(1/SampleRate):TimeValue;
freqS1 = 600;
freqS2 = 350;
toneS1 = sin(2*pi*freqS1*Samples);
toneS2 = sin(2*pi*freqS2*Samples);
ITI = 10;

% Is there a shock or not?
shock = 1;

% Initialize shock
if shock == 1
    send_to_daq('initialize'); % send to EMG recording machine           
end

keypad_index = 0;

% Child Protection
AssertOpenGL;

%% Make Dataset
trial_data = dataset();

% Trial numbers
acq_trials = 60;
ext_trials = 40;
total_trials = acq_trials + ext_trials;

% Create trials
trial_data.trial(1:total_trials,1) = 1:total_trials;

% Specify phase
trial_data.phase(1:acq_trials,1) = {'Acquisition'};
trial_data.phase(acq_trials+1:total_trials,1) = {'Extinction'};

trial_data.phase_num(1:acq_trials,1) = 1;
trial_data.phase_num(acq_trials+1:total_trials,1) = 2;

% Create balanced number of CS+ and CS-
for i = 1:2:length(trial_data)
    trial_data.stim(i:2:length(trial_data),1) = 1;
    trial_data.stim(i+1:2:length(trial_data),1) = 0;
end

shock_trials = 1:2:(acq_trials * 1/2);
for i = 1:total_trials
    if intersect(trial_data.trial(i,1),shock_trials)
        trial_data.shock(i,1) = 1;
    else
        trial_data.shock(i,1) = 0;
    end
end

for i = 1:total_trials
    if trial_data.stim(i,1) == 0
        trial_data.trial_type(i,1) = 1; % CS- trials
    elseif trial_data.stim(i,1) == 1 && trial_data.shock(i,1) == 1 
        trial_data.trial_type(i,1) = 2; % CS+ paired trials
    else
        trial_data.trial_type(i,1) = 3; % CS+ unpaired trials
    end
end        

% Randomize with constraints (no more than 3 CS+ or 3 CS- in a row)
for phase_num = 1:2
    while true
        mix = randperm_chop(trial_data(trial_data.phase_num==phase_num,:));
        [streak_start, S1] = find_longest_streak(mix.stim == 1);
        [streak_start, S2] = find_longest_streak(mix.stim == 0);
        if S1 < 4 && S2 < 4
            break
        end
    end
    trial_data(trial_data.phase_num==phase_num,:) = mix;
end

trial_data.trial(1:length(trial_data)) = 1:length(trial_data);

FrameOrd = []; % Frame order vec
CSm = [1 2 3 4 5 6 7 8]; % CS- codes
CSpp = [9 10 11 12 13 14 15 16]; % CS+ paired codes
CSpu = [17 18 19 20 21 22 23 24]; % CS+ unpaired codes

% 1 = CS-; 2 = CS+ paired; 3 = CS+ unpaired
for i = 1:acq_trials
    if trial_data.trial_type(i,1) == 1 % CS- trials
        FrameOrd = [FrameOrd CSm];
    elseif trial_data.trial_type(i,1) == 2 % CS+ paired trials
        FrameOrd = [FrameOrd CSpp];
    else % CS+ unpaired trials
        FrameOrd = [FrameOrd CSpu];
    end
end

%% ACQUIRE IMAGE ACQUISITION DEVICE (THERMAL CAMERA) OBJECT

% imaqtool
% vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID

utilpath = fullfile(matlabroot, 'toolbox', 'imaq', 'imaqdemos', 'helper');
addpath(utilpath);
% vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720');
vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);
% src.AnalogVideoFormat = 'ntsc_m_j';

% vidObj.FramesPerTrigger = 1;
% preview(vidObj);
% start(vidObj);
% pause(5)
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vid src
% vidsrc = getselectedsource(vidObj);
% diskLogger = VideoWriter([thisFolder '/thermalVid1.avi'],'Uncompressed AVI');
vidObj.LoggingMode = 'memory';
% vidObj.DiskLogger = file;
% vidObj.ROIPosition = [488 95 397 507];
vidObj.ReturnedColorspace = 'rgb';
% vidObjSource = vidObj.Source;
% preview(vidObj);    pause(3);   stoppreview(vidObj);
% TriggerRepeat is zero-based
vidObj.TriggerRepeat = total_trials * 6 + 6;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vidObj

% Once a key is pressed, the experiment will begin
% main_keyboard_index = input_device_by_prompt('Please press any key on the main keyboard\n', 'keyboard');
disp('Starting experiment now...');


Frames{1} = uint8(zeros(480,720,3));
for nn = 1:length(trial_data)*8
    Frames{nn} = uint8(zeros(480,720,3));
end

Frames = {};            % create thermal vid frame container
FramesTS = {};          % create thermal vid timestamp container
startTime = GetSecs;
ff=1;
%% Start trial loop
for trial = 1:length(trial_data)
    
    % Allows time to get movie setup
    if trial == 1
      pause(10);
    end
    
    % Get the exact timing of the tone start
    trial_data.tone_start(trial,1) = GetSecs;
    fprintf('Tone %d beginning...\n', trial);
    trial_data.tone_start_real(trial,1) = trial_data.tone_start(trial,1) - startTime;
    
    % Present the sound
    if trial_data.stim(trial,1) == 1
        sound(toneS1, SampleRate);
        % GET THERMAL CAM SNAPSHOT
        pause(1)
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        Frames{ff} = frame; ff=ff+1;
        FramesTS{end+1} = ts;
        pause(1)
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        Frames{ff} = frame; ff=ff+1;
        FramesTS{end+1} = ts;
        pause(1)
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        Frames{ff} = frame; ff=ff+1;
        FramesTS{end+1} = ts;
        
        while GetSecs < trial_data.tone_start(trial,1) + TimeValue  
        end
        if strcmp(trial_data.phase(trial,1),'Acquisition') && shock == 1 && trial_data.shock(trial,1) == 1
            send_to_daq('solenoid_1',.015);
        end
    else
        sound(toneS2, SampleRate);
        % GET THERMAL CAM SNAPSHOT
       pause(1)
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        Frames{ff} = frame; ff=ff+1;
        FramesTS{end+1} = ts;
        pause(1)
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        Frames{ff} = frame; ff=ff+1;
        FramesTS{end+1} = ts;
        pause(1)
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        Frames{ff} = frame; ff=ff+1;
        FramesTS{end+1} = ts;
        while GetSecs < trial_data.tone_start(trial,1) + TimeValue
        end
    end

    % Get the exact timing of the tone end
    trial_data.tone_end(trial,1) = GetSecs;
    trial_data.tone_end_real(trial,1) = trial_data.tone_end(trial,1) - startTime;

    % Get the exact duration of the tone period
    trial_data.tone_time(trial,1) = trial_data.tone_end(trial,1) - trial_data.tone_start(trial,1);
    
    % Get exact timing of the ITI start
    trial_data.ITI_start(trial,1) = GetSecs;
    trial_data.ITI_start_real(trial,1) = trial_data.ITI_start(trial,1) - startTime;    
    
    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{ff} = frame; ff=ff+1;
    FramesTS{end+1} = ts;
    
    pause(ITI/4);
    
    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{ff} = frame; ff=ff+1;
    FramesTS{end+1} = ts;
    
    pause(ITI/4);

    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{ff} = frame; ff=ff+1;
    FramesTS{end+1} = ts;

    pause(ITI/4);
    
    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{ff} = frame; ff=ff+1;
    FramesTS{end+1} = ts;
    
    pause(ITI/4);

    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{ff} = frame; ff=ff+1;
    FramesTS{end+1} = ts;    
        
    % Get exact timing of the ITI end 
    trial_data.ITI_end(trial,1) = GetSecs;
    trial_data.ITI_end_real(trial,1) = trial_data.ITI_end(trial,1) - startTime;

    % Get the exact duration of the ITI period
    trial_data.ITI_time(trial,1) = trial_data.ITI_end(trial,1) - trial_data.ITI_start(trial,1);

    %% Save data
    if mod(trial,10)==0
        outfile=sprintf('FC_Day1_s%s_%s.mat', subject_id, date);
        save([sub_dir, '/' outfile],'trial_data', 'Frames', 'FramesTS', 'FrameOrd');
    end
end

stop(vidObj); wait(vidObj);

%% PLAYBACK THERMAL VIDEO FRAMES & SAVE DATA
close all
for nn = 1:numel(Frames)
    figure(1)
    imagesc(Frames{nn})
    axis image
    drawnow
    pause(.1)
end

