% function [varargout] = ThermalImageAnalysis(varargin)
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

clc; close all; clear



%% CD TO DIRECTORY CONTAINING DATASET

thisdir=fileparts(which('ThermalImageAnalysis.m'));
cd(thisdir); addpath(thisdir); addpath([thisdir '/data']);
% cd(fileparts(which(mfilename)));


%% VARARGIN == PARTICIPANT ID  (TEMPORARILY HARD-CODED)

varargin = 'FCs7.mat';

if strcmp(varargin,'FCs4.mat')
    load('FrameOrd_s4.mat')
end

load(varargin);


%% PLAYBACK THERMAL VIDEO FRAMES & SAVE DATA

playNframes = 10;

Frames(481:end) = [];

numFrames = numel(Frames);

% for nn = 1:numel(Frames)
% 
%     if mod(nn,playNframes)==0
%     figure(1)
%     imagesc(Frames{nn}(:,:,:))
%     axis image
%     drawnow
%     pause(.1)
%     end
% 
% end



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

iDmat = cell2mat(iDUBs);

%%
close all
% set(gca,'YDir','reverse')
fh1 = figure(1); set(fh1,'OuterPosition',[200 200 820 580],'Color',[1 1 1]);
hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'YDir','reverse',...
           'NextPlot','replacechildren','SortMethod','childorder');
            colormap('bone');
ph1 = imagesc(iDUBs{2});

for nn = 1:numel(iDUBs)

    if mod(nn,playNframes)==0
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
    ov=[175 88];
    view(ov)

    for nn=1:50
        view(ov-nn)
        pause(.1)
    end

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

	promptTxtUB = {'Enter number of acquisition trials...'};
	dlg_TitleUB = 'Input'; num_lines = 1; presetUBval = {'60'};
	UB = inputdlg(promptTxtUB,dlg_TitleUB,num_lines,presetUBval);
	N_Acquisition_Trials = str2double(UB{:});

	promptTxtUB = {'Enter number of frame captures per trial...'};
	dlg_TitleUB = 'Input'; num_lines = 1; presetUBval = {'8'};
	UB = inputdlg(promptTxtUB,dlg_TitleUB,num_lines,presetUBval);
	Frames_Per_Trial_Preset = str2double(UB{:});

shock_trials = trial_data.stim(1:N_Acquisition_Trials)>.5;
Frames_Per_Trial = numel(ROIMx) / numel(shock_trials);

%% THROW ERROR IF NUMBER OF FRAMES DOES NOT MATCH NUMBER OF TRIALS

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


% FrameOrd = FrameOrder(trial_data);
% disp(FrameOrd)

% CSm  = [1 2 3 4 5 6 7 8];             % CS- codes
% CSpp = [9 10 11 12 13 14 15 16];      % CS+ paired codes
% CSpu = [17 18 19 20 21 22 23 24];     % CS+ unpaired codes


% FRAMES_CSm_F1 = ROIMx(FrameOrd==1);
% FRAMES_CSm_F2 = ROIMx(FrameOrd==2);
% FRAMES_CSm_F3 = ROIMx(FrameOrd==3);
% FRAMES_CSm_F4 = ROIMx(FrameOrd==4);
% FRAMES_CSm_F5 = ROIMx(FrameOrd==5);
% FRAMES_CSm_F6 = ROIMx(FrameOrd==6);
% FRAMES_CSm_F7 = ROIMx(FrameOrd==7);
% FRAMES_CSm_F8 = ROIMx(FrameOrd==8);
% 
% FRAMES_CSpp_F1 = ROIMx(FrameOrd==9);
% FRAMES_CSpp_F2 = ROIMx(FrameOrd==10);
% FRAMES_CSpp_F3 = ROIMx(FrameOrd==11);
% FRAMES_CSpp_F4 = ROIMx(FrameOrd==12);
% FRAMES_CSpp_F5 = ROIMx(FrameOrd==13);
% FRAMES_CSpp_F6 = ROIMx(FrameOrd==14);
% FRAMES_CSpp_F7 = ROIMx(FrameOrd==15);
% FRAMES_CSpp_F8 = ROIMx(FrameOrd==16);
% 
% FRAMES_CSpu_F1 = ROIMx(FrameOrd==17);
% FRAMES_CSpu_F2 = ROIMx(FrameOrd==18);
% FRAMES_CSpu_F3 = ROIMx(FrameOrd==19);
% FRAMES_CSpu_F4 = ROIMx(FrameOrd==20);
% FRAMES_CSpu_F5 = ROIMx(FrameOrd==21);
% FRAMES_CSpu_F6 = ROIMx(FrameOrd==22);
% FRAMES_CSpu_F7 = ROIMx(FrameOrd==23);
% FRAMES_CSpu_F8 = ROIMx(FrameOrd==24);

FRAMES_CSm_F{1} = ROIMx(FrameOrd==1);
FRAMES_CSm_F{2} = ROIMx(FrameOrd==2);
FRAMES_CSm_F{3} = ROIMx(FrameOrd==3);
FRAMES_CSm_F{4} = ROIMx(FrameOrd==4);
FRAMES_CSm_F{5} = ROIMx(FrameOrd==5);
FRAMES_CSm_F{6} = ROIMx(FrameOrd==6);
FRAMES_CSm_F{7} = ROIMx(FrameOrd==7);
FRAMES_CSm_F{8} = ROIMx(FrameOrd==8);

FRAMES_CSpp_F{1} = ROIMx(FrameOrd==9);
FRAMES_CSpp_F{2} = ROIMx(FrameOrd==10);
FRAMES_CSpp_F{3} = ROIMx(FrameOrd==11);
FRAMES_CSpp_F{4} = ROIMx(FrameOrd==12);
FRAMES_CSpp_F{5} = ROIMx(FrameOrd==13);
FRAMES_CSpp_F{6} = ROIMx(FrameOrd==14);
FRAMES_CSpp_F{7} = ROIMx(FrameOrd==15);
FRAMES_CSpp_F{8} = ROIMx(FrameOrd==16);

FRAMES_CSpu_F{1} = ROIMx(FrameOrd==17);
FRAMES_CSpu_F{2} = ROIMx(FrameOrd==18);
FRAMES_CSpu_F{3} = ROIMx(FrameOrd==19);
FRAMES_CSpu_F{4} = ROIMx(FrameOrd==20);
FRAMES_CSpu_F{5} = ROIMx(FrameOrd==21);
FRAMES_CSpu_F{6} = ROIMx(FrameOrd==22);
FRAMES_CSpu_F{7} = ROIMx(FrameOrd==23);
FRAMES_CSpu_F{8} = ROIMx(FrameOrd==24);


%% -- CURRENT FRAME OF INTEREST
clear FRAMES_CSm FRAMES_CSpp FRAMES_CSpu FRAMES_CSm_means FRAMES_CSpp_means FRAMES_CSpu_means



for ff = 1:numel(FRAMES_CSpp_F)

    FRAMES_CSm = FRAMES_CSm_F{ff};
    FRAMES_CSpp = FRAMES_CSpp_F{ff};
    FRAMES_CSpu = FRAMES_CSpu_F{ff};


    mm=1;
    for nn = 1:numel(FRAMES_CSm)
        FRAMES_CSm_PixelMean(mm) = mean(FRAMES_CSm{nn}(FRAMES_CSm{nn}>0));
        mm=mm+1;
    end

    mm=1;
    for nn = 1:numel(FRAMES_CSpu)
        FRAMES_CSpp_PixelMean(mm) = mean(FRAMES_CSpp{nn}(FRAMES_CSpp{nn}>0));
        mm=mm+1;
    end

    mm=1;
    for nn = 1:numel(FRAMES_CSpu)
        FRAMES_CSpu_PixelMean(mm) = mean(FRAMES_CSpu{nn}(FRAMES_CSpu{nn}>0));
        mm=mm+1;
    end


    FRAMES_CSm_means(:,ff) = FRAMES_CSm_PixelMean';
    FRAMES_CSpp_means(:,ff) = FRAMES_CSpp_PixelMean';
    FRAMES_CSpu_means(:,ff) = FRAMES_CSpu_PixelMean';

end
% clear FRAMES_CSm_means FRAMES_CSpp_means FRAMES_CSpu_means
FRAMES_CSm_means(1:2:end,:) = [];
% size(FRAMES_CSm_means)


%---------------------------------------------
% % THESE CAN BE FLIPPED FOR DIFFERENT PLOTS
    FRAMES_CSm_means_8Frames = FRAMES_CSm_means';
    FRAMES_CSpp_mean_s8Frames = FRAMES_CSpp_means';
    FRAMES_CSpu_means_8Frames = FRAMES_CSpu_means';
%{.
    FRAMES_CSm_means = FRAMES_CSm_means_8Frames;
    FRAMES_CSpp_means = FRAMES_CSpp_mean_s8Frames;
    FRAMES_CSpu_means = FRAMES_CSpu_means_8Frames;
%}
%---------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%					FINAL OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fh1=figure('Position',[200 200 1200 700],'Color','w');
hax1=axes('Position',[.07 .07 .88 .88],'Color','none');
% hax2=axes('Position',[.55 .1 .4 .8],'Color','none');
% hax2=axes('Position',[.55 .1 .4 .8],'Color','none');
%-------------------------------------------------------------
c1= [.9 .2 .2]; c2= [.2 .4 .6]; c3= [.4 .8 .4]; c4= [.6 .6 .6]; c5= [.01 .9 .01];
c11=[.9 .3 .3]; c22=[.3 .5 .7]; c33=[.5 .9 .5]; c44=[.7 .7 .7]; c55=[.01 .9 .01];
applered= [.9 .2 .2]; oceanblue= [.2 .4 .6]; neongreen = [.1 .9 .1];
liteblue = [.2 .9 .9]; hotpink=[.9 .1 .9];
c11 = 'none'; %c22 = 'none';
%------------------------------------------------

%===========================================================%
% FIG1 TOP LEFT: Poly & Depoly Events
%===========================================================%

	%==============================================%
	MuDATA=FRAMES_CSpp_means; repDATA=size(FRAMES_CSpp_means,2);
	%------------------------------
	Mu = mean(MuDATA,2)';		Sd = std(MuDATA,0,2)';		Se = Sd./sqrt(repDATA);
	y_Mu = Mu;				x_Mu = 1:(size(y_Mu,2));	e_Mu = Se;
	xx_Mu = 1:0.1:max(x_Mu);
	% yy_Mu = spline(x_Mu,y_Mu,xx_Mu);	% ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
	yy_Mu = interp1(x_Mu,y_Mu,xx_Mu,'pchip');
	ee_Mu = interp1(x_Mu,e_Mu,xx_Mu,'pchip');
	p_Mu = polyfit(x_Mu,Mu,3);
	x2_Mu = 1:0.1:max(x_Mu);	y2_Mu = polyval(p_Mu,x2_Mu);
	XT_Mu = xx_Mu';				YT_Mu = yy_Mu';		ET_Mu = ee_Mu';
	%==============================================%

    %----------------------
%     HaxTL1 = axes('Position',axTot);
    %----------------------

[ph1, po1] = boundedline(XT_Mu,YT_Mu, ET_Mu,'cmap',c1,'alpha','transparency', 0.4);
	hold on

	%==============================================%
	MuDATA=FRAMES_CSpu_means; repDATA=size(FRAMES_CSpu_means,2);
	%------------------------------
	Mu = mean(MuDATA,2)';		Sd = std(MuDATA,0,2)';		Se = Sd./sqrt(repDATA);
	y_Mu = Mu;				x_Mu = 1:(size(y_Mu,2));	e_Mu = Se;
	xx_Mu = 1:0.1:max(x_Mu);
	% yy_Mu = spline(x_Mu,y_Mu,xx_Mu);	% ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
	yy_Mu = interp1(x_Mu,y_Mu,xx_Mu,'pchip');
	ee_Mu = interp1(x_Mu,e_Mu,xx_Mu,'pchip');
	p_Mu = polyfit(x_Mu,Mu,3);
	x2_Mu = 1:0.1:max(x_Mu);	y2_Mu = polyval(p_Mu,x2_Mu);
	XT_Mu = xx_Mu';				YT_Mu = yy_Mu';		ET_Mu = ee_Mu';
	%==============================================%
	
[ph2, po2] = boundedline(XT_Mu,YT_Mu, ET_Mu,'cmap',c2,'alpha','transparency', 0.4);

	axis tight; hold on;



	%==============================================%
	MuDATA=FRAMES_CSm_means; repDATA=size(FRAMES_CSm_means,2);
	%------------------------------
	Mu = mean(MuDATA,2)';		Sd = std(MuDATA,0,2)';		Se = Sd./sqrt(repDATA);
	y_Mu = Mu;				x_Mu = 1:(size(y_Mu,2));	e_Mu = Se;
	xx_Mu = 1:0.1:max(x_Mu);
	% yy_Mu = spline(x_Mu,y_Mu,xx_Mu);	% ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
	yy_Mu = interp1(x_Mu,y_Mu,xx_Mu,'pchip');
	ee_Mu = interp1(x_Mu,e_Mu,xx_Mu,'pchip');
	p_Mu = polyfit(x_Mu,Mu,3);
	x2_Mu = 1:0.1:max(x_Mu);	y2_Mu = polyval(p_Mu,x2_Mu);
	XT_Mu = xx_Mu';				YT_Mu = yy_Mu';		ET_Mu = ee_Mu';
	%==============================================%
	
[ph3, po3] = boundedline(XT_Mu,YT_Mu, ET_Mu,'cmap',c2,'alpha','transparency', 0.4);

	axis tight; hold on;



	
    leg1 = legend([ph1,ph2,ph3],{' CS+ paired',' CS+ unpaired',' CS- trial'});
    set(leg1, 'Location','NorthWest', 'Color', [1 1 1],'FontSize',16,'Box','off');
    set(leg1, 'Position', leg1.Position .* [1 .92 1 1.5])


        MS1 = 5; MS2 = 2;
    set(ph1,'LineStyle','-','Color',c1,'LineWidth',5,...
        'Marker','none','MarkerSize',MS1,'MarkerEdgeColor',c1);
    set(ph2,'LineStyle','-.','Color',c2,'LineWidth',5,...
        'Marker','none','MarkerSize',MS1,'MarkerEdgeColor',c2);
    set(ph3,'LineStyle',':','Color',c3,'LineWidth',4,...
        'Marker','none','MarkerSize',MS1,'MarkerEdgeColor',c3);

    hTitle  = title ('\fontsize{20} Thermal Signature Per Frame Capture');
    hXLabel = xlabel('\fontsize{16} Frame Captures Per Trial');
    hYLabel = ylabel('\fontsize{16} Thermal Signature (+/- SEM)');
    set(gca,'FontName','Helvetica','FontSize',12);
    set([hTitle, hXLabel, hYLabel],'FontName','Century Gothic');
    set(gca,'Box','off','TickDir','out','TickLength',[.01 .01], ...
    'XMinorTick','off','YMinorTick','on','YGrid','on', ...
    'XColor',[.3 .3 .3],'YColor',[.3 .3 .3],'LineWidth',2);



%% USE MOUSE TO DRAW BOX AROUND ROI AREA

close all;
fh2 = figure(1); set(fh2,'OuterPosition',[200 200 820 580],'Color',[1 1 1]);
hax2 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'YDir','reverse',...
           'NextPlot','replacechildren','SortMethod','childorder');
    imagesc(FRAMES_CSm_F{1}{1});
        title('USE MOUSE TO DRAW BOX AROUND ROI - THEN CLOSE IMAGE')
        disp('DRAW BOX AROUND ROI - THEN CLOSE IMAGE')
    h1 = imrect;
    pos1 = round(getPosition(h1)); % [xmin ymin width height]

    MASKTBLR = [pos1(2) (pos1(2)+pos1(4)) pos1(1) (pos1(1)+pos1(3))];

    mask{1} = zeros(size(FRAMES_CSm_F{1}{1}));
    mask{1}(MASKTBLR(1):MASKTBLR(2), MASKTBLR(3):MASKTBLR(4)) = 1;
    mask1 = mask{1};



%% CHECK THAT MASK(S) ARE CORRECT

fh2 = figure(2); set(fh2,'OuterPosition',[200 200 820 580],'Color',[1 1 1]);
hax2 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'YDir','reverse',...
           'NextPlot','replacechildren','SortMethod','childorder');

     imagesc(FRAMES_CSm_F{1}{1}.*mask1);



%%
clear FRAMES_CSm FRAMES_CSpp FRAMES_CSpu FRAMES_CSm_means FRAMES_CSpp_means FRAMES_CSpu_means
%   FRAMES_CSm_F = {1x30 cell} x 8

% ff will loop through frame-captures 1 - 8 on each trial
for ff = 1:8

    FRAMES_CSm = FRAMES_CSm_F{ff}; 
    FRAMES_CSpp = FRAMES_CSpp_F{ff};
    FRAMES_CSpu = FRAMES_CSpu_F{ff};

    % nn will loop through each of the 15 (or 30) trials
    for nn = 1:numel(FRAMES_CSm)
        PIXELS_IN_ROI = FRAMES_CSm{nn}.*mask1;
        CSmMu_PIXELS_IN_ROI(nn) = mean(PIXELS_IN_ROI(PIXELS_IN_ROI>0));
    end

    for nn = 1:numel(FRAMES_CSpp)
        PIXELS_IN_ROI = FRAMES_CSpp{nn}.*mask1;
        CSppMu_PIXELS_IN_ROI(nn) = mean(PIXELS_IN_ROI(PIXELS_IN_ROI>0));
    end

    for nn = 1:numel(FRAMES_CSpu)
        PIXELS_IN_ROI = FRAMES_CSpu{nn}.*mask1;
        CSpuMu_PIXELS_IN_ROI(nn) = mean(PIXELS_IN_ROI(PIXELS_IN_ROI>0));
    end


    FRAMES_CSm_means(:,ff) = CSmMu_PIXELS_IN_ROI';
    FRAMES_CSpp_means(:,ff) = CSppMu_PIXELS_IN_ROI';
    FRAMES_CSpu_means(:,ff) = CSpuMu_PIXELS_IN_ROI';

end
% clear FRAMES_CSm_means FRAMES_CSpp_means FRAMES_CSpu_means
FRAMES_CSm_means(1:2:end,:) = [];
% size(FRAMES_CSm_means)




%---------------------------------------------
% % THESE CAN BE FLIPPED FOR DIFFERENT PLOTS
%{.
    FRAMES_CSm_means_8Frames = FRAMES_CSm_means';
    FRAMES_CSpp_mean_s8Frames = FRAMES_CSpp_means';
    FRAMES_CSpu_means_8Frames = FRAMES_CSpu_means';
%}
%{
    FRAMES_CSm_means = FRAMES_CSm_means_8Frames;
    FRAMES_CSpp_means = FRAMES_CSpp_mean_s8Frames;
    FRAMES_CSpu_means = FRAMES_CSpu_means_8Frames;
%}
%---------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%					FINAL OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fh1=figure('Position',[200 200 1200 700],'Color','w');
hax1=axes('Position',[.07 .07 .88 .88],'Color','none');
% hax2=axes('Position',[.55 .1 .4 .8],'Color','none');
% hax2=axes('Position',[.55 .1 .4 .8],'Color','none');
%-------------------------------------------------------------
c1= [.9 .2 .2]; c2= [.2 .4 .6]; c3= [.4 .8 .4]; c4= [.6 .6 .6]; c5= [.01 .9 .01];
c11=[.9 .3 .3]; c22=[.3 .5 .7]; c33=[.5 .9 .5]; c44=[.7 .7 .7]; c55=[.01 .9 .01];
applered= [.9 .2 .2]; oceanblue= [.2 .4 .6]; neongreen = [.1 .9 .1];
liteblue = [.2 .9 .9]; hotpink=[.9 .1 .9];
c11 = 'none'; %c22 = 'none';
%------------------------------------------------

%===========================================================%
% FIG1 TOP LEFT: Poly & Depoly Events
%===========================================================%

	%==============================================%
	MuDATA=FRAMES_CSpp_means; repDATA=size(FRAMES_CSpp_means,2);
	%------------------------------
	Mu = mean(MuDATA,2)';		Sd = std(MuDATA,0,2)';		Se = Sd./sqrt(repDATA);
	y_Mu = Mu;				x_Mu = 1:(size(y_Mu,2));	e_Mu = Se;
	xx_Mu = 1:0.1:max(x_Mu);
	% yy_Mu = spline(x_Mu,y_Mu,xx_Mu);	% ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
	yy_Mu = interp1(x_Mu,y_Mu,xx_Mu,'pchip');
	ee_Mu = interp1(x_Mu,e_Mu,xx_Mu,'pchip');
	p_Mu = polyfit(x_Mu,Mu,3);
	x2_Mu = 1:0.1:max(x_Mu);	y2_Mu = polyval(p_Mu,x2_Mu);
	XT_Mu = xx_Mu';				YT_Mu = yy_Mu';		ET_Mu = ee_Mu';
	%==============================================%

    %----------------------
%     HaxTL1 = axes('Position',axTot);
    %----------------------

[ph1, po1] = boundedline(XT_Mu,YT_Mu, ET_Mu,'cmap',c1,'alpha','transparency', 0.4);
	hold on

	%==============================================%
	MuDATA=FRAMES_CSpu_means; repDATA=size(FRAMES_CSpu_means,2);
	%------------------------------
	Mu = mean(MuDATA,2)';		Sd = std(MuDATA,0,2)';		Se = Sd./sqrt(repDATA);
	y_Mu = Mu;				x_Mu = 1:(size(y_Mu,2));	e_Mu = Se;
	xx_Mu = 1:0.1:max(x_Mu);
	% yy_Mu = spline(x_Mu,y_Mu,xx_Mu);	% ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
	yy_Mu = interp1(x_Mu,y_Mu,xx_Mu,'pchip');
	ee_Mu = interp1(x_Mu,e_Mu,xx_Mu,'pchip');
	p_Mu = polyfit(x_Mu,Mu,3);
	x2_Mu = 1:0.1:max(x_Mu);	y2_Mu = polyval(p_Mu,x2_Mu);
	XT_Mu = xx_Mu';				YT_Mu = yy_Mu';		ET_Mu = ee_Mu';
	%==============================================%
	
[ph2, po2] = boundedline(XT_Mu,YT_Mu, ET_Mu,'cmap',c2,'alpha','transparency', 0.4);

	axis tight; hold on;



	%==============================================%
	MuDATA=FRAMES_CSm_means; repDATA=size(FRAMES_CSm_means,2);
	%------------------------------
	Mu = mean(MuDATA,2)';		Sd = std(MuDATA,0,2)';		Se = Sd./sqrt(repDATA);
	y_Mu = Mu;				x_Mu = 1:(size(y_Mu,2));	e_Mu = Se;
	xx_Mu = 1:0.1:max(x_Mu);
	% yy_Mu = spline(x_Mu,y_Mu,xx_Mu);	% ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
	yy_Mu = interp1(x_Mu,y_Mu,xx_Mu,'pchip');
	ee_Mu = interp1(x_Mu,e_Mu,xx_Mu,'pchip');
	p_Mu = polyfit(x_Mu,Mu,3);
	x2_Mu = 1:0.1:max(x_Mu);	y2_Mu = polyval(p_Mu,x2_Mu);
	XT_Mu = xx_Mu';				YT_Mu = yy_Mu';		ET_Mu = ee_Mu';
	%==============================================%
	
[ph3, po3] = boundedline(XT_Mu,YT_Mu, ET_Mu,'cmap',c3,'alpha','transparency', 0.4);

	axis tight; hold on;



	
    leg1 = legend([ph1,ph2,ph3],{' CS+ paired',' CS+ unpaired',' CS- trial'});
    set(leg1, 'Location','NorthWest', 'Color', [1 1 1],'FontSize',16,'Box','off');
    set(leg1, 'Position', leg1.Position .* [1 .92 1 1.5])


        MS1 = 5; MS2 = 2;
    set(ph1,'LineStyle','-','Color',c1,'LineWidth',5,...
        'Marker','none','MarkerSize',MS1,'MarkerEdgeColor',c1);
    set(ph2,'LineStyle','-.','Color',c2,'LineWidth',5,...
        'Marker','none','MarkerSize',MS1,'MarkerEdgeColor',c2);
    set(ph3,'LineStyle',':','Color',c3,'LineWidth',4,...
        'Marker','none','MarkerSize',MS1,'MarkerEdgeColor',c3);

    hTitle  = title ('\fontsize{20} Thermal Signature Per Frame Capture');
    hXLabel = xlabel('\fontsize{16} Frame Captures Per Trial');
    hYLabel = ylabel('\fontsize{16} Thermal Signature (+/- SEM)');
    set(gca,'FontName','Helvetica','FontSize',12);
    set([hTitle, hXLabel, hYLabel],'FontName','Century Gothic');
    set(gca,'Box','off','TickDir','out','TickLength',[.01 .01], ...
    'XMinorTick','off','YMinorTick','on','YGrid','on', ...
    'XColor',[.3 .3 .3],'YColor',[.3 .3 .3],'LineWidth',2);







%%
clear FRAMES_CSm FRAMES_CSpp FRAMES_CSpu FRAMES_CSm_means FRAMES_CSpp_means FRAMES_CSpu_means
%   FRAMES_CSm_F = {1x30 cell} x 8

% ff will loop through frame-captures 1 - 8 on each trial
for ff = 1:8

    FRAMES_CSm = FRAMES_CSm_F{ff}; 
    FRAMES_CSpp = FRAMES_CSpp_F{ff};
    FRAMES_CSpu = FRAMES_CSpu_F{ff};

    % nn will loop through each of the 15 (or 30) trials
    for nn = 1:numel(FRAMES_CSm)
        PIXELS_IN_ROI = FRAMES_CSm{nn}.*mask1;
        CSmMu_PIXELS_IN_ROI(nn) = mean(PIXELS_IN_ROI(PIXELS_IN_ROI>0));
    end

    for nn = 1:numel(FRAMES_CSpp)
        PIXELS_IN_ROI = FRAMES_CSpp{nn}.*mask1;
        CSppMu_PIXELS_IN_ROI(nn) = mean(PIXELS_IN_ROI(PIXELS_IN_ROI>0));
    end

    for nn = 1:numel(FRAMES_CSpu)
        PIXELS_IN_ROI = FRAMES_CSpu{nn}.*mask1;
        CSpuMu_PIXELS_IN_ROI(nn) = mean(PIXELS_IN_ROI(PIXELS_IN_ROI>0));
    end


    FRAMES_CSm_means(:,ff) = CSmMu_PIXELS_IN_ROI';
    FRAMES_CSpp_means(:,ff) = CSppMu_PIXELS_IN_ROI';
    FRAMES_CSpu_means(:,ff) = CSpuMu_PIXELS_IN_ROI';

end
% clear FRAMES_CSm_means FRAMES_CSpp_means FRAMES_CSpu_means
FRAMES_CSm_means(1:2:end,:) = [];
% size(FRAMES_CSm_means)




%---------------------------------------------
% % THESE CAN BE FLIPPED FOR DIFFERENT PLOTS
%{
    FRAMES_CSm_means_8Frames = FRAMES_CSm_means';
    FRAMES_CSpp_mean_s8Frames = FRAMES_CSpp_means';
    FRAMES_CSpu_means_8Frames = FRAMES_CSpu_means';
%}
%{.
    FRAMES_CSm_means = FRAMES_CSm_means_8Frames;
    FRAMES_CSpp_means = FRAMES_CSpp_mean_s8Frames;
    FRAMES_CSpu_means = FRAMES_CSpu_means_8Frames;
%}
%---------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%					FINAL OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fh1=figure('Position',[100 200 1200 700],'Color','w');
hax1=axes('Position',[.07 .07 .88 .88],'Color','none');
% hax2=axes('Position',[.55 .1 .4 .8],'Color','none');
% hax2=axes('Position',[.55 .1 .4 .8],'Color','none');
%-------------------------------------------------------------
c1= [.9 .2 .2]; c2= [.2 .4 .6]; c3= [.4 .8 .4]; c4= [.6 .6 .6]; c5= [.01 .9 .01];
c11=[.9 .3 .3]; c22=[.3 .5 .7]; c33=[.5 .9 .5]; c44=[.7 .7 .7]; c55=[.01 .9 .01];
applered= [.9 .2 .2]; oceanblue= [.2 .4 .6]; neongreen = [.1 .9 .1];
liteblue = [.2 .9 .9]; hotpink=[.9 .1 .9];
c11 = 'none'; %c22 = 'none';
%------------------------------------------------

%===========================================================%
% FIG1 TOP LEFT: Poly & Depoly Events
%===========================================================%

	%==============================================%
	MuDATA=FRAMES_CSpp_means; repDATA=size(FRAMES_CSpp_means,2);
	%------------------------------
	Mu = mean(MuDATA,2)';		Sd = std(MuDATA,0,2)';		Se = Sd./sqrt(repDATA);
	y_Mu = Mu;				x_Mu = 1:(size(y_Mu,2));	e_Mu = Se;
	xx_Mu = 1:0.1:max(x_Mu);
	% yy_Mu = spline(x_Mu,y_Mu,xx_Mu);	% ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
	yy_Mu = interp1(x_Mu,y_Mu,xx_Mu,'pchip');
	ee_Mu = interp1(x_Mu,e_Mu,xx_Mu,'pchip');
	p_Mu = polyfit(x_Mu,Mu,3);
	x2_Mu = 1:0.1:max(x_Mu);	y2_Mu = polyval(p_Mu,x2_Mu);
	XT_Mu = xx_Mu';				YT_Mu = yy_Mu';		ET_Mu = ee_Mu';
	%==============================================%

    %----------------------
%     HaxTL1 = axes('Position',axTot);
    %----------------------

[ph1, po1] = boundedline(XT_Mu,YT_Mu, ET_Mu,'cmap',c1,'alpha','transparency', 0.4);
	hold on

	%==============================================%
	MuDATA=FRAMES_CSpu_means; repDATA=size(FRAMES_CSpu_means,2);
	%------------------------------
	Mu = mean(MuDATA,2)';		Sd = std(MuDATA,0,2)';		Se = Sd./sqrt(repDATA);
	y_Mu = Mu;				x_Mu = 1:(size(y_Mu,2));	e_Mu = Se;
	xx_Mu = 1:0.1:max(x_Mu);
	% yy_Mu = spline(x_Mu,y_Mu,xx_Mu);	% ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
	yy_Mu = interp1(x_Mu,y_Mu,xx_Mu,'pchip');
	ee_Mu = interp1(x_Mu,e_Mu,xx_Mu,'pchip');
	p_Mu = polyfit(x_Mu,Mu,3);
	x2_Mu = 1:0.1:max(x_Mu);	y2_Mu = polyval(p_Mu,x2_Mu);
	XT_Mu = xx_Mu';				YT_Mu = yy_Mu';		ET_Mu = ee_Mu';
	%==============================================%
	
[ph2, po2] = boundedline(XT_Mu,YT_Mu, ET_Mu,'cmap',c2,'alpha','transparency', 0.4);

	axis tight; hold on;



	%==============================================%
	MuDATA=FRAMES_CSm_means; repDATA=size(FRAMES_CSm_means,2);
	%------------------------------
	Mu = mean(MuDATA,2)';		Sd = std(MuDATA,0,2)';		Se = Sd./sqrt(repDATA);
	y_Mu = Mu;				x_Mu = 1:(size(y_Mu,2));	e_Mu = Se;
	xx_Mu = 1:0.1:max(x_Mu);
	% yy_Mu = spline(x_Mu,y_Mu,xx_Mu);	% ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
	yy_Mu = interp1(x_Mu,y_Mu,xx_Mu,'pchip');
	ee_Mu = interp1(x_Mu,e_Mu,xx_Mu,'pchip');
	p_Mu = polyfit(x_Mu,Mu,3);
	x2_Mu = 1:0.1:max(x_Mu);	y2_Mu = polyval(p_Mu,x2_Mu);
	XT_Mu = xx_Mu';				YT_Mu = yy_Mu';		ET_Mu = ee_Mu';
	%==============================================%
	
[ph3, po3] = boundedline(XT_Mu,YT_Mu, ET_Mu,'cmap',c3,'alpha','transparency', 0.4);

	axis tight; hold on;



	
    leg1 = legend([ph1,ph2,ph3],{' CS+ paired',' CS+ unpaired',' CS- trial'});
    set(leg1, 'Location','NorthWest', 'Color', [1 1 1],'FontSize',16,'Box','off');
    set(leg1, 'Position', leg1.Position .* [1 .92 1 1.5])


        MS1 = 5; MS2 = 2;
    set(ph1,'LineStyle','-','Color',c1,'LineWidth',5,...
        'Marker','none','MarkerSize',MS1,'MarkerEdgeColor',c1);
    set(ph2,'LineStyle','-.','Color',c2,'LineWidth',5,...
        'Marker','none','MarkerSize',MS1,'MarkerEdgeColor',c2);
    set(ph3,'LineStyle',':','Color',c3,'LineWidth',4,...
        'Marker','none','MarkerSize',MS1,'MarkerEdgeColor',c3);

    hTitle  = title ('\fontsize{20} Thermal Signature Per Frame Capture');
    hXLabel = xlabel('\fontsize{16} Frame Captures Per Trial');
    hYLabel = ylabel('\fontsize{16} Thermal Signature (+/- SEM)');
    set(gca,'FontName','Helvetica','FontSize',12);
    set([hTitle, hXLabel, hYLabel],'FontName','Century Gothic');
    set(gca,'Box','off','TickDir','out','TickLength',[.01 .01], ...
    'XMinorTick','off','YMinorTick','on','YGrid','on', ...
    'XColor',[.3 .3 .3],'YColor',[.3 .3 .3],'LineWidth',2);




%% NOTES AND MISC CODE

%{


return
%%


% -- PLOT IMAGESC REPLAY OF PIXELS THAT PASSED PCT% THRESHOLD

close all
% set(gca,'YDir','reverse')
fh1 = figure(1); set(fh1,'OuterPosition',[100 200 1400 600],'Color',[1 1 1]);
hax1 = axes('Position',[.03 .03 .45 .9],'Color','none','XTick',[],'YTick',[],'YDir','reverse',...
           'NextPlot','replacechildren','SortMethod','childorder');
hax2 = axes('Position',[.52 .03 .45 .9],'Color','none','XTick',[],'YTick',[],'YDir','reverse',...
           'NextPlot','replacechildren','SortMethod','childorder');
            colormap('jet');

% axes(hax1);
ph1 = imagesc(FRAMES_CSm{2},'Parent',hax1);
ph2 = imagesc(FRAMES_CSpu{2},'Parent',hax2);


for nn = 1:numel(FRAMES_CSpu)
    set(ph1,'CData',FRAMES_CSm{nn});
    set(ph2,'CData',FRAMES_CSpu{nn});
    pause(.1)
end



mm=1;
for nn = 1:numel(FRAMES_CSm)
    FRAMES_CSm_PixelMean(mm) = mean(FRAMES_CSm{nn}(FRAMES_CSm{nn}>0));
    mm=mm+1;
end

mm=1;
for nn = 1:numel(FRAMES_CSpu)
    FRAMES_CSpu_PixelMean(mm) = mean(FRAMES_CSpu{nn}(FRAMES_CSpu{nn}>0));
    mm=mm+1;
end

FrameDiff = numel(FRAMES_CSm_PixelMean)-numel(FRAMES_CSpu_PixelMean);
FRAMES_CSm_PixelMean(1:FrameDiff) = [];
% numel(FRAMES_CSm_PixelMean)

% MEAN SMOOTHING

smeth = {'moving','lowess','loess','sgolay','rlowess','rloess'};
degSm = .3; typSm = 6;
FRAMES_CSm_PixelMeanSmooth = smooth(FRAMES_CSm_PixelMean,degSm,smeth{typSm});
FRAMES_CSpu_PixelMeanSmooth = smooth(FRAMES_CSpu_PixelMean,degSm,smeth{typSm});



% PLOT MEANS

fh1=figure('Position',[600 450 1000 500],'Color','w');
hax1=axes('Position',[.07 .1 .4 .8],'Color','none');
hax2=axes('Position',[.55 .1 .4 .8],'Color','none');

ph1 = plot(hax1,[FRAMES_CSm_PixelMean' FRAMES_CSpu_PixelMean']);
ph2 = plot(hax2,[FRAMES_CSm_PixelMeanSmooth FRAMES_CSpu_PixelMeanSmooth]);

leg1 = legend(ph1,{'CSm','CSpu'});
     set(leg1, 'Location','SouthWest', 'Color',[1 1 1],'FontSize',14,'Box','off');
pause(2)

% -- Boxplot & Histogram

close all
fh1=figure('Position',[600 450 1000 500],'Color','w');
hax1=axes('Position',[.07 .1 .4 .8],'Color','none');
hax2=axes('Position',[.55 .1 .4 .8],'Color','none');

    boxplot(hax1,[FRAMES_CSm_PixelMean' FRAMES_CSpu_PixelMean'] ...
	,'notch','on' ...
	,'whisker',1 ...
	,'widths',.8 ...
	,'factorgap',[0] ...
	,'medianstyle','target');
	set(hax1,'XTickLabel',{'CSm','CSpu'},'Position',[.04 .05 .25 .9])
    pause(2)



    % axes(GUIfh.Children(1).Children(1));
hist(hax2,FRAMES_CSm_PixelMean(:),15);
hold on
hist(hax2,FRAMES_CSpu_PixelMean(:),15);
    h = findobj(gca,'Type','patch');
    h(2).FaceColor = [0 0.5 0.5];
    h(2).EdgeColor = 'w';
		pause(2)









%% NUMBER OF PIXELS PAST CRITERIA

N_ROIMx_ShockTrials = [];
N_ROIMx_NonShockTrials  = [];

mm=1;
for nn = 3:5:numel(ROIMx_ShockTrials)

N_ROIMx_ShockTrials(mm) = numel(ROIMx_ShockTrials{nn}(ROIMx_ShockTrials{nn}>0));
N_ROIMx_NonShockTrials(mm) = numel(ROIMx_NonShockTrials{nn}(ROIMx_NonShockTrials{nn}>0));
mm=mm+1;

end


close all
fh1=figure('Position',[600 450 1000 500],'Color','w');
hax1=axes('Position',[.07 .1 .4 .8],'Color','none');
hax2=axes('Position',[.55 .1 .4 .8],'Color','none');

    boxplot(hax1,[N_ROIMx_ShockTrials' N_ROIMx_NonShockTrials'] ...
	,'notch','on' ...
	,'whisker',1 ...
	,'widths',.8 ...
	,'factorgap',[0] ...
	,'medianstyle','target');
	set(hax1,'XTickLabel',{'ShockTrials','NonShockTrials'},'Position',[.04 .05 .25 .9])
    pause(2)


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
% end