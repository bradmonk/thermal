%% THERMAL RESPONSE STUDY ThermalResponseStudy_Brad.m

clc; close all; clear;
thisFolder=fileparts(which('ThermalResponseStudy_Brad.m'));
addpath(thisFolder);
cd(thisFolder);


%% TRIALS AND TIMING

ITItime = 24.0;         % default = 24
TRtime  = 8.0;          % default = 8
SHtime  = 0.5;          % default = .5

CSplus_nTrials  = 15;   % default = 15
CSminus_nTrials = 15;   % default = 15

TotTrials = CSplus_nTrials + CSminus_nTrials;
CSplus    = ones(1,CSplus_nTrials);                % create 20 CS+ trials
CSminus   = zeros(1,CSplus_nTrials);               % create 20 CS- trials
randOrder =randsample([CSplus CSminus],TotTrials); % randomize trials


%% CREATE CS+ OR CS- TONE OBJECTS

SampleRate  = 10000;
TimeValue   = TRtime;
Samples     = 0:(1/SampleRate):TimeValue;
freqCSplus 	= 600;
freqCSminus = 350;
toneCSplus  = sin(2*pi*freqCSplus*Samples);
toneCSminus = sin(2*pi*freqCSminus*Samples);



%% ACQUIRE IMAGE ACQUISITION DEVICE (THERMAL CAMERA) OBJECT
% imaqtool

% PREALLOCATE MEMORY FOR IMAGE DATA CONTAINERS
FramesPerTrial = 3;
nFrames = FramesPerTrial * TotTrials;
Frames = repmat({uint8(zeros(720,1280,3))},1,nFrames);  % Frames{1xN}(720x1280x3)uint8
FramesTS = repmat({clock},1,nFrames);

% ACQUIRE IMAGING DEVICE AS vidObj
% vidObj = videoinput('winvideo', 1, 'UYVY_720x576');  % Thermal Cam (UYVY_720x576 or UYVY_720x480)
vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % iSight Cam
vidsrc = getselectedsource(vidObj);

vidObj.LoggingMode = 'memory';
vidObj.ReturnedColorspace = 'rgb';

vidObj.TriggerRepeat = Inf;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');
% src.AnalogVideoFormat = 'ntsc_m_j'; % UNCOMMENT WHEN USING winvideo
% vidObj.ROIPosition = [488 95 397 507];
% preview(vidObj); pause(3); stoppreview(vidObj);

start(vidObj);


%% START MAIN EXPERIMENT LOOP

StartTime = clock;      % get timestamp
ff = 1;                 % current frame

for nn = 1:numel(randOrder)                 % loop over the 40 trials


% START CONDITIONING TRIAL

    % PLAY CS+ OR CS- TONE
    if randOrder(nn)
        sound(toneCSplus, SampleRate); 
    else
        sound(toneCSminus, SampleRate) 
    end

    % GET THERMAL CAM SNAPSHOT
    Frames{ff}   = getsnapshot(vidObj);
    FramesTS{ff} = clock; ff=ff+1;
    

    pause(TRtime-SHtime)

    % IF CS+ DELIVER SHOCK
    if randOrder(nn) 

        tictoc=0; tic;              % start tic toc Trial Timer
        while (tictoc < SHtime)     % for the next .5 seconds...
            disp('SHOCK!!!')        % evoke coulbourn shock device
            pause(.05)
            tictoc = tictoc + toc;  % update elapsed TrialTime
        end

    else

        tictoc=0; tic;              % start tic toc Trial Timer
        while (tictoc < SHtime)     % for the next .5 seconds...
            disp('NO SHOCK')        % skip coulbourn
            pause(.05)
            tictoc = tictoc + toc;  % update elapsed TrialTime
        end
    end



% START INTER-TRIAL INTERVAL (ITI)

    % GET THERMAL CAM SNAPSHOT
    Frames{ff}   = getsnapshot(vidObj);
    FramesTS{ff} = clock; ff=ff+1;
    
    pause(ITItime/2)

    % GET THERMAL CAM SNAPSHOT
    Frames{ff}   = getsnapshot(vidObj);
    FramesTS{ff} = clock; ff=ff+1;

    pause(ITItime/2)
    clc

end; % END MAIN LOOP



%% STOP/CLEAR VIDEO OBJECT & PLAYBACK THERMAL VIDEO FRAMES

stop(vidObj);
wait(vidObj);
clear('vidObj');

close all
for nn = 1:numel(Frames)
    figure(1)
    imagesc(Frames{nn})
    axis image; pause(.1)
end


%% COMPARE THE EXPERIMENT'S THEORETICAL TIME VS ACTUAL TIME
% This section of code compares the timestamps for when thermal image snapshots
% were actually taken vs. when they should have theoretically been taken.
% Due to variability in machine performance, it's unlikely these two sets of
% time values will correspond 1:1; however, they should be fairly close. If there 
% is large point-differences or a large systematic drift, steps should be taken 
% to attenuate the timeing issues, or offset the drift programatically.

% FramesTS{1} = [year month day hour minute seconds]
for nn = 2:numel(FramesTS)
    elapsedT(nn-1) = etime(FramesTS{nn},FramesTS{nn-1});
end
actual_elapsed_time = cumsum(elapsedT);
actual_elapsed_time = [0 actual_elapsed_time];
TR_ITI_ITI = [TRtime ITItime/2 ITItime/2];
TR_ITI_ITI = repmat(TR_ITI_ITI,1,TotTrials);
TR_ITI_ITI(end) = []; TR_ITI_ITI = [0 TR_ITI_ITI];
theoretical_elapsed_time = cumsum(TR_ITI_ITI);
format shortg; disp(actual_elapsed_time); disp(theoretical_elapsed_time)

% PLOT THEORETICAL TIME VS ACTUAL TIME
phActu = plot(actual_elapsed_time, theoretical_elapsed_time);
    axlims = [0 theoretical_elapsed_time(end)+10];
    set(gca,'XLim',axlims,'YLim',axlims); hold on;
phTheo = plot(theoretical_elapsed_time, theoretical_elapsed_time);
    leg1 = legend([phActu,phTheo],{'Actual Elapsed Time','Theoretical Elapsed Time'});
    set(leg1, 'Location','NorthWest', 'Color', [1 1 1],'FontSize',14,'Box','off');



%% SAVE EXPERIMENTAL DATASET TO HDD

save('thermalData_S1.mat', 'Frames', 'FramesTS', 'randOrder');


return


%% ---------END MAIN SCRIPT------NOTES AND STASHED CODE BELOW-------------

% IMPORT SLIDESHOW IMAGES
%{
artworkdir = dir('artwork');
artfilenames = {artworkdir.name};

art.regexp = '.*(art).*';
art.imgs = artfilenames(~cellfun('isempty',regexp(artfilenames,art.regexp)));

for nn = 1:numel(art.imgs)
[I,map] = imread(art.imgs{nn});   % get image data from file
iDUBs = im2double(I);
Pixels = [512 NaN];         % resize all images to 512x512 pixels
iDUBs = imresize(iDUBs, Pixels);
iDUBs(iDUBs > 1) = 1;  % In rare cases resizing results in some pixel vals > 1
IMGs{nn} = iDUBs;
end

fh1=figure('Position',[10 10 1200 900],'Color','w');
hax1=axes('Position',[.07 .1 .8 .8],'Color','none');

for nn = 1:numel(art.imgs)
    figure(fh1); axes(hax1);
    image(IMGs{nn})
    %imshow(IMGs{nn})
    axis off; axis image;
    drawnow;
    pause(2)
end
%}


% EXAMPLE SCRIPT FLOW-CONTROL USING A TIMER CALLBACK FUNCTION
%{
function timerEx
% inputs
t = 1:0.05:25;
% time-dependent functions
sin_t = sin(t);
cos_t = cos(t);
% loop for time-dependent measurements
n = numel(t);
figure, xlim([min(t) max(t)]), ylim([-2 2]);
hold on
%Plot first point, store handles so we can update the data later.
h(1) = plot (t(1), sin_t(1));
h(2) = plot (t(1), cos_t(1));
%Build timer
T = timer('Period',0.01,... %period
          'ExecutionMode','fixedRate',... %{singleShot,fixedRate,fixedSpacing,fixedDelay}
          'BusyMode','drop',... %{drop, error, queue}
          'TasksToExecute',n-1,...          
          'StartDelay',0,...
          'TimerFcn',@tcb,...
          'StartFcn',[],...
          'StopFcn',[],...
          'ErrorFcn',[]);
% Start it      
start(T);
      %Nested function!  Has access to variables in above workspace
      function tcb(src,evt)
          %What task are we on?  Use this instead of for-loop variable ii
          taskEx = get(src,'TasksExecuted');
          %Update the x and y data.
          set(h(1),'XData',t(1:taskEx),'YData',sin_t(1:taskEx));
          set(h(2),'XData',t(1:taskEx),'YData',cos_t(1:taskEx));
          drawnow; %force event queue flush
      end
  end
%}
