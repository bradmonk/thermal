%% THERMAL RESPONSE STUDY BRAD

clc; close all; clear;
thisFolder=fileparts(which('ThermalResponseStudy_v2.m')); 
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

CSplus = ones(1,20);                        % create 20 CS+ trials
CSminus = zeros(1,20);                      % create 20 CS- trials
randOrder =randsample([CSplus CSminus],40); % randomize trials



%% ACQUIRE IMAGE ACQUISITION DEVICE (THERMAL CAMERA) OBJECT

% imaqtool
vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID
vidsrc = getselectedsource(vidObj);
diskLogger = VideoWriter([thisFolder '/thermalVid1.avi'],'Uncompressed AVI');
vidObj.LoggingMode = 'disk&memory';
vidObj.DiskLogger = diskLogger;
vidObj.ROIPosition = [488 95 397 507];
vidObj.ReturnedColorspace = 'rgb';
vidObjSource = vidObj.Source;

% preview(vidObj);    pause(3);   stoppreview(vidObj);

% TriggerRepeat is zero-based
vidObj.TriggerRepeat = numel(randOrder) * 3 + 3;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);


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

    pause(9.5)

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
    
    pause(15)

    trigger(vidObj);
    [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
    Frames{end+1} = frame;
    FramesTS{end+1} = ts;

    pause(15)
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

%% NOTES

%{

%% -- PLAYBACK THERMAL VIDEO


ThermalDataVid = VideoReader('ThermalDataSub1.avi');
get(ThermalDataVid)
vidWidth = ThermalDataVid.Width;
vidHeight = ThermalDataVid.Height;

mov = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

k = 1;
while hasFrame(ThermalDataVid)
    mov(k).cdata = readFrame(ThermalDataVid);
    k = k+1;
end

hf = figure;
set(hf,'position',[150 150 vidWidth vidHeight]);
movie(hf,mov,1,ThermalDataVid.FrameRate);

%% -- ANALYZE THERMAL VIDEO DATA (TBD)

Img_F1 = mov(1).cdata;
Img_F1_dub = im2double(frame1);
Img_F1_flat = (Img_F1_dub(:,:,1) + Img_F1_dub(:,:,2) + Img_F1_dub(:,:,3)) ./ 3;

    fh1 = figure; set(fh1,'position',[150 50 vidWidth vidHeight*2],'Color','w');
    hax1=axes('Position',[.05 .52 .95 .45],'Color','none');
    hax2=axes('Position',[.05 .05 .95 .45],'Color','none');
    
    axes(hax1)
image(Img_F1);  % imshow(Img_F1);
    set(hax1,'XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[])

    axes(hax2)
imagesc(Img_F1_flat); colormap(bone);
    set(hax1,'XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[])



%------------------------
clc; close all; clear
thisFolder=fileparts(which('ThermalResponseStudy.m'));

% imageDevicesInfo = imaqhwinfo;    % info about all system image acquisition devices
% devs = instrhwinfo('serial')

vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720');
vidsrc = getselectedsource(vidObj);
diskLogger = VideoWriter([thisFolder '/thermalVid1.avi'],'Uncompressed AVI');
vidObj.LoggingMode = 'disk&memory';
vidObj.DiskLogger = diskLogger;
vidObj.ROIPosition = [488 95 397 507];
vidObj.ReturnedColorspace = 'rgb';
vidObjSource = vidObj.Source;


% preview(vidObj);    pause(3);   stoppreview(vidObj);


% TriggerRepeat is zero-based (i.e. one less than number of triggers)
vidObj.TriggerRepeat = 9;
vidObj.FramesPerTrigger = 1;


% triggerinfo(v)
% trigger(vidObj) is only valid when TriggerType is set to manual.
% if triggerconfig(vidObj,'manual'); trigger(vidObj); end

% triggerconfig(vidObj, 'immediate');
triggerconfig(vidObj, 'manual');

% The trigger function can be called by a video input object's event callback.
% vidObj.StartFcn = @trigger;

% When an acquisition is started, obj performs the following operations:
% 
% 1. Transfers the object's configuration to the associated hardware.
% 2. Executes the object's StartFcn callback.
% 3. Sets the object's Running property to 'On'.
%
% If the object's StartFcn errors, the hardware is never started 
% and the object's Running property remains 'Off'.
% 
% The start event is recorded in the object's EventLog property.
% 
% An image acquisition object stops running when one of the following conditions is met:
% 
% 1. The stop function is issued.
% 2. The requested number of frames is acquired. This occurs when
% 3. FramesAcquired = FramesPerTrigger * (TriggerRepeat + 1)
%    where FramesAcquired, FramesPerTrigger, and TriggerRepeat 
%    are properties of the video input object.
% 4. A run-time error occurs.
% 5. The object's Timeout value is reached.

start(vidObj);
for nn = 1:vidObj.TriggerRepeat

    trigger(vidObj);
    [frames, ts] = getdata(vidObj, vidObj.FramesPerTrigger);

    vid{nn} = frames;

    pause(.01)
end
stop(vidObj); wait(vidObj);

close all
for nn = 1:vidObj.TriggerRepeat
    figure(1)
    imagesc(vid{nn})
        axis image
        drawnow
        pause(.1)
end

save('thermalVid1.mat', 'vid');


%}

%{


% stop(vidObj)
% vid = getdata(vidObj);
% imagesc(vid(:,:,1:3))
%     axis image
% save('thermalVid1.mat', 'vid');
% clear vidObj;


%%
% Visualization
figure(1)
vv=0;
while (vv < vidObj.FramesPerTrigger)

    imagesc(peekdata(vidObj,1));
    caxis([49000 52000]);
    pause(0.1);

    vv=vidObj.FramesAcquired;
end
% waitDuration = 10;
% wait(vidObj, waitDuration);getdata function

% get frames and relative timestamps
[frames, ts] = getdata(vidObj, vidObj.FramesPerTrigger);


figure; % Plot frame timestamps
plot(ts, '.');

stop(vidObj)



%%---------

clc; close all; clear all; instrreset;

devs = instrhwinfo('serial')

devs.SerialPorts


imaqreset; clc; close all; clear;


% OUT = imaqhwinfo;
% vidObj = videoinput('macvideo', 1);
vidObj = videoinput('macvideo', 1);

vidObj.SelectedSourceName = 'iSightMac'

vidObjSource = vidObj.Source;

% triggerinfo(v)
triggerconfig(vidObjSource, 'manual');
% triggerconfig(v, 'immediate');

samplenr=10;
vidObj.FramesPerTrigger = samplenr;
vidObj.TriggerRepeat = 1;


% start videoinput and wait for acquisition to complete
start(vidObj);

% % If triggerconfig(v,'manual'): 
% % trigger(v) is only valid when TriggerType is set to manual.
pause(2);
trigger(vidObj);



% Visualization
figure(1)
i=0;
while (i<samplenr)

imagesc(peekdata(vidObj,1));
caxis([49000 52000]);
pause(0.1);

i=vidObj.FramesAcquired;
end
% waitDuration = 10;
% wait(vidObj, waitDuration);getdata function

% get frames and relative timestamps
[frames, ts] = getdata(vidObj, vidObj.FramesPerTrigger);

% Plot frame timestamps
figure;
plot(ts, '.');

stop(v)

%}
