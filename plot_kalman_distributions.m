% plot_kalman_distributions.m
%
% Run this script after mae280_final_proj.mlx to generate corner plots of
% the predicted distributions at t = 1 for the KF, EKF, and EnKF,
% both before and after the measurement correction step.
%
% Required workspace variables (produced by mae280_final_proj.mlx):
%   KF  : x_kalm, P_kalm, x_kalm_final, P_kalm_final
%   EKF : x_EKF,  P_EKF,  x_EKF_final,  P_EFK_final  (note typo preserved)
%   EnKF: X (3xN ensemble before), x_corrected (3xN after),
%         xbar, P_ens

lbls = {"$x_1$", "$x_2$", "$x_3$"};

% ── helpers ───────────────────────────────────────────────────────────────
function Pout = nearest_spd(P)
    % Symmetrize then clamp any negative eigenvalues to eps so that
    % plot_gaussian_ellipsoid receives a valid positive-definite matrix.
    P = (P + P') / 2;
    [V, D] = eig(P);
    D = max(D, eps * eye(size(D)));
    Pout = V * D * V';
    Pout = (Pout + Pout') / 2;
end

function plot_gaussian_corner(mu_col, Pcov, color, lbls)
    % mu_col : 3x1 column vector
    % Pcov   : 3x3 covariance matrix
    p.type  = "ekf";
    p.color = color;
    plot_corner_pdf(mu_col', 'P', nearest_spd(Pcov), 'p', p, 'lbls', lbls);
end

function plot_ensemble_corner(Xmat, color, lbls)
    % Xmat : 3xN  ->  transpose to Nx3 for plot_corner_pdf
    p.type  = "scatter";
    p.color = color;
    plot_corner_pdf(Xmat', 'p', p, 'lbls', lbls);
end

% ── 1. KF before correction ───────────────────────────────────────────────
figure('Name', 'KF – before correction');
hold on;
plot_gaussian_corner(x_kalm(:,end), P_kalm(:,end-2:end), "b", lbls);
sgtitle('KF predicted distribution at $t=1$ (before correction)', ...
        'Interpreter', 'latex', 'FontSize', 14);

% ── 2. KF after correction ────────────────────────────────────────────────
figure('Name', 'KF – after correction');
hold on;
plot_gaussian_corner(x_kalm_final, P_kalm_final, "b", lbls);
sgtitle('KF predicted distribution at $t=1$ (after correction)', ...
        'Interpreter', 'latex', 'FontSize', 14);

% ── 3. EKF before correction ──────────────────────────────────────────────
figure('Name', 'EKF – before correction');
hold on;
plot_gaussian_corner(x_EKF(:,end), P_EKF(:,end-2:end), "r", lbls);
sgtitle('EKF predicted distribution at $t=1$ (before correction)', ...
        'Interpreter', 'latex', 'FontSize', 14);

% ── 4. EKF after correction ───────────────────────────────────────────────
figure('Name', 'EKF – after correction');
hold on;
plot_gaussian_corner(x_EKF_final, P_EFK_final, "r", lbls);
sgtitle('EKF predicted distribution at $t=1$ (after correction)', ...
        'Interpreter', 'latex', 'FontSize', 14);

% ── 5. EnKF before correction ─────────────────────────────────────────────
figure('Name', 'EnKF – before correction');
hold on;
% Ensemble scatter (blue)
plot_ensemble_corner(X, "b", lbls);
% Gaussian fit to ensemble (red)
plot_gaussian_corner(xbar, P_ens, "r", lbls);
sgtitle({'EnKF predicted distribution at $t=1$ (before correction)', ...
         'blue = ensemble,  red = Gaussian fit'}, ...
        'Interpreter', 'latex', 'FontSize', 14);

% ── 6. EnKF after correction ──────────────────────────────────────────────
figure('Name', 'EnKF – after correction');
hold on;
xbar_corr   = mean(x_corrected, 2);
P_ens_corr  = cov(x_corrected');
% Ensemble scatter (blue)
plot_ensemble_corner(x_corrected, "b", lbls);
% Gaussian fit to corrected ensemble (red)
plot_gaussian_corner(xbar_corr, P_ens_corr, "r", lbls);
sgtitle({'EnKF predicted distribution at $t=1$ (after correction)', ...
         'blue = ensemble,  red = Gaussian fit'}, ...
        'Interpreter', 'latex', 'FontSize', 14);
