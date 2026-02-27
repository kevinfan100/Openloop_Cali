function result = fit_charge_model(distances, magnitudes)
%FIT_CHARGE_MODEL Fit inverse-square law: H(x) = a^2 / (x + b)^2
%
% Linearization: y_i = 1/sqrt(H_i), then regress x on y:
%   x = a*y - b
%   a = (mean(x*y) - mean(x)*mean(y)) / (mean(y^2) - mean(y)^2)
%   b = a*mean(y) - mean(x)
%
% This directly yields a and b without intermediate slope/intercept.
%
% Input:
%   distances  - [M x 1] distance values (um)
%   magnitudes - [M x 1] |H| values (V/V, linear)
%
% Output:
%   result - struct with fields:
%       .a, .b              - fitted parameters (b in um)
%       .R_squared          - goodness of fit (in linearized space)
%       .distances          - input distances
%       .magnitudes         - input magnitudes
%       .fitted_magnitudes  - model prediction at input distances
%       .fit_distances_smooth - [200 x 1] dense points for plotting
%       .fit_magnitudes_smooth - [200 x 1] model prediction on dense grid

    distances = distances(:);
    magnitudes = magnitudes(:);

    %% Remove invalid points
    valid = magnitudes > 0 & isfinite(magnitudes) & isfinite(distances);
    x = distances(valid);
    H = magnitudes(valid);

    if length(x) < 2
        error('fit_charge_model:insufficient_data', ...
            'Need at least 2 valid data points, got %d.', length(x));
    end

    %% Linearize: y = 1 / sqrt(H)
    y = 1 ./ sqrt(H);

    %% Regression of x on y: x = a*y - b
    x_bar  = mean(x);
    y_bar  = mean(y);
    xy_bar = mean(x .* y);
    y2_bar = mean(y.^2);

    denom = y2_bar - y_bar^2;
    if abs(denom) < eps
        error('fit_charge_model:zero_variance', ...
            'y has zero variance, cannot fit.');
    end

    a = (xy_bar - x_bar * y_bar) / denom;
    b = a * y_bar - x_bar;

    %% R^2 in linearized space (y direction)
    y_fit = (x + b) / a;
    SS_res = sum((y - y_fit).^2);
    SS_tot = sum((y - y_bar).^2);
    if SS_tot > 0
        R_squared = 1 - SS_res / SS_tot;
    else
        R_squared = NaN;
    end

    %% Model prediction at input distances
    fitted_magnitudes = a^2 ./ (distances + b).^2;

    %% Smooth curve for plotting (200 points)
    x_min = min(distances);
    x_max = max(distances);
    x_margin = 0.05 * (x_max - x_min);
    fit_distances_smooth = linspace(max(0, x_min - x_margin), x_max + x_margin, 200)';
    fit_magnitudes_smooth = a^2 ./ (fit_distances_smooth + b).^2;

    %% Pack output
    result.a = a;
    result.b = b;
    result.R_squared = R_squared;
    result.distances = distances;
    result.magnitudes = magnitudes;
    result.fitted_magnitudes = fitted_magnitudes;
    result.fit_distances_smooth = fit_distances_smooth;
    result.fit_magnitudes_smooth = fit_magnitudes_smooth;
end
