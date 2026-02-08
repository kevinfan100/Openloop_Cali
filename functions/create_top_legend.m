function lgd = create_top_legend(ax, varargin)
%CREATE_TOP_LEGEND 頂端水平共用 legend
%
% Usage:
%   lgd = create_top_legend(gca)
%   lgd = create_top_legend(gca, 'FontSize', 22)
%
% 建立水平方向的 legend，放在圖表頂端。
% 用於多 subplot 共用一個 legend 的情境。

    %% Parse options
    p = inputParser;
    addParameter(p, 'FontSize', 22, @isnumeric);
    addParameter(p, 'Box', 'on', @ischar);
    parse(p, varargin{:});

    lgd = legend(ax, 'Orientation', 'horizontal', ...
        'FontSize', p.Results.FontSize, ...
        'FontWeight', 'bold', ...
        'Box', p.Results.Box);

    %% Position at top center
    lgd.Units = 'normalized';
    pos = lgd.Position;
    pos(1) = 0.5 - pos(3)/2;  % center horizontally
    pos(2) = 0.95 - pos(4);    % near top
    lgd.Position = pos;
end
