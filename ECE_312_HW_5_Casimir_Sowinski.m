% ECE-312 
% HW-5
% Casimir Sowinski
%% Part e
t_e_max = 10;   
N = 1000;                                         
t_e = linspace(-1*t_e_max, t_e_max, N);
a = 2;
p = (abs(t_e) < a);
figure(1);
plot(t_e, p, '-r');
% Format plot
title('P_a vs t');
ylabel('P_a');
xlabel('t');
set(gca, 'XTick', [-1*a a], 'XTickLabel', {'-a' 'a'})
xlim([-5 5]);
ylim([-3 3]);
%% Part g
%%%%%%%%%%%%%%SOMETHING IS WRONGE WITH TIME STUFF, MILLISECONDS, ETC.
t_g_max = 2;
t_g = linspace(-1*t_g_max/1000, t_g_max/1000, N);   % In millisec
%t2_millisec = t2/1000;
h_g = 2./(pi.*t_g).*cos(1500.*pi.*t_g).*sin(500.*pi.*t_g);
figure(2);
plot(t_g, h_g, '-b');
% Format plot
title('h_B_P_F vs t');
ylabel('h_B_P_F');
xlabel('t (ms)');
%set(gca, 'XTick', [-1*a a], 'XTickLabel', {'-a' 'a'})
%xlim([-5 5]);
%ylim([-3 3]);
%% Part i
f_s = 2400;    % Sample rate at 120% Nyquist rate (in Hz)
t_i_max = t_g_max;                  % +/- 2 s
N_sample = 5.4;
%N_sample = 100;
t_sample = linspace(0, t_i_max/1000, N_sample);   % In millisec
%t_sample_millisec = t_sample/1000;  % Convert to milliseconds
h_sample = 2./(pi.*t_sample).*cos(1500.*pi.*t_sample).*sin(500.*pi.*t_sample);
figure(3);
%plot(t_sample_millisec, h_sample, 'or', t2, h2, '-b');
plot(t_sample, h_sample, 'or');
hold on
plot(t_g, h_g, '-b');
hold off
% Format plot
title('h_B_P_F vs t');
ylabel('h_B_P_F');
xlabel('t (ms)');
xlim([0 2E-3]);
disp(t_i_max);
disp(N_sample);
%% Part j
nfft = 2^nextpow2(f_s); 
fftEst = fft(h_g, nfft);

figure(4);
plot(t_sample, fftEst);










