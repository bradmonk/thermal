%% THERMAL RESPONSE STUDY SCOTT

%%%%%% This script is for Day 1 of the fear conditioning experiment %%%%%%
close all; clear 

% Delete any active connection with the device
imaqreset

% Randomize the seed
rand('seed',sum(100*clock));

% cd(fileparts(which(mfilename)));
this=fileparts(which('ThermalResponseStudy_Scott.m')); 
addpath(this); cd(this);

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

%% Experiment parameters
shock_dur = 0.5;
SampleRate = 10000;
TimeValue = 2;
TimeValueShock = TimeValue - 0.5;
Samples = 0:(1/SampleRate):TimeValue;
freqS1 = 600;
freqS2 = 350;
toneS1 = sin(2*pi*freqS1*Samples);
toneS2 = sin(2*pi*freqS2*Samples);
ITI = 2;

% Is there a shock or not?
shock = 0;

% Initialize shock
if shock == 1
    send_to_coulbourn('init');
end

keypad_index = 0;

% Child Protection
AssertOpenGL;

%% Make Dataset
trial_data = dataset();

% Trial numbers
acq_trials = 4;
ext_trials = 4;
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

%% ACQUIRE IMAGE ACQUISITION DEVICE (THERMAL CAMERA) OBJECT

% imaqtool
% vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID

utilpath = fullfile(matlabroot, 'toolbox', 'imaq', 'imaqdemos', 'helper');
addpath(utilpath);
vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720');
% vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
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
% vidObj.ReturnedColorspace = 'rgb';
% vidObjSource = vidObj.Source;
% preview(vidObj);    pause(3);   stoppreview(vidObj);
% TriggerRepeat is zero-based
vidObj.TriggerRepeat = total_trials * 3 + 3;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vidObj

% Once a key is pressed, the experiment will begin
main_keyboard_index = input_device_by_prompt('Please press any key on the main keyboard\n', 'keyboard');
disp('Starting experiment now...');

Frames = {};            % create thermal vid frame container
FramesTS = {};          % create thermal vid timestamp container
startTime = GetSecs;

%% Start trial loop
for trial = 1:length(trial_data)
    
    % Get exact timing of the ITI start
    trial_data.ITI_start(trial,1) = GetSecs;
    trial_data.ITI_start_real(trial,1) = trial_data.ITI_start(trial,1) - startTime;    
    
    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{end+1} = frame;
    FramesTS{end+1} = ts;
    
    WaitSecs(ITI/2);

    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{end+1} = frame;
    FramesTS{end+1} = ts;

    WaitSecs(ITI/2);
    
    cls
    
    % Get exact timing of the ITI end 
    trial_data.ITI_end(trial,1) = GetSecs;
    trial_data.ITI_end_real(trial,1) = trial_data.ITI_end(trial,1) - startTime;

    % Get the exact duration of the ITI period
    trial_data.ITI_time(trial,1) = trial_data.ITI_end(trial,1) - trial_data.ITI_start(trial,1);
    
    % Get the exact timing of the tone start
    trial_data.tone_start(trial,1) = GetSecs;
    fprintf('Tone %d beginning...\n', trial);
    trial_data.tone_start_real(trial,1) = trial_data.tone_start(trial,1) - startTime;
    
    % Present the sound
    if strcmp(trial_data.stim(trial,1),'S1')
        sound(toneS1, SampleRate);
        % GET THERMAL CAM SNAPSHOT
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        Frames{end+1} = frame;
        FramesTS{end+1} = ts;
        while GetSecs < trial_data.tone_start(trial,1) + TimeValue
            if strcmp(trial_data.phase(trial,1),'Acquisition')
                while GetSecs > trial_data.tone_start(trial,1) + TimeValueShock & GetSecs < trial_data.tone_start(trial,1) + TimeValue
                    fprintf('Shock ON!\n');
                end
            end
        end
        if strcmp(trial_data.phase(trial,1),'Acquisition')
            fprintf('----------Shock OFF----------\n');
        end
    else
        sound(toneS2, SampleRate);
        % GET THERMAL CAM SNAPSHOT
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        Frames{end+1} = frame;
        FramesTS{end+1} = ts;
        while GetSecs < trial_data.tone_start(trial,1) + TimeValue
        end
    end

    % Get the exact timing of the tone end
    trial_data.tone_end(trial,1) = GetSecs;
    trial_data.tone_end_real(trial,1) = trial_data.tone_end(trial,1) - startTime;

    % Get the exact duration of the tone period
    trial_data.tone_time(trial,1) = trial_data.tone_end(trial,1) - trial_data.tone_start(trial,1);
    
    %% Save data
    outfile=sprintf('FC_NEW_Day1_s%s_%s.mat', subject_id, date);
    save([sub_dir, '/' outfile],'trial_data');
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

%% Save data
outfile=sprintf('FC_NEW_Day1_s%s_%s.mat', subject_id, date);
save([sub_dir, '/' outfile],'trial_data', 'Frames', 'FramesTS');

return





