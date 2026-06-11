function plt = plot_corner_pdf(X, varargin)
% plot_corner_pdf.m
% Benjamin Hanson, 2025
% 
%   Given the N-by-D coordinate matrix X and the N-by-1 probability vector 
%   P, creates a D-by-D corner figure. Each grid of the corner plot contains 
%   a 2D plot of the subspace of the PDF
% 
% Inputs:
%          X -- N-by-D coordinate matrix
%   varargin -- optional arguments
%               * P -- weights of state vectors (optional)
%               * p -- plotting parameters (optional)
%                   *   color -- isosurface color
%                   * display -- handle visibility
%                   *    name -- display name, if display==1
%                   *   means -- plot weighted mean of point mass PDF
%                   *     axh -- figure axis
%                   *    type -- distribution type
%                   *    hist -- plot histogram on i==j plots
%               * axc -- figure axis to copy (because plotting alphaShape
%               automatically changes the aspect ratio and limits of a plot
%               * lbls -- labels of axes
% 
% Example:
% 
%   figure; hold on; 
%   d = 5; mu = randn(1,d); P = randn(d,d); P = P' * P; N = 20; x = zeros(d, N); 
%   for i = 1:d, x(i,:) = linspace(-3 * sqrt(P(i,i)) + mu(i),3 * sqrt(P(i,i)) + mu(i),N); end
%   [X1,X2,X3,X4,X5] = ndgrid(x(1,:)',x(2,:)',x(3,:)',x(4,:)',x(5,:)'); 
%   X = [X1(:) X2(:) X3(:) X4(:) X5(:)]; 
%   lbl = {"$x_1$", "$x_2$", "$x_3$", "$x_4$", "$x_5$"}; p.color = "red"; p.type = "grid"; 
%   P = mvnpdf(X, mu, P); plot_corner_pdf(X,'P',P,'lbls',lbl,'p',p);

% variable arguments - defaults
P = [];
p.color = "r";
p.display = 0; 
p.means = 0;
p.axh = gca; 
p.type = "scatter";
axc = p.axh; 

for i=1:2:length(varargin)
    if strcmp('P',varargin{i})
        P = varargin{i+1};
    elseif strcmp('p',varargin{i})
        p = varargin{i+1};
    elseif strcmp('isovalue',varargin{i})
        isovalue = varargin{i+1};
    elseif strcmp('axc',varargin{i})
        axc = varargin{i+1}; 
    elseif strcmp('lbls',varargin{i})
        lbls = varargin{i+1}; 
    else
        error(append("Unspecified argument: ", varargin{i}));
    end
end

% checks and balances: X
[N, D] = size(X); 

% checks and balances: isovalue
if ~exist("isovalue", "var")
    for i = 1 : ((D - 1) * D / 2)
        isovalue{i} = [normpdf(3)/normpdf(0), normpdf(2)/normpdf(0), normpdf(1)/normpdf(0)]; 
    end
else
    if ~iscell(isovalue)
        isovalue_i = isovalue; isovalue = {}; 
        for i = 1 : ((D - 1) * D / 2)
            isovalue{i} = isovalue_i; 
        end
    else
        isovalue_0 = isovalue; 
        for i = 1 : numel(isovalue_0)
            isovalue{i} = isovalue_0{i};
        end
        for i = (numel(isovalue_0) + 1):((D - 1) * D / 2)
            isovalue{i} = [normpdf(3)/normpdf(0), normpdf(2)/normpdf(0), normpdf(1)/normpdf(0)]; 
        end
    end
end

% checks and balances: p
if ~isfield(p,'axh')
    p.axh=gca;
end
if ~isfield(p,'type')
    p.type = "scatter"; 
else 
    if strcmp(p.type, "ukf")
        if ~isfield(p,'a')
            p.a = 0.8; 
        end
        if ~isfield(p,'b')
            p.b = 2; 
        end
        if isfield(p,'rot_m')
            for j = 1:N
                X(j,:) = (p.rot_m' * X(j,:)')';
            end
        end
        mu = zeros(D,1); 
        for j = 1:N
            mu = mu + P(j, 1) .* X(j, :)'; % Mean
        end
        S = zeros(D,D); 
        for j = 1:N
            S = S + P(j, 2) .* ((X(j, :)' - mu)*(X(j, :)' - mu)'); % Covariance
        end
        if ~isfield(p, "points_too")
            p.points_too = 0;
        end
    elseif strcmp(p.type, "ekf")
        mu = X'; 
        S = P; 
    end
end
if ~isfield(p,'hist')
    p.hist = 1; 
end
if ~isfield(p,'hold_lims')
    p.hold_lims = 0; 
end
if ~isa(axc, 'matlab.graphics.axis.Axes')
    error("Copy axis must be an axis variable.")
end
if ~exist("lbls", "var")
    for i = 1:D
        lbls{i} = "$x_" + num2str(i) + "$"; 
    end
else
    [~, Dl] = size(lbls);
    if Dl ~= D
        error("Incompatible label array size.");
    end
end

lbls_bool = 0;
tl = findall(gcf,'Type','tiledlayout');
if isempty(tl)
    t = tiledlayout(D,D); % create only if none exists
    t.TileSpacing = 'compact';
    lbls_bool = 1; 
else
    % verify it matches D x D
    if ~(tl.GridSize(1)==D && tl.GridSize(2)==D)
        error("Existing tiledlayout has incompatible dimensions.");
    end
end

iso_count = 1; 
count = 1; plt = {}; 
for i = 1:D
    for j = 1:i
        pause(0.2); nexttile((i - 1) * D + j); p.axh = gca; 
        if lbls_bool
            hold on; box on; set(p.axh, 'FontName', 'times', 'FontSize', 14, "LineWidth", 2);
        end
        if i==j 
            if p.hist
                origXL = xlim(p.axh);
                origYL = ylim(p.axh);
                if strcmp(p.type, "ukf")||strcmp(p.type, "ekf")
                    type0 = p.type; p.type = "line"; 
                    [plt{count}, ~] = plot_gaussian_ellipsoid(mu(i), sqrt(S(i, i)), 'p', p);
                    min_X = min(plt{count}{1}.XData); max_X = max(plt{count}{1}.XData); 
                    min_Y = min(plt{count}{1}.YData); max_Y = max(plt{count}{1}.YData); 
                    p.type = type0; 
                else
                    plt{count} = plot_nongaussian_surface(X(:,i), 'P', P, 'p', p); 
                    if isa(plt{count}, 'matlab.graphics.chart.primitive.Histogram')
                        min_X = min(X(:,i)); max_X = max(X(:,i)); 
                        min_Y = 0; max_Y = max(plt{count}.Values); 
                    else
                        min_X = min(X(:,i)); max_X = max(X(:,i)); 
                        min_Y = 0; max_Y = max(plt{count}.YData); 
                    end
                end
                if (i == 1)
                    ylabel("$p$", 'FontSize', 20, 'FontName', 'Times', 'Interpreter', 'latex');
                end
            end
        else
            origXL = xlim(p.axh);
            origYL = ylim(p.axh);
            if strcmp(p.type, "ukf")||strcmp(p.type, "ekf")
                type0 = p.type; p.type = "line";
                [plt{count}, shp] = plot_gaussian_ellipsoid(mu([j,i], 1), S([j,i], [j,i]), 'p', p);
                min_X = min(shp{1}(1, :)); max_X = max(shp{1}(1, :)); 
                min_Y = min(shp{1}(2, :)); max_Y = max(shp{1}(2, :)); 
                p.type = type0;
            else
                plt{count} = plot_nongaussian_surface(X(:,[j,i]), 'P', P, 'isovalue', isovalue{iso_count}, 'p', p);
                min_X = min(X(:,j)); max_X = max(X(:,j)); 
                min_Y = min(X(:,i)); max_Y = max(X(:,i));                
                iso_count = iso_count + 1; 
            end

            if strcmp(p.type, "ukf")
                if(p.points_too)
                    type0 = p.type; p.type = "scatter";
                    plot_nongaussian_surface(X(:,[j,i]), 'p', p);
                    p.type = type0;
                end
            end
        end

        if lbls_bool
            xlim(p.axh, [min_X, max_X]); 
            ylim(p.axh, [min_Y, max_Y]); 
        else
            if p.hold_lims
                xlim(origXL); ylim(origYL);
            else
                xlim(p.axh, [min(min_X, origXL(1)), max(max_X, origXL(2))]); 
                ylim(p.axh, [min(min_Y, origYL(1)), max(max_Y, origYL(2))]); 
            end
        end
        
        if lbls_bool
            if j == 1 && (i ~= 1)
                ylabel(lbls{i}, 'FontSize', 20, 'FontName', 'Times', 'Interpreter', 'latex');
            end
            if i==D
                xlabel(lbls{j}, 'FontSize', 20, 'FontName', 'Times', 'Interpreter', 'latex');
            end
            if i ~= D, xticks([]); end
            if (j ~= 1), yticks([]); end
        end
        axis normal; 
        count = count + 1; 
        drawnow; 
    end
end
end