% =========================================================================
% CRU Gold Standard — Single Angle Query with Averaged Execution Time
% =========================================================================
% Group 23: Max Mendelow (MNDMAX003) & Sharaav Dhebideen (DHBSHA001)
% =========================================================================

clc; clear;

%% -------------------------------------------------------------------------
%  INPUT — only edit this section
%% -------------------------------------------------------------------------

angle_deg  = 45;    
NUM_RUNS   = 105;   % total number of repetitions
WARMUP_RUNS = 5;    % first N runs to discard

%% -------------------------------------------------------------------------
%  COMPUTATION
%% -------------------------------------------------------------------------

SCALE     = 32000;
angle_rad = deg2rad(angle_deg);

times_us = zeros(1, NUM_RUNS);      % preallocate timing array

for k = 1:NUM_RUNS
    t_start      = tic;
    gold_Xout    = round(SCALE * cos(angle_rad));
    gold_Yout    = round(SCALE * sin(angle_rad));
    times_us(k)  = toc(t_start) * 1e6;
end

% Discard the first WARMUP_RUNS timings
times_valid   = times_us(WARMUP_RUNS+1 : end);
avg_time_us   = mean(times_valid);
min_time_us   = min(times_valid);
max_time_us   = max(times_valid);
std_time_us   = std(times_valid);

%% -------------------------------------------------------------------------
%  OUTPUT
%% -------------------------------------------------------------------------

fprintf('=================================================\n');
fprintf(' Gold Standard Result\n');
fprintf('=================================================\n');
fprintf(' Input angle      : %g degrees\n',   angle_deg);
fprintf(' Xout (cos)       : %d LSB\n',       gold_Xout);
fprintf(' Yout (sin)       : %d LSB\n',       gold_Yout);
fprintf('-------------------------------------------------\n');
fprintf(' Timing Summary (%d runs, %d discarded)\n', NUM_RUNS, WARMUP_RUNS);
fprintf('-------------------------------------------------\n');
fprintf(' Average time     : %.4f us\n',  avg_time_us);
fprintf(' Min time         : %.4f us\n',  min_time_us);
fprintf(' Max time         : %.4f us\n',  max_time_us);
fprintf(' Std deviation    : %.4f us\n',  std_time_us);
fprintf('=================================================\n');