clc
clear
close all

%% Set simulation and plant parameters
ref = 0; % Reference
d_ref = 15; % Reference
file_name = {'no_anti_windup', 'simple_clamping', 'advanced_clamping', 'back_tracking'};
for k = 1:length(file_name)
    if k == 1  % no anti-windup
        Clamping_enable = 0; % (0: clamping is deactivated)
        Advanced_clamping_enable = 0; % (0: advanced clamping is deactivated)
        Back_tracking_enable = 0; % (0: back-tracking is deactivated)
    elseif k == 2  % simple clamping
        Clamping_enable = 1; % (0: clamping is deactivated)
        Advanced_clamping_enable = 0; % (0: advanced clamping is deactivated)
        Back_tracking_enable = 0; % (0: back-tracking is deactivated)
    elseif k == 3  % advanced clamping
        Clamping_enable = 1; % (0: clamping is deactivated)
        Advanced_clamping_enable = 1; % (0: advanced clamping is deactivated)
        Back_tracking_enable = 0; % (0: back-tracking is deactivated)
    elseif k == 4  % back-tracking
        Clamping_enable = 0; % (0: clamping is deactivated)
        Advanced_clamping_enable = 0; % (0: advanced clamping is deactivated)
        Back_tracking_enable = 1; % (0: back-tracking is deactivated)
    end
    
    Tsim = 1e-5; % Simulation sampling time [s]
    Tend = 1; % Simulation end time [s]
    
    start = 0.2; % Reference start time [s]
    stop = 1; % Reference end time [s]
    
    fb = 10; % controller bandwidth [Hz]
    wb = 2*pi*fb; % Controller bandwidth [rad/s]
    
    Kp = wb; % P gain
    Ki = wb; % I gain

    Kb = Ki/Kp; % Back-calculation coefficient
    
    upper_limit = 10; % Upper limit
    lower_limit = -10; % Lower limit
    
    d_step1 = 0.2; % Disturbance step time 1 [s]
    d_step2 = 0.3; % Disturbance step time 2 [s]
    d_step3 = 0.35; % Disturbance step time 3 [s]
    d_step4 = 0.4; % Disturbance step time 4 [s]
    
    %% Implement simulation
    out = sim('simple_model');
    
    % Extract simulation data 
    runObj = Simulink.sdi.Run.getLatest;
    
    % List of variables to extract
    obj2ext = {'time','ref','fb','err','I_out','preSat','postSat','d'};
    
    % Get signal IDs and store signals into array
    for idx = 2:length(obj2ext)
        sigID = getSignalIDsByName(runObj,obj2ext{idx});
        sig_obj.(obj2ext{idx}) = Simulink.sdi.getSignal(sigID);
        sig_val.(obj2ext{idx}) = sig_obj.(obj2ext{idx}).Values.Data;
    end
    
    time = sig_obj.(obj2ext{2}).Values.Time;
    
    writematrix([time,sig_val.ref,sig_val.fb,sig_val.err, ...
        sig_val.I_out,sig_val.preSat,sig_val.postSat,sig_val.d], append(char(file_name(k)), '.csv'))

end

no_anti_windup_data = readmatrix('no_anti_windup.csv');
simple_clamping_data = readmatrix('simple_clamping.csv');
advanced_clamping_data = readmatrix('advanced_clamping.csv');
back_tracking_data = readmatrix('back_tracking.csv');

%% Plot figure
markersize = 3;
linewidth = 1;

figure
% subplot(611)
plot(no_anti_windup_data(:,strmatch('time',obj2ext)),no_anti_windup_data(:,strmatch('ref',obj2ext)),'color','k','Linewidth',linewidth);
hold on
plot(no_anti_windup_data(:,strmatch('time',obj2ext)),no_anti_windup_data(:,strmatch('fb',obj2ext)),'color','r','Linewidth',linewidth);
hold on
plot(simple_clamping_data(:,strmatch('time',obj2ext)),simple_clamping_data(:,strmatch('fb',obj2ext)),'color','b','Linewidth',linewidth);
hold on
plot(advanced_clamping_data(:,strmatch('time',obj2ext)),advanced_clamping_data(:,strmatch('fb',obj2ext)),'color','c','LineStyle','--','Linewidth',linewidth);
hold on
plot(back_tracking_data(:,strmatch('time',obj2ext)),back_tracking_data(:,strmatch('fb',obj2ext)),'color','g','Linewidth',linewidth);
hold on
xlabel('Time [s]','Interpreter','latex');
ylabel('fb','Interpreter','latex');
legend('Command','w/o AW','Simple clamping','Advanced clamping','Back-tracking','Interpreter','latex','Location','east');
xlim([0 Tend]);
figure
% subplot(612)
plot(no_anti_windup_data(:,strmatch('time',obj2ext)),no_anti_windup_data(:,strmatch('err',obj2ext)),'color','r','Linewidth',linewidth);
hold on
plot(simple_clamping_data(:,strmatch('time',obj2ext)),simple_clamping_data(:,strmatch('err',obj2ext)),'color','b','Linewidth',linewidth);
hold on
plot(advanced_clamping_data(:,strmatch('time',obj2ext)),advanced_clamping_data(:,strmatch('err',obj2ext)),'color','c','LineStyle','--','Linewidth',linewidth);
hold on
plot(back_tracking_data(:,strmatch('time',obj2ext)),back_tracking_data(:,strmatch('err',obj2ext)),'color','g','Linewidth',linewidth);
hold on
xlabel('Time [s]','Interpreter','latex');
ylabel('err','Interpreter','latex');
legend('w/o AW','Simple clamping','Advanced clamping','Back-tracking','Interpreter','latex','Location','east');
xlim([0 Tend]);
figure
% subplot(613)
plot(no_anti_windup_data(:,strmatch('time',obj2ext)),no_anti_windup_data(:,strmatch('I_out',obj2ext)),'color','r','Linewidth',linewidth);
hold on
plot(simple_clamping_data(:,strmatch('time',obj2ext)),simple_clamping_data(:,strmatch('I_out',obj2ext)),'color','b','Linewidth',linewidth);
hold on
plot(advanced_clamping_data(:,strmatch('time',obj2ext)),advanced_clamping_data(:,strmatch('I_out',obj2ext)),'color','c','LineStyle','--','Linewidth',linewidth);
hold on
plot(back_tracking_data(:,strmatch('time',obj2ext)),back_tracking_data(:,strmatch('I_out',obj2ext)),'color','g','Linewidth',linewidth);
hold on
xlabel('Time [s]','Interpreter','latex');
ylabel('Iout','Interpreter','latex');
legend('w/o AW','Simple clamping','Advanced clamping','Back-tracking','Interpreter','latex','Location','east');
xlim([0 Tend]);
figure
% subplot(614)
plot(no_anti_windup_data(:,strmatch('time',obj2ext)),no_anti_windup_data(:,strmatch('preSat',obj2ext)),'color','r','Linewidth',linewidth);
hold on
plot(simple_clamping_data(:,strmatch('time',obj2ext)),simple_clamping_data(:,strmatch('preSat',obj2ext)),'color','b','Linewidth',linewidth);
hold on
plot(advanced_clamping_data(:,strmatch('time',obj2ext)),advanced_clamping_data(:,strmatch('preSat',obj2ext)),'color','c','LineStyle','--','Linewidth',linewidth);
hold on
plot(back_tracking_data(:,strmatch('time',obj2ext)),back_tracking_data(:,strmatch('preSat',obj2ext)),'color','g','Linewidth',linewidth);
hold on
xlabel('Time [s]','Interpreter','latex');
ylabel('preSat','Interpreter','latex');
legend('w/o AW','Simple clamping','Advanced clamping','Back-tracking','Interpreter','latex','Location','east');
xlim([0 Tend]);
figure
% subplot(615)
plot(no_anti_windup_data(:,strmatch('time',obj2ext)),no_anti_windup_data(:,strmatch('postSat',obj2ext)),'color','r','Linewidth',linewidth);
hold on
plot(simple_clamping_data(:,strmatch('time',obj2ext)),simple_clamping_data(:,strmatch('postSat',obj2ext)),'color','b','Linewidth',linewidth);
hold on
plot(advanced_clamping_data(:,strmatch('time',obj2ext)),advanced_clamping_data(:,strmatch('postSat',obj2ext)),'color','c','LineStyle','--','Linewidth',linewidth);
hold on
plot(back_tracking_data(:,strmatch('time',obj2ext)),back_tracking_data(:,strmatch('postSat',obj2ext)),'color','g','Linewidth',linewidth);
hold on
xlabel('Time [s]','Interpreter','latex');
ylabel('postSat','Interpreter','latex');
legend('w/o AW','Simple clamping','Advanced clamping','Back-tracking','Interpreter','latex','Location','east');
xlim([0 Tend]);
figure
% subplot(616)
plot(no_anti_windup_data(:,strmatch('time',obj2ext)),no_anti_windup_data(:,strmatch('d',obj2ext)),'color','r','Linewidth',linewidth);
hold on
plot(simple_clamping_data(:,strmatch('time',obj2ext)),simple_clamping_data(:,strmatch('d',obj2ext)),'color','b','Linewidth',linewidth);
hold on
plot(advanced_clamping_data(:,strmatch('time',obj2ext)),advanced_clamping_data(:,strmatch('d',obj2ext)),'color','c','LineStyle','--','Linewidth',linewidth);
hold on
plot(back_tracking_data(:,strmatch('time',obj2ext)),back_tracking_data(:,strmatch('d',obj2ext)),'color','g','Linewidth',linewidth);
hold on
xlabel('Time [s]','Interpreter','latex');
ylabel('d','Interpreter','latex');
legend('w/o AW','Simple clamping','Advanced clamping','Back-tracking','Interpreter','latex','Location','east');
xlim([0 Tend]);

% width = 5.43; height = 4.38/3;
% set(0,'units','inches')
% Inch_SS = get(0,'screensize');
% set(gcf,'Units','inches','Position',[(Inch_SS(3)-width)/2 (Inch_SS(4)-height)/2 width height]);
% print('-dsvg','-noui','results');



