%% THERMAL RESPONSE STUDY BRAD

clc; close all; clear;
thisFolder=fileparts(which('ThermalImaging_PC.m'));
addpath(thisFolder);
cd(thisFolder);


%% CREATE CS+ OR CS- TONE OBJECTS

SampleRate  = 10000;
TimeValue   = 10;
Samples     = 0:(1/SampleRate):TimeValue;
freqCSplus 	= 600;
freqCSminus = 350;
toneCSplus = sin(2*pi*freqCSplus*Samples);
toneCSminus = sin(2*pi*freqCSminus*Samples);

% CSplus = ones(1,20);                        % create 20 CS+ trials
% CSminus = zeros(1,20);                      % create 20 CS- trials
% randOrder =randsample([CSplus CSminus],40); % randomize trials

CSplus = ones(1,5);                        % create 20 CS+ trials
CSminus = zeros(1,5);                      % create 20 CS- trials
randOrder =randsample([CSplus CSminus],10); % randomize trials

Ttime = 8;
Stime = .5;
ITItime = 2;


%% ACQUIRE IMAGE ACQUISITION DEVICE (THERMAL CAMERA) OBJECT

% imaqtool
% vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID

utilpath = fullfile(matlabroot, 'toolbox', 'imaq', 'imaqdemos', 'helper');
addpath(utilpath);


vidObj = videoinput('winvideo', 1, 'UYVY_720x576');
% vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);
src.AnalogVideoFormat = 'ntsc_m_j';


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
vidObj.TriggerRepeat = numel(randOrder) * 3 + 3;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);



% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vidObj

%% SETUP TIMESTAMP AND FRAME-CAPTURE VARS

Frames = {};            % create thermal vid frame container
FramesTS = {};          % create thermal vid timestamp container

ThermalTime = clock;	% save timestamp
StartTime = clock;      % get timestamp


%% START MAIN EXPERIMENT LOOP

for nn = 1:numel(randOrder)                 % loop over the 40 trials


% 10-SECOND CONDITIONING TRIAL

    % PLAY CS+ OR CS- TONE
    if randOrder(nn)
        sound(toneCSplus, SampleRate); 
    else
        sound(toneCSminus, SampleRate) 
    end

    % GET THERMAL CAM SNAPSHOT
    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{end+1} = frame;
    FramesTS{end+1} = ts;

    pause(Ttime-Stime)

    % IF CS+ DELIVER SHOCK
    if randOrder(nn) 

        STT=0; tic;                 % start Shock Trial Timer (STT)
        while (STT < .5)            % for the next .5 seconds...
            disp('SHOCK!!!')        % evoke coulbourn shock device
            STT = STT + toc;        % update elapsed TrialTime
        end

    else
        pause(.5)
    end

    
% 30-SECOND ITI

    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{end+1} = frame;
    FramesTS{end+1} = ts;
    
    pause(ITItime/2)

    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{end+1} = frame;
    FramesTS{end+1} = ts;

    pause(ITItime/2)
    clc

end; % END MAIN LOOP

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

save('thermalData_S1.mat', 'Frames', 'FramesTS', 'randOrder');

return