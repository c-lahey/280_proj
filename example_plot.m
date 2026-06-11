clearvars; clc; close all; 

figure; hold on; 
d = 3; 
mu = randn(1,d); P = randn(d, d); P = P' * P; % randomizing statistics
p.type = "ekf"; p.color = "r"; 
plot_corner_pdf(mu, 'P', P, 'p', p); % plotting Gaussian
X = mvnrnd(mu, P, 5000); 
p.type = "scatter"; p.color = "b"; 
plot_corner_pdf(X,'p', p); % plotting ensemble