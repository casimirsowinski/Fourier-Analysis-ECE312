% Casimir Sowinski
% ECE-312, HW-4, #2
% 02/22/2015
%% Impulse Response 
x_max = 50E-4;   
N = 100;                                         
x = linspace(0, x_max, N); 
y_1 = 5000*pi*exp(-1000*pi.*x);
clc;
figure(1);
plot(x, y_1);
title({'HW-4, Sowinski, Impulse Response'});
ylabel('h(t)');
xlabel('time, t');
xlim([x(1) x(end)]);
ylim([0 max(y_1)]);

%% Bode Plots
% H(s) = 5(s)/(s+1000pi)
% H(s) = (5s)/(s+1000pi)

H01 = tf([5 0],[1 1000*pi]);
figure(2);bode(H01);
title('HW-4, Sowinski, Bode Plot');













