send_to_stimulator('initialize'); % send to EMG recording machine           

liqDuration=.4;  %% default 1 drop

    send_to_stimulator('solenoid_1',liqDuration)  %% liquid Dur in seconds

            
                
