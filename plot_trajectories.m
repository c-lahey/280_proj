% plot_trajectories.m
%
% Run after mae280_final_proj.mlx. Plots:
%   1. True vs KF / EKF / EnKF mean trajectories (one subplot per state)
%   2. Covariance trajectory as ±1σ shaded bands for KF and EKF,
%      and ensemble spread (±1 std across members) for EnKF

% ── Integrate true trajectory ─────────────────────────────────────────────
x_true = zeros(3, length(t));
x_true(:,1) = x0;
for i = 2:length(t)
    x_true(:,i) = RK4_step(f, x_true(:,i-1), dt);
end

% ── Compute EnKF ensemble mean and std at each timestep ───────────────────
N_ens = 200;
n_states = 3;
x_ens_mean = zeros(n_states, length(t));
x_ens_std  = zeros(n_states, length(t));
for i = 1:length(t)
    members = reshape(x_ensemble(:,i), n_states, N_ens);  % 3 x N_ens
    x_ens_mean(:,i) = mean(members, 2);
    x_ens_std(:,i)  = std(members, 0, 2);
end

% ── Extract KF and EKF marginal std over time ─────────────────────────────
n_t = length(t);
kf_std  = zeros(n_states, n_t);
ekf_std = zeros(n_states, n_t);
for i = 1:n_t
    P_k = P_kalm(:, 3*(i-1)+1 : 3*i);
    P_e = P_EKF(:,  3*(i-1)+1 : 3*i);
    kf_std(:,i)  = sqrt(max(diag(P_k), 0));
    ekf_std(:,i) = sqrt(max(diag(P_e), 0));
end

state_labels = {"$x_1$", "$x_2$", "$x_3$"};
colors.true  = [0.2 0.2 0.2];
colors.kf    = [0.2 0.4 0.8];
colors.ekf   = [0.8 0.2 0.2];
colors.enkf  = [0.1 0.7 0.3];

% ══ Figure 1: Mean trajectories ═══════════════════════════════════════════
figure('Name', 'Trajectories');
for s = 1:n_states
    subplot(3,1,s); hold on; box on;
    plot(t, x_true(s,:),    '-',  'Color', colors.true,  'LineWidth', 1.5, 'DisplayName', 'True');
    plot(t, x_kalm(s,:),    '--', 'Color', colors.kf,    'LineWidth', 1.2, 'DisplayName', 'KF');
    plot(t, x_EKF(s,:),     '--', 'Color', colors.ekf,   'LineWidth', 1.2, 'DisplayName', 'EKF');
    plot(t, x_ens_mean(s,:),'--', 'Color', colors.enkf,  'LineWidth', 1.2, 'DisplayName', 'EnKF mean');
    ylabel(state_labels{s}, 'Interpreter', 'latex', 'FontSize', 13);
    if s == 1
        legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 11);
        title('Estimated vs. true trajectories', 'Interpreter', 'latex', 'FontSize', 13);
    end
    if s == n_states
        xlabel('$t$', 'Interpreter', 'latex', 'FontSize', 13);
    end
    set(gca, 'FontName', 'Times', 'LineWidth', 1);
end

% ══ Figure 2: KF ±1σ bands ════════════════════════════════════════════════
figure('Name', 'KF uncertainty bands');
for s = 1:n_states
    subplot(3,1,s); hold on; box on;
    fill([t, fliplr(t)], ...
         [x_kalm(s,:) + kf_std(s,:), fliplr(x_kalm(s,:) - kf_std(s,:))], ...
         colors.kf, 'FaceAlpha', 0.25, 'EdgeColor', 'none', 'DisplayName', '$\pm 1\sigma$');
    plot(t, x_true(s,:), '-',  'Color', colors.true, 'LineWidth', 1.5, 'DisplayName', 'True');
    plot(t, x_kalm(s,:), '--', 'Color', colors.kf,   'LineWidth', 1.2, 'DisplayName', 'KF mean');
    ylabel(state_labels{s}, 'Interpreter', 'latex', 'FontSize', 13);
    if s == 1
        legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 11);
        title('KF: mean trajectory $\pm 1\sigma$', 'Interpreter', 'latex', 'FontSize', 13);
    end
    if s == n_states
        xlabel('$t$', 'Interpreter', 'latex', 'FontSize', 13);
    end
    set(gca, 'FontName', 'Times', 'LineWidth', 1);
end

% ══ Figure 3: EKF ±1σ bands ═══════════════════════════════════════════════
figure('Name', 'EKF uncertainty bands');
for s = 1:n_states
    subplot(3,1,s); hold on; box on;
    fill([t, fliplr(t)], ...
         [x_EKF(s,:) + ekf_std(s,:), fliplr(x_EKF(s,:) - ekf_std(s,:))], ...
         colors.ekf, 'FaceAlpha', 0.25, 'EdgeColor', 'none', 'DisplayName', '$\pm 1\sigma$');
    plot(t, x_true(s,:), '-',  'Color', colors.true, 'LineWidth', 1.5, 'DisplayName', 'True');
    plot(t, x_EKF(s,:),  '--', 'Color', colors.ekf,  'LineWidth', 1.2, 'DisplayName', 'EKF mean');
    ylabel(state_labels{s}, 'Interpreter', 'latex', 'FontSize', 13);
    if s == 1
        legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 11);
        title('EKF: mean trajectory $\pm 1\sigma$', 'Interpreter', 'latex', 'FontSize', 13);
    end
    if s == n_states
        xlabel('$t$', 'Interpreter', 'latex', 'FontSize', 13);
    end
    set(gca, 'FontName', 'Times', 'LineWidth', 1);
end

% ══ Figure 4: EnKF ensemble spread ════════════════════════════════════════
figure('Name', 'EnKF ensemble spread');
for s = 1:n_states
    subplot(3,1,s); hold on; box on;
    fill([t, fliplr(t)], ...
         [x_ens_mean(s,:) + x_ens_std(s,:), fliplr(x_ens_mean(s,:) - x_ens_std(s,:))], ...
         colors.enkf, 'FaceAlpha', 0.25, 'EdgeColor', 'none', 'DisplayName', '$\pm 1\sigma$ ensemble');
    plot(t, x_true(s,:),     '-',  'Color', colors.true,  'LineWidth', 1.5, 'DisplayName', 'True');
    plot(t, x_ens_mean(s,:), '--', 'Color', colors.enkf,  'LineWidth', 1.2, 'DisplayName', 'EnKF mean');
    ylabel(state_labels{s}, 'Interpreter', 'latex', 'FontSize', 13);
    if s == 1
        legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 11);
        title('EnKF: ensemble mean $\pm 1\sigma$ spread', 'Interpreter', 'latex', 'FontSize', 13);
    end
    if s == n_states
        xlabel('$t$', 'Interpreter', 'latex', 'FontSize', 13);
    end
    set(gca, 'FontName', 'Times', 'LineWidth', 1);
end
