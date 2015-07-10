function [varargout] = send_to_stimulator(command, duration)
% Commands used to send information to the CED micro through a daq
%
% [elapsed_time] = send_to_tms_daq(command, command_param, show_fprintf_feedback)
%
% send_to_tms_daq('initialize')
%  Initializes the daq (must always issue first before other commands)
%
% send_to_tms_daq('status')
%  Get the current stats of the daq
%
% send_to_tms_daq('tms')
%  sends a TTL pulse to trigger the TMS machine
%
% send_to_tms_daq('sweep')
%  sends a TTL pulse to the CED to start an EMG sweep
%
% send_to_tms_daq('marker', marker_string)
%  sends a string of characters to the CED over the serial connector
%

% Copyright 2008 Mike Claffey mclaffey@ucsd.edu

% 10/02/08 error for not being able to find daq
% 09/18/08 eliminated pulse time, added elapsed_time
% 04/22/08 initial versionuuuuuuu

    start_time = GetSecs();

    % this variable holds the index of the daq between calls of the
    % function, so that DaqDeviceIndex (which takes about 5-7 ms) doesn't
    % have to be run each time 
    persistent daq_id

    % this is a variable the indicates whether the initialize command was
    % run. This ensures that experiments that use the daq initialize it at
    % the begining of the experiment and address any errors that occur
    % (e.g. daq isn't plugged in). Otherwise, the errors may occur when
    % first trying to send codes later in the experiment, or they might not
    % be noticed at all.
    persistent was_properly_initialized
    
    % default values for paramters
    if ~exist('command', 'var'), command='initialize'; end;
    if ~exist('show_fprintf_feedback', 'var'), show_fprintf_feedback=1; end;
    command = lower(command);

    % constants
    port_a = 0; % serial connector
    port_b = 1; % bnc connectors (to tms and ced)
    config_for_ouput = 0;
    config_for_input = 1; %#ok<NASGU>
    all_bits_high = 255;
    bits_for_solenoid_3_trigger = 4;  %% looks like pin35
    bits_for_solenoid_2_trigger = 2;  %% looks like pin34
    bits_for_solenoid_1_trigger = 1;  %% looks like pin33
    
%% initialization
    switch command
        case {'initialize', 'init', ''}
            % find the daq
            daq_id = 2;%DaqDeviceIndex; was 7
            if isempty(daq_id)
                error('Daq could not be found')
            end
            was_properly_initialized = true;

            % configure both ports for output            
            DaqDConfigPort(daq_id, port_a, config_for_ouput);
            DaqDConfigPort(daq_id, port_b, config_for_ouput);
            if show_fprintf_feedback
                fprintf('Daq has been initialized with daq_id = %d\n', daq_id);
            end
        otherwise
            % if the daq initialize command was not issued, complain
            if isempty(was_properly_initialized) || ~was_properly_initialized
                error('Daq must be initialized using send_to_tms_daq(''initialize'') before any commands can be issued')
            end
            % if the daq could not be found, issue a warning and exit out of the function
            if isempty(daq_id)
                warning('send_to_tms_daq() could not find the Daq and will not be issuing commands') %#ok<WNTAG>
                return
            end
    end

    % now handle all possible commands
    switch command
        case {'initialize', 'init', ''}
            % do nothing, already handled above
            
%% get status
        case 'status'
            DaqGetAll(daq_id)
        
%% tms or sweep trigger            
        case {'solenoid_1', 'solenoid_2','solenoid_3'}
                        
            switch command
                case 'solenoid_1'
                    bits_for_pulse = bits_for_solenoid_3_trigger;
%                     status_message = sprintf('Triggering TMS pulse (long cable goes high then low with approx 3 ms pulse)\n');
                case 'solenoid_2'
                    bits_for_pulse = bits_for_solenoid_3_trigger;
%                     status_message = sprintf('Triggering EMG sweep (short cable goes high then low with approx 3 ms pulse)\n');
                case 'solenoid_3'
                    bits_for_pulse = bits_for_solenoid_3_trigger;
%                     status_message = sprintf('Triggering EMG sweep (short cable goes high then low with approx 3 ms pulse)\n');
            end
            
                      
            % display status message
%             if show_fprintf_feedback, fprintf(status_message); end
            
            % go high and reset
            DaqDOut(daq_id, port_b, 0);  %% all close
            on_start = GetSecs;
            DaqDOut(daq_id, port_b, bits_for_pulse);
            on_end = GetSecs;
            pause(duration);
            off_start = GetSecs;
            DaqDOut(daq_id, port_b, 0);  %% all close
            off_end = GetSecs;
            fprintf('On duration: %f, pause duration %f, off duration %f\n', on_end - on_start, off_start - on_end, off_end - off_start);
            



%% marker
        case 'marker'
            if ~exist('command_param', 'var') || isempty(command_param)
                error 'Must provide a second paramater with the character to use as the marker'
            else
                marker_string = command_param;
            end

            if ~ischar(marker_string) 
                error('Must provide a string to send with the marker command')
            end

            % make sure all bits are originally high
            DaqDOut(daq_id, port_a, all_bits_high);

            % cycle through all characters and send over daq
            for x = 1:length(marker_string)
                % convert character to the ascii value
                marker_value = fix(marker_string(x));

                % send marker to Daq by going low on bit 8 with marker_value in remaining bits
                DaqDOut(daq_id, port_a, marker_value);

                % return to high state
                DaqDOut(daq_id, port_a, all_bits_high);
            end

%% otherwise
        otherwise
            error 'Invalid command supplied to send_to_tms_daq()'
    end

%% return elapsed time, if requested

    if nargout == 1
        varargout = {GetSecs - start_time};
    else
        varargout = {};
    end
        
end