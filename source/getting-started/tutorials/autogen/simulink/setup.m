clear; clc;

samplingFrequency_Hz = 10e3;              % sampling frequency (Hz)
samplingTime_s = 1/samplingFrequency_Hz;  % sampling time (s)
simulationTime_s = samplingTime_s/10;     % simulation time (s) 

omegaElec_radps = 377.0;  % elctrical angular velocity (rad/s)
dutyAmplitude = 0.8;      % amplitude of the duty-ratio waveform (--)

% Autogen code for the controller
model='generate_duty';  % name of the controller to be built
slbuild(model);      % generates the Autogen code
oldFolder = cd('C:generate_duty_ert_rtw\');
% Copy only .c and .h files in autogen folder
command = 'for /r %i in (*.c, *.h) do copy /y %i ..\..\..\firmware\project-firmware\usr\controller\autogen';
[status, cmdout] = system(command);
cd(oldFolder);

