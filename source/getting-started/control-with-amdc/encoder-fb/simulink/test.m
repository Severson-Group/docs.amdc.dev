clc; clear; close all;

%% inputs

Tend = 0.2;
Ts = 1e-3;
Tsim = Ts/10;

J = 29.54e-6;
b = 4.28e-6;

speed_ref = 5e3;        % RPM

speed_control.fb = 50;     % Hz

direct.filter_fb = 100;          % Hz

pll.fb = 100;

encoder_noise_power = 0.5e-6*0;

%% calculations

% speed controller
speed_control.A = exp(-Ts*b/J);

speed_control.bw = 2*pi*speed_control.fb;
speed_control.corr_coef = 1 - (2*max(exp(-speed_control.bw*Ts), 0.5) - 1)^2;

speed_control.kp = speed_control.corr_coef * b/4 * (speed_control.A / (1 - speed_control.A));
speed_control.ki = speed_control.corr_coef * b/4 * (1 / Ts);

% direct method
direct.filter_bw = 2*pi*direct.filter_fb;

% pll
pll.bw = 2*pi*pll.fb;
pll.kp = (1 - exp(-pll.bw*Ts)) / Ts;

%% run simulation

Simulink.sdi.view
sim("speedControlSystem.slx");
