clear
close all

pole_1_Hz = -10;
pole_2_Hz = -100;

w1 = 2*pi*pole_1_Hz;
w2 = 2*pi*pole_2_Hz;

Tend = 10;
Tsim = 1e-5;

finit = 0.1; % initial frequency of chirp [Hz]
ftarget = 1000; % chirp frequency at target time [Hz]

%% Run simulation
out = sim('pll_test_sim.slx');

%% System ID
sim_data = [out.theta_in.Time,out.theta_in.Data,out.theta_out.Data];

den = sim_data(:,2); % input signal
num = sim_data(:,3); % output signal

[freq,mag,phase,coh] = generateFRF(num,den,Tsim,100000,'hann');

% Curve Fit Current Command Tracking FRF
% Find where frequency goes positive
idx_f_pos = find(freq >= 0,1);

G_CL = tf([-w1-w2, w1*w2], [1, -w1-w2, w1*w2]); % CL transfer function
disp('---')
disp('System Poles (Hz):')
my_poles_Hz = pole(G_CL) ./ (2*pi);
disp(my_poles_Hz(1))
disp(my_poles_Hz(2))

mag_pos = mag(idx_f_pos:end);
phase_pos = phase(idx_f_pos:end);
freq_pos = freq(idx_f_pos:end);
[~,index] = min(abs(mag_pos - 1/sqrt(2)));
freq_check = freq_pos(index);
mag_check = mag_pos(index);
phase_check = phase_pos(index);

%% Plot
markersize = 3;
linewidth = 1;

% Bode diagram
figure

f1 = 0.1;
f2 = 1000;

tiledlayout(3,1);
ax1 = nexttile;
ax2 = nexttile;
ax3 = nexttile;

% Bode plot by System ID
plot(ax1,freq,20*log10(mag),'oc','markersize',markersize);
plot(ax2,freq,phase,'oc','markersize',markersize);
plot(ax3,freq,coh,'.','markersize',6);
hold (ax1,'on'); 
hold (ax2,'on'); 

% Bode plot with ideal Closed-loop transfer function
freq_bode = transpose(linspace(0.1,1/(4*Tsim),10/(4*Tsim)));
[mag_G_CL,phase_G_CL] = bode(G_CL,freq_bode*2*pi);
plot(ax1,freq_bode,squeeze(20*log10(mag_G_CL)),'r','linewidth',linewidth);
plot(ax2,freq_bode,wrapTo180(squeeze(phase_G_CL)),'r','linewidth',linewidth);

% Set figure limit, label, etc.
xlim(ax1,[f1 f2]);
xlim(ax2,[f1 f2]);
xlim(ax3,[f1 f2]);
ylim(ax3,[0 1]);

xlabel(ax3,"Frequency (Hz)");
ylabel(ax1,"Magnitude (dB)");
ylabel(ax2,"Phase (deg)");
ylabel(ax3,"Coherence");

grid(ax1,'on');
grid(ax2,'on');
grid(ax3,'on');

set(ax1,'xscale','log');
set(ax2,'xscale','log');
set(ax3,'xscale','log');

legend(ax1,'System ID','PLL','Location','southwest');
legend(ax2,'System ID','PLL','Location','southwest');  

%%
function [freq,mag,phase,coh] = generateFRF(num,den,T,lines,win)

	fs = 1/T;
	overlap = lines/2;
	averages = floor(length(num)/(lines-overlap));
	windowType = window(win,lines);
	
	[FRF,freq] = tfestimate(den,num,windowType,overlap,lines,fs);
	[coh,freq] = mscohere(den,num,windowType,overlap,lines,fs);
	
	FRF = fftshift(FRF);
	coh = fftshift(coh);
	freq = freq - max(freq)/2;
	mag = abs(FRF);
	phase = angle(FRF) * 180/pi;

end