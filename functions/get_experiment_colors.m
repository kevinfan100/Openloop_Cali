function colors = get_experiment_colors()
%GET_EXPERIMENT_COLORS 固定顏色方案
%
% 順序: Hung (blue 'o') → Hung_noring (green 'd') → NTU (red 's')
%
% Usage:
%   colors = get_experiment_colors();
%   c = colors.Hung;        % c.rgb, c.marker, c.display_name
%   c = colors.Hung_noring;
%   c = colors.NTU;

    colors = struct();

    colors.Hung.rgb = [0, 0, 1];
    colors.Hung.marker = 'o';
    colors.Hung.display_name = 'Hung';

    colors.Hung_noring.rgb = [0, 0.6, 0];
    colors.Hung_noring.marker = 'd';
    colors.Hung_noring.display_name = 'Hung (NoRing)';

    colors.NTU.rgb = [1, 0, 0];
    colors.NTU.marker = 's';
    colors.NTU.display_name = 'NTU';

    colors.NTU_t.rgb = [0, 0, 1];
    colors.NTU_t.marker = 'o';
    colors.NTU_t.display_name = 'V_{tip}';

    colors.NTU_s.rgb = [1, 0, 0];
    colors.NTU_s.marker = 's';
    colors.NTU_s.display_name = 'V_{surface}';
end
