clc
clear
close all

%% Set simulation parameters
Tsim = 1e-5;  % Simulation sampling time [s]
Tend = 1;  % Simulation end time [s]

ref = 1;  % Reference
start = 0.2;  % Reference start time [s]
stop = 1.5;  % Reference end time [s]

d_ref = 0;  % Disturbance
d_start = 0.2;  % Disturbance start time [s]
d_stop = 0.3;  % Disturbance end time [s]

upper_limit = 10;  % Upper limit
lower_limit = -10;  % Lower limit

%% Set controller parameters
fb = 10;  % Controller bandwidth [Hz]
wb = 2*pi*fb;  % Controller bandwidth [rad/s]

Kp = wb;  % P gain
Ki = wb;  % I gain

Kb = Ki/Kp;  % Back-calculation coefficient

% Select anti-windup methods that you want to simulate
sim_scenario = ["No anti-windup","Simple clamping","Advanced clamping","Back-tracking"];
num_sim_scenario = length(sim_scenario);

% List of variables to extract from Simulink
interested_signals = {'time','Reference','Output','Error','Iout','preSat','postSat','Disturbance'};

% Preallocate the cell array to store results
results = cell(round(Tend/Tsim+1), length(interested_signals));

%% Implement each simulation scenario
for i = 1:num_sim_scenario
    switch sim_scenario(i)
    case "No anti-windup"
        Clamping_enable = 0; Advanced_clamping_enable = 0; Back_tracking_enable = 0;
    case "Simple clamping"
        Clamping_enable = 1; Advanced_clamping_enable = 0; Back_tracking_enable = 0;
    case "Advanced clamping"
        Clamping_enable = 1; Advanced_clamping_enable = 1; Back_tracking_enable = 0;
    case "Back-tracking"
        Clamping_enable = 0; Advanced_clamping_enable = 0; Back_tracking_enable = 1;
    end
    
    % Run simulation
    out = sim('simple_model');
    
    % Extract simulation data 
    runObj = Simulink.sdi.Run.getLatest;
    
    % Get signal IDs and store signals into array
    for idx = 2:length(interested_signals)
        sigID = getSignalIDsByName(runObj,interested_signals{idx});
        sig_obj.(interested_signals{idx}) = Simulink.sdi.getSignal(sigID);
        sig_val.(interested_signals{idx}) = sig_obj.(interested_signals{idx}).Values.Data;
    end
    
    % Store simulation results
    time = sig_obj.(interested_signals{2}).Values.Time;    
    results{i} = [time,sig_val.Reference,sig_val.Output,sig_val.Error, ...
                  sig_val.Iout,sig_val.preSat,sig_val.postSat,sig_val.Disturbance];
end

%% Plot figures
% Define figure size
width = 5.43; height = 4.38/3;
set(0,'units','inches')
Inch_SS = get(0,'screensize');

% Define plot line parameters
lw = 1; colors = {'r', 'b', 'c', 'g'}; lineStyles = {'-', '-', '--', '-'};

% Plot figures
for j = 3:length(interested_signals)
    figure
    hold on
    if j == 3  % This is special handling for 'Output' plot with 'Command'
        plot(results{1}(:, 1),results{1}(:, 2),'color','k','Linewidth',lw);
        for i = 1:num_sim_scenario
            plot(results{i}(:, 1), results{i}(:, j), ...
                'color',colors{i},'LineStyle',lineStyles{i},'Linewidth',lw);
        end
        legend(['Command', sim_scenario],'Interpreter','latex','Location','east');
    else
        for i = 1:num_sim_scenario
            plot(results{i}(:, 1),results{i}(:, j), ...
                'color',colors{i},'LineStyle',lineStyles{i},'Linewidth',lw);
        end
        legend(sim_scenario,'Interpreter','latex','Location','east');
    end
    xlabel('Time [s]','Interpreter','latex');
    ylabel(interested_signals{j},'Interpreter','latex');
    xlim([0 Tend]);
    set(gcf,'Units','inches','Position',[(Inch_SS(3)-width)/2,(Inch_SS(4)-height)/2,width,height]);
    print('-dsvg','-noui',['images/' interested_signals{j}]);
end
