clear all;
close all;
clc;

%% Simulink model properties for an example case
V_i = 3; % This is a voltage at analog input
V_g = 1/10; % This is the gain to scale the analog input by and set PWM duty ratio
V_hi = 0.9; % Upper limit of PWM duty cycle
V_low = 0; % Lower limit of PWM duty cycle

%% Simulation time
T_end = 10; % Simulation end time
T_step = 1e-6; % Simulation time step

%% Autogen code for the controller
model='exampleController'; % Name of the controller to be built
slbuild(model); % Generates the autogen code
