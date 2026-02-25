function result = fit_charge_model(distances, magnitudes)
%FIT_CHARGE_MODEL Fit inverse-square law: H(x) = a^2 / (x + b)^2
%
% Linearization: y = 1/sqrt(H) = (x + b) / a = (1/a)*x + (b/a)
% Linear regression on y vs x gives slope=1/a, intercept=b/a.
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

    %% Linear regression: y = slope * x + intercept
    coeffs = polyfit(x, y, 1);
    slope = coeffs(1);       % 1/a
    intercept = coeffs(2);   % b/a

    %% Recover physical parameters
    if abs(slope) < eps
        error('fit_charge_model:zero_slope', 'Slope is zero, cannot recover parameters.');
    end
    a = 1 / slope;
    b = intercept / slope;

    %% R^2 in linearized space
    y_fit = polyval(coeffs, x);
    SS_res = sum((y - y_fit).^2);
    SS_tot = sum((y - mean(y)).^2);
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
