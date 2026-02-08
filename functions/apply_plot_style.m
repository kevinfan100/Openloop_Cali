function apply_plot_style(ax, style_type)
%APPLY_PLOT_STYLE 統一繪圖樣式
%
% Usage:
%   apply_plot_style(gca, 'bode')
%   apply_plot_style(gca, 'dashboard')
%
% style_type:
%   'bode'      - Bode 圖樣式 (FontSize 24, bold, no grid)
%   'dashboard'  - Dashboard 樣式 (FontSize 11, grid on)

    switch lower(style_type)
        case 'bode'
            set(ax, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
            ax.XAxis.LineWidth = 3;
            ax.YAxis.LineWidth = 3;
            box(ax, 'on');

        case 'dashboard'
            set(ax, 'FontSize', 11);
            grid(ax, 'on');

        otherwise
            warning('apply_plot_style:unknown', 'Unknown style: %s', style_type);
    end
end
