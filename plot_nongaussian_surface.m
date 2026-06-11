function plt = plot_nongaussian_surface(X, varargin)
% plot_nongaussian_surface.m
% Benjamin Hanson, 2024
% 
% Given a set of 2D/3D state vectors X with associated weights P,
% generate an isosurface representing a curve of isovalue
% 
% Inputs:
%          X -- set of 2D/3D state vectors
%          P -- weights of 2D/3D state vectors (optional)
%   isovalue -- isosurface value(s) to plot (optional)
%          p -- plotting parameters (optional)
%               *   color -- isosurface color
%               * display -- handle visibility
%               *    name -- display name, if display==1
%               *     axh -- figure axis
%               *   alpha -- surface visibility
%               *    fill -- bool on whether contours are filled
%               *    type -- distribution type
%               *      ls -- linestyle
%               *      lw -- linewidth
%               * m_alpha -- marker alpha
% Outputs:
%   plots -- plots for legends, with first being the mean

% variable arguments - defaults
P = [];
isovalue = [normpdf(3)/normpdf(0), normpdf(2)/normpdf(0), normpdf(1)/normpdf(0)]; 
p.type = "grid"; 
p.fill = 0; 
p.color = {"r", "r", "r"}; 
p.display = 0; 
p.axh = gca; 
p.plt = 1; 

for i=1:2:length(varargin)
    if strcmp('P',varargin{i})
        P = varargin{i+1};
    elseif strcmp('isovalue',varargin{i})
        isovalue = varargin{i+1};
    elseif strcmp('p',varargin{i})
        p = varargin{i+1};
    else
        error(append("Unspecified argument: ", varargin{i}));
    end
end

[N,D] = size(X);

% checks and balances: isovalue
isovalue = sort(isovalue); 

% checks and balances: p
if ~isfield(p,'type')
    p.type = 'grid';
else
    if strcmp(p.type, 'grid')
    elseif strcmp(p.type, 'scatter')
        if ~isfield(p,'ms')
            p.ms = 10;
        end
        if ~isfield(p,'marker')
            p.marker = "o";
        end
        if ~isfield(p,'m_alpha')
            p.m_alpha = 1; 
        end
    elseif strcmp(p.type, 'scatter_grid')
        if ~isfield(p,'Nx_bins')
            p.Nx_bins = 25; 
        end
        if ~isfield(p,'Ny_bins')
            p.Ny_bins = 25; 
        end
        if ~isfield(p,'Nz_bins')
            p.Nz_bins = 25; 
        end
    else
        error("Unsupported type.")
    end
end
if ~isfield(p,'color')
    if isscalar(isovalue) && (isovalue >= 1)
        for i = 1:isovalue
            p.color{i}="r";
        end
    else
        for i = 1:numel(isovalue)
            p.color{i}="r";
        end
    end
else
    if (isstring(p.color))||(ischar(p.color))||((all(size(p.color) == [1,3]))&&(~iscell(p.color)))
        col = p.color; p.color = {}; 
        if isscalar(isovalue) && (isovalue >= 1)
            for i = 1:isovalue
                p.color{i}=col;
            end
        else
            for i = 1:numel(isovalue)
                p.color{i}=col;
            end
        end
    end 
end
if ~isfield(p,'display')
    if ~isfield(p,'name')
        p.display = 0;
    else
        p.display = 1;
    end
else
    if p.display == 1
        if ~isfield(p,'name')
            p.display = 0; 
            % p.name = {}; 
            % if isscalar(isovalue) && (isovalue >= 1)
            %     for i = 1:isovalue
            %         p.name{i} = snum2str(i) + "curve";
            %     end
            % else
            %     for i = 1:numel(isovalue)
            %         p.name{i} = snum2str(i) + "\sigma covariance";
            %     end
            % end
        % else
            % if isscalar(isovalue) && (isovalue >= 1)
            %     if numel(p.name) ~= isovalue
            %         error("Names and isovalue have different lengths.");
            %     end
            % else
            %     if numel(p.name) ~= numel(isovalue)
            %         error("Names and isovalue have different lengths.");
            %     end
            % end
        end
    end
end
if ~isfield(p, 'axh') 
    p.axh = gca; 
else
    if ~isa(p.axh, 'matlab.graphics.axis.Axes')
        error("Copy axis must be an axis variable.")
    end
end
if ~isfield(p, 'plt'), p.plt = 1; end
if ~isfield(p,'fill')
    p.fill = 0;
elseif (p.fill == 1)
    if ~isfield(p,'alpha')
        if isscalar(isovalue) && (isovalue >= 1)
            p.alpha=logspace(log(0.4),log(0.75),isovalue);
        else
            p.alpha=logspace(log(0.4),log(0.75),numel(isovalue));
        end
    else
        if isscalar(isovalue) && (isovalue >= 1)
            if numel(p.alpha) ~= isovalue
                error("Alpha and isovalue have different lengths.");
            else
                p.alpha = sort(p.alpha); 
            end
        else
            if numel(p.alpha) ~= numel(isovalue)
                error("Alpha and isovalue have different lengths.");
            else
                p.alpha = sort(p.alpha); 
            end
        end
    end
    if ~isfield(p,'hist_alpha')
        p.hist_alpha = 0.5; 
    end
end
if D==3
    if ~isfield(p,'alpha')
        if isscalar(isovalue) && (isovalue >= 1)
            p.alpha=flip(logspace(log(0.5),log(0.75),isovalue));
        else
            p.alpha=flip(logspace(log(0.5),log(0.75),numel(isovalue)));
        end
    else
        if isscalar(isovalue) && (isovalue >= 1)
            if numel(p.alpha) ~= isovalue
                error("Alpha and isovalue have different lengths.");
            else
                p.alpha = sort(p.alpha); 
            end
        else
            if numel(p.alpha) ~= numel(isovalue)
                error("Alpha and isovalue have different lengths.");
            else
                p.alpha = sort(p.alpha); 
            end
        end
    end
end
if ~isfield(p,'ls')
    p.ls = "-";
end
if ~isfield(p,'lw')
    p.lw = 2;
end
if ~isfield(p,'mean')
    p.mean = 0; 
end

% checks and balances: X, P
if ~strcmp(p.type, "scatter")
    if N~=numel(P)
        error("Incongruous state vector/weight sets.")
    end
end

switch D
    case 1, plt = plot_nongaussian_surface1D(X,P,p);
    case 2, plt = plot_nongaussian_surface2D(X,P,isovalue,p);
    case 3, plt = plot_nongaussian_surface3D(X,P,isovalue,p);
   otherwise
      error('Unsupported dimensionality');
end

function plt = plot_nongaussian_surface1D(X,P,p)

if ~strcmp(p.type, "scatter")
    if strcmp(p.type, "grid")
        [x, ~, ic] = unique(X);                    % x = sorted unique values; ic maps each sample -> bin index
        P_full = accumarray(ic, P, [numel(x), 1]); % sum P into bins (vectorized)
    elseif strcmp(p.type, "scatter_grid")
        x = linspace(min(X), max(X), p.Nx_bins+1);
        ix = discretize(X, x); 
        valid = ~isnan(ix);
        ix = ix(valid);
        P  = P(valid);
        P_full = accumarray(ix, P, [p.Nx_bins, 1], @sum, 0);
        dx = x(2) - x(1); 
        P_pad = zeros(p.Ny_bins + 2, 1);
        P_pad(2:end-1, 1) = P_full; P_full = P_pad;
        x = [x(1) - dx, x, x(end) + dx];
        x = 0.5*(x(1:end-1) + x(2:end));
    end
    dx = x(2) - x(1); 
    P_full = P_full / (sum(P_full) * dx);
    
    if p.display
        plt = plot(p.axh, x, P_full, "Color", p.color{1}, 'LineWidth', p.lw, 'LineStyle', p.ls, 'DisplayName', p.name);
    else
        plt = plot(p.axh, x, P_full, "Color", p.color{1}, 'LineWidth', p.lw, 'LineStyle', p.ls, 'HandleVisibility', 'off');
    end
    if p.fill
        fill(p.axh, [x(:); flipud(x(:))], [P_full(:); zeros(size(P_full(:)))], p.color{1}, 'FaceAlpha', p.hist_alpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end

    if p.mean
        mu = x' * P_full; 
        xline(mu, "Color", p.color{1}, 'LineWidth', p.lw, 'LineStyle', p.ls, 'HandleVisibility', 'off');
    end

else
    if p.display
        plt = histogram(p.axh, X, 'Normalization', 'pdf', 'FaceColor', p.color{1}, "EdgeColor", "none", 'DisplayName', p.name);
    else
        plt = histogram(p.axh, X, 'Normalization', 'pdf', 'FaceColor', p.color{1}, "EdgeColor", "none", 'HandleVisibility', 'off');
    end

    if p.mean
        mu = mean(X);
        xline(p.axh, mu, "Color", 'k', 'LineWidth', p.lw, 'LineStyle', p.ls, 'HandleVisibility', 'off');
    end
end
  
function plt = plot_nongaussian_surface2D(X,P,isovalue,p)

if ~strcmp(p.type, "scatter")
    if strcmp(p.type, "grid")
        x = unique(X(:,1)); nx = numel(x); [~, ix] = ismember(X(:,1), x);   % ix in 1:nx
        y = unique(X(:,2)); ny = numel(y); [~, iy] = ismember(X(:,2), y);   % iy in 1:ny
        lin = sub2ind([ny, nx], iy, ix);
        Pvec = accumarray(lin, P, [ny*nx, 1]);    % column vector length ny*nx
        P_full = reshape(Pvec, ny, nx);          % rows = y, cols = x
    elseif strcmp(p.type, "scatter_grid")
        x = linspace(min(X(:,1)), max(X(:,1)), p.Nx_bins+1);
        y = linspace(min(X(:,2)), max(X(:,2)), p.Ny_bins+1);
        ix = discretize(X(:,1), x);  
        iy = discretize(X(:,2), y);  
        valid = ~isnan(ix) & ~isnan(iy);
        ix = ix(valid);
        iy = iy(valid);
        P  = P(valid);
        lin = sub2ind([p.Ny_bins, p.Nx_bins], iy, ix);
        Pvec = accumarray(lin, P, [p.Ny_bins*p.Nx_bins, 1], @sum, 0);
        P_full = reshape(Pvec, p.Ny_bins, p.Nx_bins);
        dx = x(2) - x(1);
        dy = y(2) - y(1);
        P_pad = zeros(p.Ny_bins + 2, p.Nx_bins + 2);
        P_pad(2:end-1, 2:end-1) = P_full; P_full = P_pad; 
        x = [x(1) - dx, x, x(end) + dx];
        y = [y(1) - dy, y, y(end) + dy];
        x = 0.5 * (x(1:end-1) + x(2:end));
        y = 0.5 * (y(1:end-1) + y(2:end));
    end
    [X_grid,Y_grid] = meshgrid(x, y);
    P_full = P_full ./ sum(P_full(:));
    
    if isscalar(isovalue) && (isovalue >= 1)
        isovalue = compute_isovalues_from_pdf(P_full, isovalue);
    else
        isovalue = max(P_full(:)).*isovalue;
    end

    count = 1; 
    for i=isovalue
        if (count == numel(isovalue))&&p.display
            if strcmp(p.color{count}, "jet")
                plt{count} = contour(p.axh, X_grid, Y_grid, P_full, [linspace(min(P_full,[],'all'),max(P_full,[],'all'),50)], 'LineWidth',2, 'Fill', 'on', 'DisplayName', p.name);
                colormap(jet); 
                clim([min(P_full,[],'all'), max(P_full,[],'all')]); 
            else
                if p.fill
                    plt{count} = contour(p.axh, X_grid, Y_grid, P_full, [i i], p.ls, 'EdgeAlpha', p.alpha(count), 'EdgeColor', 'none', 'FaceAlpha', p.alpha(count), 'FaceColor', p.color{count}, 'Fill', 'on', 'DisplayName', p.name);
                else
                    plt{count} = contour(p.axh, X_grid, Y_grid, P_full, [i i], 'EdgeColor', p.color{count}, "LineWidth", p.lw, 'LineStyle', p.ls, 'DisplayName', p.name);
                end
            end
        else
            if strcmp(p.color{count}, "jet")
                plt{count} = contour(p.axh, X_grid, Y_grid, P_full, [linspace(min(P_full,[],'all'),max(P_full,[],'all'),50)], 'LineWidth',2, 'Fill', 'on', 'HandleVisibility', 'off');
                colormap(jet); 
                clim([min(P_full,[],'all'), max(P_full,[],'all')]); 
            else
                if p.fill
                    plt{count} = contour(p.axh, X_grid, Y_grid, P_full, [i i], p.ls, 'EdgeAlpha', p.alpha(count), 'EdgeColor', 'none', 'FaceAlpha', p.alpha(count), 'FaceColor', p.color{count}, 'Fill', 'on', 'HandleVisibility', 'off');
                else
                    plt{count} = contour(p.axh, X_grid, Y_grid, P_full, [i i], 'EdgeColor', p.color{count}, "LineWidth", p.lw, 'LineStyle', p.ls, 'HandleVisibility', 'off');
                end
            end
        end
        count = count + 1; 
    end
else 
    
    if p.display
        plt{1} = scatter(p.axh, X(:,1), X(:,2), p.ms, 'Marker', p.marker, 'MarkerFaceColor', p.color{1}, 'MarkerEdgeColor', p.color{1}, 'MarkerEdgeAlpha', p.m_alpha, 'MarkerFaceAlpha', p.m_alpha, 'DisplayName', p.name);
    else
        plt{1} = scatter(p.axh, X(:,1), X(:,2), p.ms, 'Marker', p.marker, 'MarkerFaceColor', p.color{1}, 'MarkerEdgeColor', p.color{1}, 'MarkerEdgeAlpha', p.m_alpha, 'MarkerFaceAlpha', p.m_alpha, 'HandleVisibility', "off");
    end
end

function plt = plot_nongaussian_surface3D(X,P,isovalue,p)

if strcmp(p.type, "scatter_grid")
    p.type = "scatter";
end
if strcmp(p.type, "grid")
    x = unique(X(:,1)); nx = numel(x); [~, ix] = ismember(X(:,1), x);   
    y = unique(X(:,2)); ny = numel(y); [~, iy] = ismember(X(:,2), y);   
    z = unique(X(:,3)); nz = numel(z); [~, iz] = ismember(X(:,3), z);   
    lin = sub2ind([ny, nx, nz], iy, ix, iz);                    
    Pvec = accumarray(lin, P, [ny*nx*nz, 1]);                  
    P_full = reshape(Pvec, ny, nx, nz);                        
    P_full = P_full ./ sum(P_full(:));                          
    [X_grid, Y_grid, Z_grid] = meshgrid(x, y, z);   
    isovalue = max(P_full(:)).*isovalue;
    
    count = 1; 
    for i=isovalue
        if (count == numel(isovalue))&&p.display
            plt{count} = patch(isosurface(X_grid, Y_grid, Z_grid, P_full, i), 'EdgeColor', 'none', 'FaceAlpha', p.alpha(count), 'FaceColor', p.color{count},'DisplayName', p.name); 
        else
            plt{count} = patch(isosurface(X_grid, Y_grid, Z_grid, P_full, i), 'EdgeColor', 'none', 'FaceAlpha', p.alpha(count), 'FaceColor', p.color{count},'HandleVisibility', 'off');
        end
        count = count + 1; 
    end
elseif strcmp(p.type, "scatter")
    
    if p.display
        plt{1} = scatter3(p.axh, X(:,1), X(:,2), X(:,3), p.ms, 'Marker', p.marker, 'MarkerFaceColor', p.color{1}, 'MarkerEdgeColor', p.color{1}, 'MarkerEdgeAlpha', p.m_alpha, 'MarkerFaceAlpha', p.m_alpha, 'DisplayName', p.name);
    else
        plt{1} = scatter3(p.axh, X(:,1), X(:,2), X(:,3), p.ms, 'Marker', p.marker, 'MarkerFaceColor', p.color{1}, 'MarkerEdgeColor', p.color{1}, 'MarkerEdgeAlpha', p.m_alpha, 'MarkerFaceAlpha', p.m_alpha, 'HandleVisibility', "off");
    end
end

function isovalues = compute_isovalues_from_pdf(P_full, N, varargin)
% COMPUTE_ISOVALUES_FROM_PDF  Compute N contour isovalues tailored to a 2D PDF.
%
% Behavior:
%  - finds the smallest isovalue (outer threshold) that produces a connected mask
%    (same relaxation procedure you used previously)
%  - finds the largest isovalue (inner threshold) **that produces a closed contour**
%    by requiring at least one connected component to: exceed a minimum mass,
%    exceed a minimum pixel area, and be strictly interior (bounding box not
%    touching image border). These checks ensure plotting contour(..., level)
%    will actually produce a closed curve rather than nothing or a few pixels.
%  - for N>2 the remaining levels are linearly spaced in PDF-value space
%    between inner (high PDF) and outer (low PDF) thresholds.
%
% Signature:
%   isovalues = compute_isovalues_from_pdf(P_full, N)
%   isovalues = compute_isovalues_from_pdf(..., 'lower_mass_target',0.995, 'min_lower_mass',0.90, ...
%                 'connectivity',8, 'min_component_mass',1e-3, 'min_pixels',10, 'require_interior',true)
%
% Inputs:
%   P_full - ny-by-nx gridded PDF (nonnegative; will be normalized)
%   N      - integer >= 2 number of desired levels
%
% Optional name/value:
%   'lower_mass_target'  (default 0.995) - initial outer mass target for lowest level
%   'min_lower_mass'     (default 0.90)  - minimum outer mass to relax to
%   'connectivity'       (default 8)     - 4 or 8 connectivity for bwconncomp
%   'min_component_mass' (default 1e-3)  - min fraction mass for a valid inner component
%   'min_pixels'         (default 10)    - min pixel count for a valid inner component
%   'require_interior'   (default true)  - require the component bbox not touch image border
%
% Output:
%   isovalues - 1xN vector (ascending: smallest/outermost -> largest/innermost)

% ---- parse inputs ----
p = inputParser;
addParameter(p,'lower_mass_target',0.995,@(x)isnumeric(x)&&x>0&&x<1);
addParameter(p,'min_lower_mass',0.90,@(x)isnumeric(x)&&x>0&&x<1);
addParameter(p,'connectivity',8,@(x)ismember(x,[4,8]));
addParameter(p,'min_component_mass',1e-3,@(x)isnumeric(x)&&x>=0&&x<1);
addParameter(p,'min_pixels',10,@(x)isnumeric(x)&&x>=1);
addParameter(p,'require_interior',true,@islogical);
parse(p,varargin{:});
lower_mass_target  = p.Results.lower_mass_target;
min_lower_mass     = p.Results.min_lower_mass;
conn               = p.Results.connectivity;
min_component_mass = p.Results.min_component_mass;
min_pixels         = p.Results.min_pixels;
require_interior   = p.Results.require_interior;

if nargin < 2
    error('Need P_full and N.');
end
if floor(N) ~= N
    error('N must be an integer >= 2.');
end

% ---- normalize and prep ----
P = P_full;
P(P < 0) = 0;
total = sum(P(:));
if total == 0
    error('P_full sums to zero (all zeros).');
end
P = P ./ total;                % ensure sums to 1

[ny, nx] = size(P);
v = P(:);
[vs_sorted, ~] = sort(v,'descend');   % descending PDF values
cum_mass = cumsum(vs_sorted);

% ---- find outer threshold (smallest isovalue) - same strategy as before ----
target_mass = lower_mass_target;
thresh_outer = [];
found_outer = false;
while target_mass >= min_lower_mass && ~found_outer
    k = find(cum_mass >= target_mass, 1, 'first');
    if isempty(k)
        level_v = vs_sorted(end);
    else
        level_v = vs_sorted(k);
    end
    mask = P >= level_v;
    cc = bwconncomp(mask, conn);
    if cc.NumObjects == 1
        thresh_outer = level_v;
        found_outer = true;
        break;
    end
    target_mass = target_mass - 0.005; % relax by 0.5%
end

if ~found_outer
    % fallback: choose threshold maximizing mass in largest connected component
    unique_vals = unique(v(v>0));
    unique_vals = sort(unique_vals, 'descend');
    best_mass = 0;
    best_thresh = unique_vals(end);
    limit = min(numel(unique_vals), 300);
    for ii = 1:limit
        vi = unique_vals(ii);
        m = P >= vi;
        cc = bwconncomp(m, conn);
        if cc.NumObjects == 0, continue; end
        comps = cellfun(@(c) sum(P(c)), cc.PixelIdxList);
        mc = max(comps);
        if mc > best_mass
            best_mass = mc;
            best_thresh = vi;
        end
        if best_mass >= 0.999, break; end
    end
    thresh_outer = best_thresh;
    warning('Could not satisfy outer connectivity at requested mass; using fallback outer threshold (largest component mass ~= %.4g).', best_mass);
end

% ---- find inner threshold (largest isovalue) BUT require a closed-ish contour ----
% We scan high->low (largest PDF values downwards). Accept the FIRST level that
% yields at least one connected component meeting: mass >= min_component_mass,
% pixel count >= min_pixels, and (optionally) bounding box strictly interior.
thresh_inner = [];
found_inner = false;
unique_vals_desc = unique(v(v>0));
unique_vals_desc = sort(unique_vals_desc, 'descend');

for ii = 1:numel(unique_vals_desc)
    lv = unique_vals_desc(ii);
    mask = P >= lv;
    if ~any(mask(:)), continue; end
    cc = bwconncomp(mask, conn);
    if cc.NumObjects == 0, continue; end
    % examine components
    for cj = 1:cc.NumObjects
        pix = cc.PixelIdxList{cj};
        % pixel area
        npix = numel(pix);
        if npix < min_pixels, continue; end
        % mass of component
        cmass = sum(P(pix));
        if cmass < min_component_mass, continue; end
        % check interiorness if requested
        if require_interior
            [r,c] = ind2sub([ny, nx], pix);
            rmin = min(r); rmax = max(r);
            cmin = min(c); cmax = max(c);
            % require strict interior (not touching border)
            if rmin <= 1 || cmin <= 1 || rmax >= ny || cmax >= nx
                % touches border => not usable as closed contour (likely open)
                continue;
            end
        end
        % passed all checks -> accept this lv as inner threshold
        thresh_inner = lv;
        found_inner = true;
        break;
    end
    if found_inner, break; end
end

% If not found with strict checks, progressively relax requirements in order:
% 1) allow touching border, 2) allow smaller pixel counts, 3) allow smaller mass.
if ~found_inner
    % Relax step 1: allow touching border (keep min_pixels & min_component_mass)
    for ii = 1:numel(unique_vals_desc)
        lv = unique_vals_desc(ii);
        mask = P >= lv;
        if ~any(mask(:)), continue; end
        cc = bwconncomp(mask, conn);
        if cc.NumObjects == 0, continue; end
        for cj = 1:cc.NumObjects
            pix = cc.PixelIdxList{cj};
            npix = numel(pix);
            if npix < min_pixels, continue; end
            cmass = sum(P(pix));
            if cmass < min_component_mass, continue; end
            % here we accept even if touches border
            thresh_inner = lv;
            found_inner = true;
            break;
        end
        if found_inner, break; end
    end
end

if ~found_inner
    % Relax step 2: reduce pixel requirement to 3 pixels (small)
    min_pixels2 = max(3, round(min_pixels/3));
    for ii = 1:numel(unique_vals_desc)
        lv = unique_vals_desc(ii);
        mask = P >= lv;
        if ~any(mask(:)), continue; end
        cc = bwconncomp(mask, conn);
        if cc.NumObjects == 0, continue; end
        for cj = 1:cc.NumObjects
            pix = cc.PixelIdxList{cj};
            npix = numel(pix);
            if npix < min_pixels2, continue; end
            cmass = sum(P(pix));
            if cmass < min_component_mass, continue; end
            thresh_inner = lv;
            found_inner = true;
            break;
        end
        if found_inner, break; end
    end
end

if ~found_inner
    % Relax step 3: reduce mass threshold to a tiny number (1e-6)
    min_comp_mass2 = min_component_mass;
    if min_comp_mass2 > 1e-6, min_comp_mass2 = 1e-6; end
    for ii = 1:numel(unique_vals_desc)
        lv = unique_vals_desc(ii);
        mask = P >= lv;
        if ~any(mask(:)), continue; end
        cc = bwconncomp(mask, conn);
        if cc.NumObjects == 0, continue; end
        for cj = 1:cc.NumObjects
            pix = cc.PixelIdxList{cj};
            npix = numel(pix);
            if npix < 1, continue; end
            cmass = sum(P(pix));
            if cmass < min_comp_mass2, continue; end
            thresh_inner = lv;
            found_inner = true;
            break;
        end
        if found_inner, break; end
    end
end

% Final fallback: if still not found, pick a near-peak value that at least returns non-empty mask
if ~found_inner
    % choose a high PDF level that yields ANY non-empty mask (this might be a single pixel)
    for ii = 1:numel(unique_vals_desc)
        lv = unique_vals_desc(ii);
        mask = P >= lv;
        if any(mask(:))
            thresh_inner = lv;
            found_inner = true;
            warning('Had to fallback to a high PDF value as inner threshold (may be a very small region).');
            break;
        end
    end
end

if isempty(thresh_inner)
    error('Unable to determine an inner threshold. PDF may be degenerate.');
end

% ---- ensure ordering ----
% thresh_outer should be <= thresh_inner logically (outer is lower PDF value)
if thresh_inner < thresh_outer
    % swap so outer is smaller value and inner is larger
    tmp = thresh_inner; thresh_inner = thresh_outer; thresh_outer = tmp;
    warning('Inner threshold was smaller than outer threshold; swapped to ensure ascending ordering.');
end
thresh_inner = thresh_inner * .9; 

% ---- produce N isovalues ----
if N == 1
    isovalues = thresh_outer; 
elseif N == 2
    isovalues = sort([thresh_outer, thresh_inner], 'ascend');
else
    % linearly space in PDF-value space between inner (high) and outer (low)
    levels = linspace(thresh_inner, thresh_outer, N);
    isovalues = sort(levels, 'ascend');
end