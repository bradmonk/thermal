%% Thermal Response Study
clc; close all; clear;

this=fileparts(which('ThermalResponseStudy.m')); addpath(this); cd(this);

%%

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

% FLIR Tau 640 longwave infrared (thermographic) imaging camera LWIR
cam = webcam;                               % get webcam

vidWriter = VideoWriter('ThermalDataSub1.avi');
open(vidWriter);
writeVideo(vidWriter, snapshot(cam));

ThermalTime = clock;                        % save timestamp
StartTime = clock;                          % get timestamp

% for nn = 1:numel(randOrder)                 % loop over the 40 trials
for nn = 1:1                 % loop over the 40 trials

    if randOrder(nn)
        sound(toneCSplus, SampleRate); 
    else
        sound(toneCSminus, SampleRate) 
    end

    TrialTime=0; tic;                           % start Trial Timer
    while (TrialTime < 10)                      % for the next 10 seconds...
        writeVideo(vidWriter, snapshot(cam));   % save thermal cam data
        ThermalTime(end+1,:) = clock;           % save timestamp
        pause(.05)

        if mod(TrialTime,100); disp(TrialTime); end
        if (TrialTime > 9.5) && randOrder(nn) 
            disp('SHOCK!!!')
        end

        TrialTime = TrialTime + toc;        % update elapsed TrialTime
    end
    %toc


    ITITime=0; tic;                    % start ITI Timer
    while (ITITime < 30)                    % for the next 30 seconds...
        writeVideo(vidWriter, snapshot(cam)); % save thermal cam data
        ThermalTime(end+1,:) = clock;         % save timestamp
        
        pause(.05)
        if mod(ITITime,100); disp(ITITime); end
        ITITime = ITITime + toc;            % update elapsed ITI Time
    end
    % toc;
end

close(vidWriter);
save('OrderDataSub1.mat','randOrder')
save('ThermalTimeSub1.mat','ThermalTime')
clear cam

%%
return

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





% ----------------------------------------------------------------
%% NOTES


%{

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
















