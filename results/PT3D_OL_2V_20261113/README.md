# PT3D open-loop 6x6 sweep, DA 2 V, 2026-11-13

- Lab PC win-PME406_04. HW2 `PT3D_HW2_20261111_235146_84e9211-rctrl-L2-clamp.sof`, PT3D_SW `PT3D_rctrl_newmodel.exe`
  (the R constants are not used in open loop). Coil driver on.
- PT3D_SW FreqSweep with MT Ctrl / HS Relax / HS Ctrl all off: HW2 sends the sine straight to the DA (P1/P3/P6 inverted).
  `alpha_tune` = excited axis 1-6, `beta_tune` = 2 V. 15 points 0.1-3000 Hz; 10 transient + >= 24 steady cycles + margin.
- Files (lab PC `PT3D_SW\Export\`, not in git): `1113_OL_P<k>_2V_<f>hz.dat` (HSData V8, 168-byte header, loop_mode 1)
  and `.f64` (full 64-word frames).
- Same amplitude and method as the 2025-09/10 data behind `legacy/P1..P6.m` (raw files on WD_BLACK `F:\P1..P6`, V1, 100 kHz).

## Quality check (`quality_check.txt`)
All 90 files: header frequency / amplitude 2 / channel correct; DA amplitude of the excited channel 2.000 V;
no DAC saturation; ADC_cnt (frame word 15) advances by exactly 2 every frame (no lost or shifted frames);
no Vm jumps (second difference > 50x its median, all 6 channels).

## Processed data
- `processed/MIMO_Raw_Bode_Data.mat`: `raw_bode.H_mag`, `H_phase_raw` (6 x 6 x 15, Vm_i / DA_j, phase not corrected), `frequencies`.
- `processed/mimo_fit_results.mat`: `step_mimo_fit` output for all 15 points (legacy wc 0.1 Hz + band 200-1500 Hz).
- `fitting_results/*.csv`: same in CSV.
- 2025 vs 2026 and legacy vs band (frequencies up to 2000 Hz): `results/compare_fit_20261113/README.md`.
