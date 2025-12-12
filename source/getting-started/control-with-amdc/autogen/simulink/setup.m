clear; clc;

Ts = 1/(10e3);  % sec
Tsim = Ts/10;   % sec 

%% Autogen code for the controller
model='integrator'; % Name of the controller to be built
slbuild(model);     % Generates the autogen code
oldFolder = cd('C:integrator_ert_rtw\');
command = 'for /r %i in (*.c, *.h) do copy /y %i ..\autogen';
[status, cmdout] = system(command);
cd(oldFolder);

