clear; clc;

fs = 10e3;      % sampling frequency (Hz)
Ts = 1/fs;      % sampling time (sec)
Tsim = Ts/10;   % simulation time (s) 

omega = 377.0;  % (rad/s)
Do    = 0.8;    % (--)

% %% Autogen code for the controller
% model='integrator';  % name of the controller to be built
% slbuild(model);      % generates the Autogen code
% oldFolder = cd('C:integrator_ert_rtw\');
% % Copy only .c and .h files in autogen folder
% command = 'for /r %i in (*.c, *.h) do copy /y %i ..\autogen';
% [status, cmdout] = system(command);
% cd(oldFolder);

