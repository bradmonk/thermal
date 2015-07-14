function [varargout] = ThermalImageAnalysis(varargin)
%% ThermalImageAnalysis.m USAGE NOTES AND CREDITS
%{

Syntax
-----------------------------------------------------
    xmlmesh(vrts,tets)
    xmlmesh(vrts,tets,'filename.xml')
    xmlmesh(____,'doctype','xmlns')


Description
-----------------------------------------------------
    xmlmesh() takes a set of 2D or 3D vertices (vrts) and a tetrahedral (tets)
    connectivity list, and creates an XML file of the mesh. This function was 
    originally created to export xml mesh files for using in Fenics:Dolfin 
    but can be adapted for universal xml export of triangulated meshes.


Useage Definitions
-----------------------------------------------------


    xmlmesh(vrts,tets)
        creates an XML file 'xmlmesh.xml' from a set of vertices "vrts"
        and a connectivity list; here the connectivity list is referred 
        to as "tets". These parameters can be generated manually, or by
        using matlab's builtin triangulation functions. The point list
        "vrts" is a matrix with dimensions Mx2 (for 2D) or Mx3 (for 3D).
        The matrix "tets" represents the triangulated connectivity list 
        of size Mx3 (for 2D) or Mx4 (for 3D), where M is the number of 
        triangles. Each row of tets specifies a triangle defined by indices 
        with respect to the points. The delaunayTriangulation function
        can be used to quickly generate these input variables:
            TR = delaunayTriangulation(XYZ);
            vrts = TR.Points;
            tets = TR.ConnectivityList;


    xmlmesh(vrts,tets,'filename.xml')
        same as above, but allows you to specify the xml filename.


    xmlmesh(____,'doctype','xmlns')
        same as above, but allows you to additionally specify the
        xml namespace xmlns attribute. For details see:
        http://www.w3schools.com/xml/xml_namespaces.asp




Example
-----------------------------------------------------

% Create 2D triangulated mesh
    XY = randn(10,2);
    TR2D = delaunayTriangulation(XY);
    vrts = TR2D.Points;
    tets = TR2D.ConnectivityList;

    xmlmesh(vrts,tets,'xmlmesh_2D.xml')


% Create 3D triangulated mesh
    d = [-5 8];
    [x,y,z] = meshgrid(d,d,d); % a cube
    XYZ = [x(:) y(:) z(:)];
    TR3D = delaunayTriangulation(XYZ);
    vrts = TR3D.Points;
    tets = TR3D.ConnectivityList;

    xmlmesh(vrts,tets,'xmlmesh_3D.xml')


Example Output
--------------------------







See Also
-----------------------------------------------------
http://bradleymonk.com/ThermalImageAnalysis
https://github.com/subroutines/thermal
>> web(fullfile(docroot, 'matlab/math/triangulation-representations.html'))


Attribution
-----------------------------------------------------
% Created by: Bradley Monk
% email: brad.monk@gmail.com
% website: bradleymonk.com
% 2015.07.13

%}

%% CLEAR CONSOLE AND CLOSE ANY OPEN FIGURES

clc; close all; % clear


%% CD TO DIRECTORY CONTAINING DATASET

varargin = 'FC_Day1_s2_13-Jul-2015.mat'; % <-- THIS IS TEMPORARY

% this=fileparts(which('S3D.m')); addpath(this); cd(this);
% cd(fileparts(which(mfilename)));
cd(fileparts(which(varargin)));



%% ---------- LOAD THERMAL IMAGE DATASET     ----------

load(varargin);


%% PLAYBACK THERMAL VIDEO FRAMES & SAVE DATA


numFrames = numel(Frames);

for nn = 1:numel(Frames)

    if mod(nn,10)==0
    figure(1)
    imagesc(Frames{nn}(:,:,:))
    axis image
    drawnow
    pause(.1)
    end

end



%% 

clear iDUBs
for nn = 1:numel(Frames)

    dubFrameR = double(Frames{nn}(:,:,1));
    dubFrameB = double(Frames{nn}(:,:,2));
    dubFrameG = double(Frames{nn}(:,:,3));

    iDUBs{nn} = (dubFrameR+dubFrameB+dubFrameG)./3.0;

end

size(iDUBs{1})

%%
% set(gca,'YDir','reverse')
fh1 = figure(1); set(fh1,'OuterPosition',[200 200 820 580],'Color',[1 1 1]);
hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'YDir','reverse',...
           'NextPlot','replacechildren','SortMethod','childorder');
            colormap('bone');
ph1 = imagesc(iDUBs{2});

for nn = 1:numel(iDUBs)

    if mod(nn,10)==0
    set(ph1,'CData',iDUBs{nn});
    drawnow
    pause(.1)
    end

end



%% -- MESH SURFACE PLOT

iDUB = iDUBs{2};

close all;
fh1 = figure(1); set(fh1,'OuterPosition',[200 200 820 780],'Color',[1 1 1]);
hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],...
           'NextPlot','replacechildren','SortMethod','childorder');
            colormap('jet'); % set(gca,'YDir','reverse')

    mesh(iDUB)
        view([162 84])

    pause(2)


%% USE MOUSE TO DRAW BOX AROUND BACKGROUND AREA

close all;
fh2 = figure(1); set(fh2,'OuterPosition',[200 200 820 580],'Color',[1 1 1]);
hax2 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'YDir','reverse',...
           'NextPlot','replacechildren','SortMethod','childorder');
    imagesc(iDUB);
        title('USE MOUSE TO DRAW BOX AROUND ROI - THEN CLOSE IMAGE')
        % colormap(bone)

        disp('DRAW BOX AROUND ROI - THEN CLOSE IMAGE')
    h1 = imrect;
    pos1 = round(getPosition(h1)); % [xmin ymin width height]


%% GET FRAME COORDINATES AND CREATE XY MASK

    MASKTBLR = [pos1(2) (pos1(2)+pos1(4)) pos1(1) (pos1(1)+pos1(3))];

    % Background
    mask{1} = zeros(size(iDUB));
    mask{1}(MASKTBLR(1):MASKTBLR(2), MASKTBLR(3):MASKTBLR(4)) = 1;
    mask1 = mask{1};



%% CHECK THAT MASK(S) ARE CORRECT

fh2 = figure(2); set(fh2,'OuterPosition',[200 200 820 580],'Color',[1 1 1]);
hax2 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'YDir','reverse',...
           'NextPlot','replacechildren','SortMethod','childorder');

     imagesc(iDUB.*mask{1});




%% -- GET MEAN OF ROI PIXELS

    f1ROI = iDUB .* mask1;
    meanBG = mean(f1ROI(f1ROI > 0));

    meanALL = mean(iDUB(:));

    % iDUB = iDUB - meanBG;
    % iDUB(iDUB <= 0) = 0;


%% check vague SNR for masks.
close all

  hist(iDUB(:),80);
    %xlim([.05 .9])
    %xlim([10 200])
    pause(.5)


    %----------------------------
    promptTXT = {'Enter Threshold Mask Values:'};
    dlg_title = 'Input'; num_lines = 1; 
    presetval = {num2str(70)};
    dlgOut = inputdlg(promptTXT,dlg_title,num_lines,presetval);
    threshmask = str2num(dlgOut{:});




%% -- REMOVE PIXELS BELOW THRESHOLD

    threshPix = iDUB > threshmask;  % logical Mx of pixels > thresh
    rawPix = iDUB .* threshPix;		% raw value Mx of pixels > thresh



%% -- CHOOSE PCT% RANGE OF PIXELS ABOVE THRESH

    % how many pixels passed threshold (tons!)?  
	n = sum(threshPix(:));

    % get actual values of those pixels
	valArray = iDUB(threshPix);

    % sort pixels, brightest to dimmest
	Hi2LoVals = sort(valArray, 'descend');

    % select subset of pixels to use in terms of their brightness rank
	% this is up to the users discretion - and can be set in the dialogue box
	% the dialogue prompt has default vaules set to assess pixels that are 
	% within the range of X%-99.99% brightest

	promptTxtUB = {'Enter upper-bound percent of pixels to analyze'};
	dlg_TitleUB = 'Input'; num_lines = 1; presetUBval = {'99.99'};
	UB = inputdlg(promptTxtUB,dlg_TitleUB,num_lines,presetUBval);
	UpperBound = str2double(UB{:}) / 100;

	promptTxtLB = {'Enter lower-bound percent of pixels to analyze'};
	dlg_TitleLB = 'Input'; num_lines = 1; presetLBval = {'2'};
	LB = inputdlg(promptTxtLB,dlg_TitleLB,num_lines,presetLBval);
	LowerBound = str2double(LB{:}) / 100;

	n90 = round(n - (n * UpperBound));
    if n90 < 1; n90=1; end;
	n80 = round(n - (n * LowerBound));
	hotpix = Hi2LoVals(n90:n80);


%% -- GET PIXELS THAT PASSED PCT% THRESHOLD

    HighestP = Hi2LoVals(n90);
    LowestsP = Hi2LoVals(n80);

    HiLogicMxP = iDUB <= HighestP;      % logic value Mx of pixels passed thresh
    HiRawMxP = iDUB .* HiLogicMxP;		% raw value Mx of pixels passed thresh
    LoLogicMxP = iDUB >= LowestsP;		% logic value Mx of pixels passed thresh
    LoRawMxP = iDUB .* LoLogicMxP;		% raw value Mx of pixels passed thresh

    IncLogicMxP = HiRawMxP > LowestsP;
    IncRawMxP = HiRawMxP .* IncLogicMxP;

    IncPixArray = IncRawMxP(IncRawMxP>0);
    Hi2LoIncPixArray = sort(IncPixArray, 'descend');



%% -- GET PIXELS THAT PASSED PCT% THRESHOLD FOR ALL FRAMES

for nn = 1:numel(iDUBs)

    iDUB = iDUBs{nn};

    HiLogicMxP = iDUB <= HighestP;      % logic value Mx of pixels passed thresh
    HiRawMxP = iDUB .* HiLogicMxP;		% raw value Mx of pixels passed thresh
    LoLogicMxP = iDUB >= LowestsP;		% logic value Mx of pixels passed thresh
    LoRawMxP = iDUB .* LoLogicMxP;		% raw value Mx of pixels passed thresh

    LogicMx{nn} = HiRawMxP > LowestsP;
    ROIMx{nn} = HiRawMxP .* LogicMx{nn};
    ROIAr{nn} = ROIMx{nn}(ROIMx{nn}>0);

end

%% -- PLOT IMAGESC REPLAY OF PIXELS THAT PASSED PCT% THRESHOLD

close all
% set(gca,'YDir','reverse')
fh1 = figure(1); set(fh1,'OuterPosition',[200 200 820 620],'Color',[1 1 1]);
hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'YDir','reverse',...
           'NextPlot','replacechildren','SortMethod','childorder');
            colormap('jet');

ph1 = imagesc(ROIMx{2});

for nn = 1:numel(ROIMx)

    if mod(nn,10)==0
    set(ph1,'CData',ROIMx{nn});
    pause(.1)
    end

end


%% GET TRIAL DATATABLE AND DETERMINE SHOCK TRIALS

disp(trial_data)
N_Acquisition_Trials = 88;
Frames_Per_Trial_Preset = 5;

shock_trials = trial_data.stim(1:N_Acquisition_Trials)>.5;

Frames_Per_Trial = numel(ROIMx) / numel(shock_trials);

if Frames_Per_Trial ~= Frames_Per_Trial_Preset
    warn0 = sprintf('ERROR! \n');
    warn1 = sprintf('  Number of frames per trial is: % 2.2g \n', Frames_Per_Trial);
    warn2 = sprintf('  Frame num per trial should be: % 2.2g \n', Frames_Per_Trial_Preset);
    warn3 = sprintf('   aborting... \n');
    error([warn0 warn1 warn2 warn3])
end

% try
%    surf
% catch exception
%     disp(['ID: ' exception.identifier])
%     rethrow(exception)
% end


%% SEPARATE OUT SHOCK TRIALS VS NON-SHOCK TRIALS

% clear ROIMx_ShockTrials ROIMx_NonShockTrials
%     LogicMx{nn} = HiRawMxP > LowestsP;
%     ROIMx{nn} = HiRawMxP .* LogicMx{nn};
%     ROIAr{nn} = ROIMx{nn}(ROIMx{nn}>0);

shock_trials_Ar = repmat(shock_trials,1,Frames_Per_Trial_Preset)';
shock_trials_Ar = shock_trials_Ar(:)';
% numel(shock_trials_Ar)

ROIMx_ShockTrials = ROIMx(shock_trials_Ar);
ROIMx_NonShockTrials = ROIMx(~shock_trials_Ar);


%% -- Boxplot & Histogram

close all
fh1=figure('Position',[600 450 1000 500],'Color','w');
hax1=axes('Position',[.07 .1 .4 .8],'Color','none');
hax2=axes('Position',[.55 .1 .4 .8],'Color','none');

    boxplot(hax1,Hi2LoIncPixArray ...
	,'notch','on' ...
	,'whisker',1 ...
	,'widths',.8 ...
	,'factorgap',[0] ...
	,'medianstyle','target');
	%set(gca,'XTickLabel',{' '},'Position',[.04 .05 .25 .9])
    pause(2)

    % axes(GUIfh.Children(1).Children(1));
hist(hax2,Hi2LoIncPixArray(:),100);
		pause(2)




%% -- VIEW ORIGINAL, SNR MASK, AND TARGET IMAGES

close all
fh1=figure('Position',[600 450 1000 500],'Color','w');
hax1=axes('Position',[.07 .1 .4 .8],'Color','none');
hax2=axes('Position',[.55 .1 .4 .8],'Color','none');

        axes(hax1)
    imagesc(iDUB);
        %axis(HaxThresh,'image')

        axes(hax2)
    imagesc(IncRawMxP);

     colormap('jet');




%% NOTES AND MISC CODE

%{

iDUBs = Frames{2};

    AveR = mean(mean(iDUBs(:,:,1)));
    AveG = mean(mean(iDUBs(:,:,2)));
    AveB = mean(mean(iDUBs(:,:,3)));


Pixels = [512 NaN];         % resize all images to 512x512 pixels

[I,map] = imread(iFileName);   % get image data from file

% colormap will be a 512x512 matrix of class double (values range from 0-1)
iDUBs = im2double(I);              
iDUBs = imresize(iDUBs, Pixels);
iDUBs(iDUBs > 1) = 1;  % In rare cases resizing results in some pixel vals > 1

szImg = size(iDUBs);






%% -- NORMALIZE DATA TO RANGE: [0 <= DATA <= 1]
%--- PRINT MESSAGE TO CON ---
spf0=sprintf('Normalizing data to range [0 <= DATA <= 1]');
[ft,spf2,spf3,spf4]=upcon(ft,spf0,spf2,spf3,spf4);
%----------------------------


% I2 = histeq(I);
% figure
% imshow(I2)

IMGsumOrig = iDUB;
IMGs = iDUB;

maxIMG = max(max(IMGs));
minIMG = min(min(IMGs));

lintrans = @(x,a,b,c,d) (c*(1-(x-a)/(b-a)) + d*((x-a)/(b-a)));

    for nn = 1:numel(IMGs)

        x = IMGs(nn);

        if maxIMG > 1
            IMGs(nn) = lintrans(x,minIMG,maxIMG,0,1);
        else
            IMGs(nn) = lintrans(x,minIMG,1,0,1);
        end


    end




%% USE MOUSE TO DRAW BOX AROUND BACKGROUND AREA

if DODs(2)
%--- PRINT MESSAGE TO CON ---
spf0=sprintf('Perform manual background selection...');
[ft,spf2,spf3,spf4]=upcon(ft,spf0,spf2,spf3,spf4);
%----------------------------

    iDUB = IMGs;

        fh11 = figure(11);
        set(fh11,'OuterPosition',[400 400 700 700])
        ax1 = axes('Position',[.1 .1 .8 .8]);
    imagesc(iDUB);
        title('USE MOUSE TO DRAW BOX AROUND BACKGROUND AREA')
        % colormap(bone)

        disp('DRAW BOX AROUND A BACKGROUND AREA')
    h1 = imrect;
    pos1 = round(getPosition(h1)); % [xmin ymin width height]

close(fh11)

figure(Fh1)
set(Fh1,'CurrentAxes',hax1);
%--- PRINT MESSAGE TO CON ---
spf0=sprintf('Perform manual background selection... done');
[ft,spf2,spf3,spf4]=upcon(ft,spf0,spf2,spf3,spf4);
%----------------------------
end


if DODs(3)
%--- PRINT MESSAGE TO CON ---
spf0=sprintf('Performing auto background selection');
[ft,spf2,spf3,spf4]=upcon(ft,spf0,spf2,spf3,spf4);
%----------------------------

    iDUB = IMGs;
    szBG = size(iDUB);
    BGrows = szBG(1);
    BGcols = szBG(2);
    BGr10 = floor(BGrows/10);
    BGc10 = floor(BGcols/10);
    pos1 = [BGrows-BGr10 BGcols-BGc10 BGr10-1 BGc10-1];

end



    
%% GET FRAME COORDINATES AND CREATE XY MASK

    pmsk = [pos1(2) (pos1(2)+pos1(4)) pos1(1) (pos1(1)+pos1(3))];

    % Background
    mask{1} = zeros(size(iDUB));
    mask{1}(pmsk(1):pmsk(2), pmsk(3):pmsk(4)) = 1;
    mask1 = mask{1};


%% CHECK THAT MASK(S) ARE CORRECT

        axes(hax1);
    imagesc(iDUB);
        
vert = [pmsk(1) pmsk(1);pmsk(1) pmsk(2);pmsk(2) pmsk(2);pmsk(2) pmsk(1)];
fac = [1 2 3 4]; % vertices to connect to make square
fvc = [1 0 0;0 1 0;0 0 1;0 0 0];
patch('Faces',fac,'Vertices',vert,...
'FaceVertexCData',fvc,'FaceColor','interp','FaceAlpha',.5)

pause(1)


%% -- GET MEAN OF BACKGROUND PIXELS & SUBTRACT FROM IMAGE
%--- PRINT MESSAGE TO CON ---
spf0=sprintf('Taking average of background pixels');
[ft,spf2,spf3,spf4]=upcon(ft,spf0,spf2,spf3,spf4);
%----------------------------

    f1BACKGROUND = iDUB .* mask1;
    meanBG = mean(f1BACKGROUND(f1BACKGROUND >= 0));

    meanALL = mean(iDUB(:));

    iDUB = iDUB - meanBG;
    iDUB(iDUB <= 0) = 0;


%}











%%
varargout = {};
end