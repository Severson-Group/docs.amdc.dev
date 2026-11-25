clear; clc;

f_s_Hz = 10e3;              % sampling frequency (Hz)
t_s_s = 1/f_s_Hz;           % sampling time (s)
t_sim_s = t_s_s/10;         % simulation time (s) 
t_end_s = 10;               % simulation end time (s)

omega_e_radps = 377.0;      % electrical angular velocity (rad/s)
duty_amp = 0.8;             % amplitude of the duty-ratio waveform (--)

% Autogen code for the controller
slbuild("generate_duty");
build_dir = "generate_duty_ert_rtw";
dst_dir = "..\..\..\firmware\project-firmware\usr\controller\autogen";

delete(fullfile(dst_dir, '*.c'));
delete(fullfile(dst_dir, '*.h'));

% Copy only .c and .h files in autogen folder
copyfile(fullfile(build_dir, '*.c'), dst_dir);
copyfile(fullfile(build_dir, '*.h'), dst_dir);

