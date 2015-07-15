function [FrameO] = FrameOrd()
FrameO = []; % Frame order vec
FrameO(1:5) = NaN; % For subjects 3 and 4, first five trials are removed
CSm = [1 2 3 4 5 6 7 8]; % CS- codes
CSpp = [9 10 11 12 13 14 15 16]; % CS+ paired codes
CSpu = [17 18 19 20 21 22 23 24]; % CS+ unpaired codes
acq_trials = length(find(strcmp(trial_data.phase,'Acquisition'))); % Determine number of acquisition trials

for i = 1:acq_trials
    if trial_data.stim(i,1) == 0 % CS- trials
        FrameO = [FrameO CSm];
    elseif trial_data.stim(i,1) == 1 && trial_data.shock(i,1) == 1 % CS+ paired trials
        FrameO = [FrameO CSpp];
    else % CS+ unpaired trials
        FrameO = [FrameO CSpu];
    end
end
 
% Get rid of the first five trials
for j = 1:5
    FrameO(1) = [];
end

% save('FrameO', 'FrameO');
end

