function config = PT3D_OL_2V_20261113_config()
%PT3D_OL_2V_20261113_CONFIG PT3D open-loop 6x6 sweep, DA 2 V, 2026-11-13 (lab PC win-PME406_04)
%
% Recording: PT3D_SW FreqSweep with MT Ctrl / HS Relax / HS Ctrl all off (HW2 drives the DA with the sine,
% P1/P3/P6 inverted), alpha_tune = excited axis, beta_tune = 2 V, HW2 84e9211 (L2 clamp build),
% HSData V8 (168-byte header, 124-byte records), 100 kHz. Files: <prefix>_<f>hz.dat, all in one folder.
% Same amplitude as the 2025-09/10 data behind legacy/P1..P6.m (config 'MIMO').
%
% 使用方式:
%   run_analysis('PT3D_OL_2V_20261113', 'mimo_all');   % needs the .dat files (lab PC)
%   run_analysis('PT3D_OL_2V_20261113', 'mimo_fit');   % from the CSV (works anywhere after mimo_fft)
%   compare_fit_methods                                 % 2025 vs 2026, legacy vs band fit

    config = default_config();
    config.experiment_name = 'PT3D_OL_2V_20261113';

    %% FreqSweep list (PT3D_SW DlgMTCtrl FS_FREQ_LIST), 15 points
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 500, 1000, ...
        1200, 1250, 1500, 1600, 2000, 2500, 3000
    ];
    config.expected_sampling_rate = 100000;

    %% MIMO
    config.mimo = struct();
    config.mimo.num_channels = 6;
    config.mimo.data_source = 'dat';
    config.mimo.legacy_data_folder = '';
    config.mimo.pair_map = [2, 1, 4, 3, 6, 5];
    lab_pc = 'C:\Users\kevin\Desktop\Control_Programs\PT3D_SW\Export';
    if exist(lab_pc, 'dir')
        config.mimo.dat_base_folder = lab_pc;
    else
        config.mimo.dat_base_folder = fullfile(config.project_root, 'data', 'PT3D_OL_2V_20261113');
    end
    config.mimo.dat_subfolder = repmat({''}, 6, 1);
    config.mimo.dat_prefix = {'1113_OL_P1_2V'; '1113_OL_P2_2V'; '1113_OL_P3_2V'; ...
                              '1113_OL_P4_2V'; '1113_OL_P5_2V'; '1113_OL_P6_2V'};
    config.mimo.k_A_diag = [0.3618, 0.3614, 0.3536, 0.3532, 0.3573, 0.3610];
    config.mimo.T_sample = 1e-5;

    %% Fitting: legacy (same as 'MIMO') + band fit
    config.fitting.p_weight = 0.5;
    config.fitting.wc_Hz = 0.1;
    config.fitting.band.enable = true;
    config.fitting.band.range = [200 1500];
    config.fitting.band.curves = 'diag';

    %% Output
    config.output.save_processed_mat = true;
    config.output_folder = fullfile(config.project_root, 'results', 'PT3D_OL_2V_20261113');
end
