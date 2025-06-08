clear
close all

ENABLE_SYSTEM_ID = 0;

Ts = 1e-4;
Tsim = 1e-5;

load_system('compute_speed') % load Simulink model

Tend = 0.2;

p = 1;  % number of pole
speed_cmd = 3000;  % rotational speed (r/min)

% Parameters for low pass filter
f_lpf = 100;  % low pass fileter cut-off frequency (Hz)
omega_lpf = 2*pi*f_lpf;  % low pass fileter cut-off frequency (rad/s)

% Parameters for PLL
pole_1_Hz = -10;
pole_2_Hz = -100;
w1 = 2*pi*pole_1_Hz;
w2 = 2*pi*pole_2_Hz;

% Parameters for observer
J_z = 29.54e-6;
b = 4.28e-6; 

f_sf = 10;  % motion state fileter cut-off frequency (Hz)
wb_sf = 2*pi*f_sf;
b_o_sf = wb_sf*J_z;
K_io_sf = wb_sf*b;

% Parameters for chirp signal
f_init = 0.1; % initial frequency of chirp [Hz]
f_target = 1000; % chirp frequency at target time [Hz]

% Parameters for speed control
fb_speed = 100;
omega_b_speed = 2*pi*fb_speed;
Kp_speed = omega_b_speed*J_z;
Ki_speed = omega_b_speed*b;

%% Run simulation
out = sim('compute_speed.slx');

%% Post processing
% Extract simulation data 
runObj = Simulink.sdi.Run.getLatest;

% List of variables to extract
obj2ext = {'time','theta_m','omega_raw', 'omega_lpf', 'omega_pll', 'omega_sf'};

% Get signal IDs and store signals into array
for idx = 2:length(obj2ext)
    sigID = getSignalIDsByName(runObj,obj2ext{idx});
    sig_obj.(obj2ext{idx}) = Simulink.sdi.getSignal(sigID);
    sig_val.(obj2ext{idx}) = sig_obj.(obj2ext{idx}).Values.Data;
end

time = sig_obj.(obj2ext{2}).Values.Time;

%% Plot figure
width = 2*5.43; 
height = 1.2*3*4.38 / 3;
set(0,'units','inches');
Inch_SS = get(0,'screensize');
lw = 1;  % line width

figure1 = figure;
% Plot theta_in
subplot(2,1,1);
hold on;
plot(time, squeeze(sig_val.theta_m), 'Color', 'k', 'LineWidth', lw);
xlabel('Time [s]','Interpreter','latex');
ylabel('$\theta_{\mathrm{m}}$ (rad)','Interpreter','latex');
xlim([0 Tend]);
ylim([0 7]);
yticks([0 2 4 6]);

% Plot theta_out
subplot(2,1,2);
hold on;
plot(time, squeeze(sig_val.omega_raw), 'Color', 'k', 'LineWidth', lw);
plot(time, squeeze(sig_val.omega_lpf), 'Color', 'r', 'LineWidth', lw);
plot(time, squeeze(sig_val.omega_pll), 'Color', 'b', 'LineWidth', lw);
plot(time, squeeze(sig_val.omega_sf), '--', 'Color', 'g', 'LineWidth', lw);
xlabel('Time [s]','Interpreter','latex');
ylabel('$\Omega$ (rad/s)','Interpreter','latex');
xlim([0 Tend]);
% ylim([0 400]);
legend('$\Omega_{\mathrm{raw}}$','$\Omega_{\mathrm{lpf}}$', '$\Omega_{\mathrm{pll}}$', '$\Omega_{\mathrm{sf}}$', 'Interpreter','latex','Location','east');

set(findall(gcf, '-property', 'FontName'), 'FontName', 'Times New Roman');

set(figure1,'Units','inches','Position',[(Inch_SS(3)-width)/2 (Inch_SS(4)-height)/2 width height]);
print(figure1, '-dsvg','-noui','plot_results');
print(figure1, '-dpng','-r300','plot_results');

%% System ID
if ENABLE_SYSTEM_ID == 1
    den = squeeze(sig_val.omega_raw);  % input signal
    outputs = {
        squeeze(sig_val.omega_lpf), 'Low-pass filter', '--';
        % squeeze(sig_val.omega_pll), 'PLL', '-';
        squeeze(sig_val.omega_sf),  'Observer', '-.'
    };  % output signals
    
    markersize = 3;
    linewidth = 1;
    colors = lines(size(outputs, 1));  % set color map
    
    % Bode plot
    f1 = f_init;
    f2 = f_target;
    
    figure;
    tiledlayout(3,1);
    ax1 = nexttile;  % Magnitude
    ax2 = nexttile;  % Phase
    ax3 = nexttile;  % Coherence
    
    hold(ax1, 'on');
    hold(ax2, 'on');
    hold(ax3, 'on');
    
    % Compute magnitude and phase for each signal
    for i = 1:size(outputs, 1)
        num = outputs{i, 1};
        label = outputs{i, 2};
        linestyle = outputs{i, 3};
        
        [freq, mag, phase, coh] = generateFRF(num, den, Ts, 10000, 'hann');
    
        plot(ax1, freq, 20*log10(mag), ...
            'LineStyle', 'none', 'Marker', 'o', ...
            'Color', colors(i,:), 'MarkerSize', markersize, ...
            'DisplayName', label);
    
        plot(ax2, freq, phase, ...
            'LineStyle', 'none', 'Marker', 'o', ...
            'Color', colors(i,:), 'MarkerSize', markersize, ...
            'DisplayName', label);
    
        plot(ax3, freq, coh, ...
            'LineStyle', 'none', 'Marker', 'o', ...
            'Color', colors(i,:), 'MarkerSize', markersize, ...
            'DisplayName', label);
    end
    
    xlim(ax1, [f1 f2]);
    xlim(ax2, [f1 f2]);
    xlim(ax3, [f1 f2]);
    % ylim(ax2, [-180 0]);
    ylim(ax3, [0 1]);
    
    set(ax1, 'xscale', 'log');
    set(ax2, 'xscale', 'log');
    set(ax3, 'xscale', 'log');
    
    xlabel(ax3, "Frequency (Hz)");
    ylabel(ax1, "Magnitude (dB)");
    ylabel(ax2, "Phase (deg)");
    ylabel(ax3, "Coherence");
    
    grid(ax1, 'on');
    grid(ax2, 'on');
    grid(ax3, 'on');
    
    legend(ax1, 'Location', 'southwest');
    
    set(findall(gcf, '-property', 'FontName'), 'FontName', 'Times New Roman');
    
    set(figure1,'Units','inches','Position',[(Inch_SS(3)-width)/2 (Inch_SS(4)-height)/2 width height]);
    print(figure1, '-dsvg','-noui','bode_plot');
    print(figure1, '-dpng','-r300','bode_plot');
end

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