function colors = get_experiment_colors()
%GET_EXPERIMENT_COLORS 固定顏色方案
%
% 順序: Hung (blue 'o') → Hung_no_washer (green 'd') → NTU (red 's')
%
% Usage:
%   colors = get_experiment_colors();
%   c = colors.Hung;            % c.rgb, c.marker, c.display_name
%   c = colors.Hung_no_washer;
%   c = colors.NTU;

    colors = struct();

    colors.Hung.rgb = [0, 0, 1];
    colors.Hung.marker = 'o';
    colors.Hung.display_name = 'Hung';

    colors.Hung_no_washer.rgb = [0, 0.6, 0];
    colors.Hung_no_washer.marker = 'd';
    colors.Hung_no_washer.display_name = 'Hung (NoWasher)';

    colors.Hung_spring_washer.rgb = [0.6, 0, 0.8];
    colors.Hung_spring_washer.marker = '^';
    colors.Hung_spring_washer.display_name = 'Hung (SpringWasher)';

    colors.NTU.rgb = [1, 0, 0];
    colors.NTU.marker = 's';
    colors.NTU.display_name = 'single';

    colors.NTU_t.rgb = [0, 0, 1];
    colors.NTU_t.marker = 'o';
    colors.NTU_t.display_name = 'V_{tip}';

    colors.NTU_s.rgb = [1, 0, 0];
    colors.NTU_s.marker = 's';
    colors.NTU_s.display_name = 'V_{surface}';

    colors.Hung_single_yoke.rgb = [1, 0, 0];
    colors.Hung_single_yoke.marker = 's';
    colors.Hung_single_yoke.display_name = 'single yoke';

    colors.Hung_pair_2.rgb = [0, 0, 1];
    colors.Hung_pair_2.marker = 'o';
    colors.Hung_pair_2.display_name = 'excite';

    colors.Hung_pair_3.rgb = [0, 0.6, 0];
    colors.Hung_pair_3.marker = 'd';
    colors.Hung_pair_3.display_name = 'coupled';

    colors.NTU_pair_2.rgb = [0, 0, 1];
    colors.NTU_pair_2.marker = 'o';
    colors.NTU_pair_2.display_name = 'excite';

    colors.NTU_pair_3.rgb = [0, 0.6, 0];
    colors.NTU_pair_3.marker = 'd';
    colors.NTU_pair_3.display_name = 'coupled';

    colors.Hung_test1.rgb = [1, 0, 0];
    colors.Hung_test1.marker = 's';
    colors.Hung_test1.display_name = 'single';

    colors.Hung_single_yoke_test1.rgb = [0, 0, 1];
    colors.Hung_single_yoke_test1.marker = 'o';
    colors.Hung_single_yoke_test1.display_name = 'single yoke';

    colors.Hung_pair_test1_2.rgb = [0, 0, 1];
    colors.Hung_pair_test1_2.marker = 'o';
    colors.Hung_pair_test1_2.display_name = 'pair excite';

    colors.Hung_pair_test1_3.rgb = [0, 0.6, 0];
    colors.Hung_pair_test1_3.marker = 'd';
    colors.Hung_pair_test1_3.display_name = 'coupled';
end
