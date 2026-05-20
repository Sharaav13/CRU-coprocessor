% =========================================================================
% CRU Gold Standard Comparison Script with Speedup Analysis
% =========================================================================
% Group 23: Max Mendelow (MNDMAX003) & Sharaav Dhebideen (DHBSHA001)
% =========================================================================

clc; clear; close all;

%% =========================================================================
%  SECTION 1 — CRU RESULTS
%  =========================================================================

test_angles_deg = [0, 24, 76, 155, 200, 248, 307, 346];

eda_Xout = [31994, 29224, 7741, -28992, -30073, -11979, 19254, 31045];
eda_Yout = [2, 13022, 31043, 13529, -10929, -29668, -25552, -7740];

%% -------------------------------------------------------------------------
%  PARAMETERS
%% -------------------------------------------------------------------------
SCALE       = 32000;
CORDIC_GAIN = 1.6467602579;
Xin_fixed   = round(SCALE / CORDIC_GAIN);  % = 19431

CRU_time_ns = 150;  % ns — constant for all test angles

% Timing parameters for gold-standard measurement
NUM_RUNS    = 105;   % total number of repetitions (matches gold_standard.m)
WARMUP_RUNS = 5;     % first N runs to discard (JIT / cache warm-up)

assert(length(test_angles_deg) == length(eda_Xout), ...
    'ERROR: test_angles_deg and eda_Xout must be the same length.');
assert(length(test_angles_deg) == length(eda_Yout), ...
    'ERROR: test_angles_deg and eda_Yout must be the same length.');

n = length(test_angles_deg);

%% =========================================================================
%  SECTION 2 — GOLD STANDARD (IEEE 754) + TIMING
%  =========================================================================
test_angles_rad = deg2rad(test_angles_deg);

gold_Xout = SCALE * cos(test_angles_rad);
gold_Yout = SCALE * sin(test_angles_rad);

% Measure MATLAB execution time for each angle individually.
% Structure mirrors gold_standard.m: preallocate times_us, run NUM_RUNS
% repetitions, discard the first WARMUP_RUNS, then report avg/min/max/std.
gold_avg_us = zeros(1, n);
gold_min_us = zeros(1, n);
gold_max_us = zeros(1, n);
gold_std_us = zeros(1, n);

fprintf('Measuring gold-standard execution times (%d runs, %d discarded each)...\n', ...
    NUM_RUNS, WARMUP_RUNS);

for k = 1:n
    times_us = zeros(1, NUM_RUNS);          % preallocate timing array
    for r = 1:NUM_RUNS
        t_start     = tic;
        gold_Xout_r = round(SCALE * cos(test_angles_rad(k))); %#ok<NASGU>
        gold_Yout_r = round(SCALE * sin(test_angles_rad(k))); %#ok<NASGU>
        times_us(r) = toc(t_start) * 1e6;  % convert s → µs
    end
    % Discard the first WARMUP_RUNS timings
    times_valid    = times_us(WARMUP_RUNS+1 : end);
    gold_avg_us(k) = mean(times_valid);
    gold_min_us(k) = min(times_valid);
    gold_max_us(k) = max(times_valid);
    gold_std_us(k) = std(times_valid);
end

% Convert CRU fixed latency to µs for a consistent unit comparison
CRU_time_us = CRU_time_ns / 1e3;   % 150 ns → 0.150 µs

%% =========================================================================
%  SECTION 3 — SPEEDUP ANALYSIS
%  =========================================================================
% Speedup = (MATLAB average time) / (CRU hardware time)
% A value > 1 means the CRU is faster than MATLAB double-precision.
speedup = gold_avg_us / CRU_time_us;

%% -------------------------------------------------------------------------
%  ANGLE ENCODING (for Verilog testbench reference)
%% -------------------------------------------------------------------------
angle_raw = mod(round(test_angles_deg / 360 * 65536), 65536);
quadrant  = mod(floor(test_angles_deg / 90), 4);

%% =========================================================================
%  SECTION 4 — ACCURACY ERROR ANALYSIS
%  =========================================================================
error_X_lsb = abs(eda_Xout - gold_Xout);
error_Y_lsb = abs(eda_Yout - gold_Yout);
error_X_pct = (error_X_lsb / SCALE) * 100;
error_Y_pct = (error_Y_lsb / SCALE) * 100;
max_err_lsb = max(error_X_lsb, error_Y_lsb);

%% =========================================================================
%  SECTION 5 — CONSOLE OUTPUT
%  =========================================================================
fprintf('\n=============================================================\n');
fprintf(' CRU CORDIC — CRU vs Gold Standard\n');
fprintf(' Xin = %d  |  Scale = %d  |  Stages = 16\n', Xin_fixed, SCALE);
fprintf(' Number of test points: %d\n', n);
fprintf('=============================================================\n\n');

fprintf('%-8s %-8s %-12s %-12s %-10s %-12s %-12s %-10s %-10s %-10s\n', ...
    'Angle', 'Quad', 'Gold Xout', 'EDA Xout', 'Xerr(LSB)', ...
    'Gold Yout', 'EDA Yout', 'Yerr(LSB)', 'Max Err', 'Err(%)');
fprintf('%s\n', repmat('-', 1, 112));

for k = 1:n
    fprintf('%-8d %-8d %-12.1f %-12d %-10.2f %-12.1f %-12d %-10.2f %-10.2f %-10.5f\n', ...
        test_angles_deg(k), quadrant(k), ...
        gold_Xout(k), eda_Xout(k), error_X_lsb(k), ...
        gold_Yout(k), eda_Yout(k), error_Y_lsb(k), ...
        max_err_lsb(k), (max_err_lsb(k) / SCALE) * 100);
end

fprintf('\n--- Accuracy Summary ---\n');
fprintf('Max Xout error  : %6.3f LSB  (%8.5f%%)\n', max(error_X_lsb), max(error_X_pct));
fprintf('Max Yout error  : %6.3f LSB  (%8.5f%%)\n', max(error_Y_lsb), max(error_Y_pct));
fprintf('Mean Xout error : %6.3f LSB\n', mean(error_X_lsb));
fprintf('Mean Yout error : %6.3f LSB\n', mean(error_Y_lsb));
fprintf('Overall max err : %6.3f LSB  (%8.5f%%)\n', ...
    max([error_X_lsb, error_Y_lsb]), max([error_X_pct, error_Y_pct]));

fprintf('\n--- Speedup Summary (CRU = %d ns = %.3f us, fixed) ---\n', ...
    CRU_time_ns, CRU_time_us);
fprintf('%s\n', repmat('=', 1, 80));
for k = 1:n
    fprintf(' Angle            : %g degrees\n',  test_angles_deg(k));
    fprintf(' Gold Xout        : %d LSB\n',      round(gold_Xout(k)));
    fprintf(' Gold Yout        : %d LSB\n',      round(gold_Yout(k)));
    fprintf(' Timing Summary   (%d runs, %d discarded)\n', NUM_RUNS, WARMUP_RUNS);
    fprintf('   Average time   : %.4f us\n',     gold_avg_us(k));
    fprintf('   Min time       : %.4f us\n',     gold_min_us(k));
    fprintf('   Max time       : %.4f us\n',     gold_max_us(k));
    fprintf('   Std deviation  : %.4f us\n',     gold_std_us(k));
    fprintf('   CRU time       : %.4f us  (constant)\n', CRU_time_us);
    fprintf('   Speedup        : %.3fx\n',       speedup(k));
    fprintf('%s\n', repmat('-', 1, 80));
end
fprintf('\nOverall average speedup : %.3fx\n', mean(speedup));
fprintf('Min speedup             : %.3fx  (at %d deg)\n', ...
    min(speedup), test_angles_deg(speedup == min(speedup)));
fprintf('Max speedup             : %.3fx  (at %d deg)\n', ...
    max(speedup), test_angles_deg(speedup == max(speedup)));

fprintf('\n--- Verilog Testbench Angle Reference ---\n');
fprintf('%-10s %-12s %-8s %-6s\n', 'Angle (deg)', 'angle_raw', 'Hex', 'Quad');
fprintf('%s\n', repmat('-', 1, 40));
for k = 1:n
    fprintf('%-10d %-12d 0x%04X   %d\n', ...
        test_angles_deg(k), angle_raw(k), angle_raw(k), quadrant(k));
end

%% =========================================================================
%  SECTION 6 — PLOTS
%  =========================================================================

%% --- PLOT 1: Gold Standard vs CRU (Xout and Yout) -------------
figure('Name', 'EDA vs Gold Standard', 'NumberTitle', 'off', ...
    'Position', [100 100 900 600]);

subplot(2,1,1);
plot(test_angles_deg, gold_Xout, 'b-o', 'LineWidth', 1.5, ...
    'DisplayName', 'Gold Std (cos \times 32000)');
hold on;
plot(test_angles_deg, eda_Xout, 'r--x', 'LineWidth', 1.5, ...
    'MarkerSize', 8, 'DisplayName', 'CRU Xout');
xlabel('Angle (degrees)'); ylabel('Output Value (LSB)');
title('Xout: CRU vs MATLAB IEEE 754 Double Precision for Cosine');
legend('Location', 'best'); grid on;

subplot(2,1,2);
plot(test_angles_deg, gold_Yout, 'b-o', 'LineWidth', 1.5, ...
    'DisplayName', 'Gold Std (sin \times 32000)');
hold on;
plot(test_angles_deg, eda_Yout, 'r--x', 'LineWidth', 1.5, ...
    'MarkerSize', 8, 'DisplayName', 'CRU Yout');
xlabel('Angle (degrees)'); ylabel('Output Value (LSB)');
title('Yout: CRU vs MATLAB IEEE 754 Double Precision for Sine');
legend('Location', 'best'); grid on;

%% --- PLOT 2: Absolute Error per Angle ------------------------------------
figure('Name', 'Error Analysis', 'NumberTitle', 'off', ...
    'Position', [100 750 900 400]);

bar(test_angles_deg, [error_X_lsb', error_Y_lsb'], 'grouped');
xlabel('Angle (degrees)'); ylabel('Absolute Error (LSB)');
title('Absolute Error: CRU against MATLAB IEEE 754 Double Precision');
legend('Xout Error (cos)', 'Yout Error (sin)', 'Location', 'best');
grid on; hold on;

% Annotate bars with numeric error values
bar_width_half = (test_angles_deg(2) - test_angles_deg(1)) * 0.15;
for k = 1:n
    text(test_angles_deg(k) - bar_width_half, error_X_lsb(k) + 0.2, ...
        num2str(error_X_lsb(k), '%.1f'), 'FontSize', 7, ...
        'HorizontalAlignment', 'center', 'Color', [0 0.4 0.8]);
    text(test_angles_deg(k) + bar_width_half, error_Y_lsb(k) + 0.2, ...
        num2str(error_Y_lsb(k), '%.1f'), 'FontSize', 7, ...
        'HorizontalAlignment', 'center', 'Color', [0.8 0.2 0]);
end

%% --- PLOT 4: Execution Time Comparison (MATLAB vs CRU) ---------------------
figure('Name', 'Execution Time Comparison', 'NumberTitle', 'off', ...
    'Position', [100 100 900 420]);

cru_times_rep = repmat(CRU_time_us, 1, n);   % flat 0.150 µs line

bar_data = [gold_avg_us', cru_times_rep'];
b = bar(test_angles_deg, bar_data, 'grouped');
b(1).FaceColor = [0.2 0.4 0.8];   % blue  — MATLAB gold standard
b(2).FaceColor = [0.9 0.3 0.1];   % red   — CRU hardware

xlabel('Angle (degrees)'); ylabel('Execution Time (\mus)');
title('Execution Time: CRU vs MATLAB IEEE 754 Double Precision');
legend('MATLAB (Gold Standard)', ...
    sprintf('CRU Hardware (%.3f \\mus fixed)', CRU_time_us), ...
    'Location', 'best');
grid on; hold on;

% Mark the constant CRU line explicitly for clarity
yline(CRU_time_us, 'r--', 'LineWidth', 1.5, ...
    'Label', sprintf('CRU = %.3f \\mus (constant)', CRU_time_us), ...
    'LabelVerticalAlignment', 'bottom');

% Annotate each gold-standard bar with its avg value
for k = 1:n
    text(test_angles_deg(k), gold_avg_us(k) + gold_avg_us(k)*0.02, ...
        sprintf('%.4f', gold_avg_us(k)), 'FontSize', 8, ...
        'HorizontalAlignment', 'center', 'Color', [0.1 0.2 0.6]);
end

%% --- PLOT 5: Speedup Bar Chart -------------------------------------------
figure('Name', 'Speedup', 'NumberTitle', 'off', 'Position', [100 580 900 420]);

b2 = bar(test_angles_deg, speedup, 0.55, 'FaceColor', [0.2 0.65 0.3]);

xlabel('Angle (degrees)'); ylabel('Speedup (×)');
title('Speedup: CRU vs MATLAB IEEE 754 Double Precision');
grid on; hold on;

% Reference line at speedup = 1 (break-even)
yline(1, 'k--', 'LineWidth', 1.2, 'Label', 'Break-even (1×)', ...
    'LabelVerticalAlignment', 'bottom');

% Average speedup reference line
avg_su = mean(speedup);
yline(avg_su, 'b--', 'LineWidth', 1.5, ...
    'Label', sprintf('Avg = %.2f×', avg_su), ...
    'LabelVerticalAlignment', 'top');

% Annotate bars
for k = 1:n
    text(test_angles_deg(k), speedup(k) + 0.05, ...
        sprintf('%.2f×', speedup(k)), 'FontSize', 9, ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

ylim([0, max(speedup) * 1.25]);
xticks(test_angles_deg);
xticklabels(arrayfun(@(x) sprintf('%d°', x), test_angles_deg, ...
    'UniformOutput', false));