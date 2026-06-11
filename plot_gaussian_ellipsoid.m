function [plots, shps] = plot_gaussian_ellipsoid(X, S, varargin)
% plot_gaussian_ellipsoid.m
% Benjamin Hanson, 2024
% 
% Given a set of 2D/3D state vectors X with associated weights P,
% generate an isosurface representing a curve of isovalue
% 
% Inputs:
%          X -- 2D/3D mean vector
%          S -- 2x2/3x3 covariance matrix
%         sd -- standard deviation of ellipse(s) (optional)
%          p -- plotting parameters (optional)
%               *    type -- type of plot
%               *   color -- isosurface color
%               * display -- handle visibility
%               *    name -- display name, if display==1
%               *   means -- plot weighted mean of point mass PDF
%               *     axh -- figure axis
%               *   alpha -- surface visibility
%               *     plt -- plotting boolean
% 
% Outputs:
%   plots -- plots for legends, with first being the mean

% variable arguments - defaults
sd = 3; 
p.type = "line"; 
p.display = 0; 
p.axh = gca; 
p.plt = 1; 

for i=1:2:length(varargin)
    if strcmp('sd',varargin{i})
        sd = varargin{i+1};
    elseif strcmp('p',varargin{i})
        p = varargin{i+1};
    else
        error(append("Unspecified argument: ", varargin{i}));
    end
end

% checks and balances: X, S
if numel(X) ~= length(X)
    error('X must be a vector'); 
end
if size(X,1)~=size(S,1)
    error("Incongruous mean and covariance.")
end
if size(S,1)~=size(S,2)
    error("Covariance is not square.")
end
[~,test] = chol(S);
if test ~= 0
    error("Covariance is not positive definite");
end

% checks and balances: sd
if sd < 0
    error("sd value must be positive"); 
end

% checks and balances: p
if ~isfield(p,'type')
    p.type = 'line';
elseif strcmp(p.type, 'line')
    if ~isfield(p,'lw')
        p.lw = 3;
    end
    if ~isfield(p,'ls')
        p.ls = '-';
    end
else
    error("Unsupported type.")
end
if ~isfield(p,'lw')
    p.lw = 3;
end
if ~isfield(p,'ls')
    p.ls = '-';
end
if ~isfield(p, 'sd_span')
    p.sd_span = 3; 
end
if ~isfield(p, 'fill')
    p.fill = 0; 
else
    if ~isfield(p, 'hist_alpha')
        p.hist_alpha = 0.5;
    end
end

if ~isfield(p,'color')
    for i = 1:numel(sd)
        p.color{i}="r";
    end
else
    if (isstring(p.color))||(ischar(p.color))||((all(size(p.color) == [1,3]))&&(~iscell(p.color)))
        col = p.color; p.color = {}; 
        for i = 1:numel(sd)
            p.color{i}=col;
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
        %     p.name = {}; 
        %     for i = 1:numel(sd)
        %         p.name{i} = snum2str(sd(i)) + "\sigma covariance";
        %     end
        % else
        %     if numel(p.name) ~= numel(sd)
        %         error("Names and sd have different lengths.");
        %     end
        end
    end
end
if ~isfield(p,'alpha')
    p.alpha=flip(logspace(log(0.5),log(0.75),numel(sd)));
else
   if numel(p.alpha) ~= numel(sd)
        error("Alpha and sd have different lengths.");
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
if ~isfield(p, 'mean'), p.mean = 0; end
p.alpha = sort(p.alpha, 'descend'); 
sd = sort(sd); 

% Getting dimension of mean
N=numel(X); 

switch N
    case 1, [plots,shps] = plot_gaussian_ellipsoid1D(X,S,p);
    case 2, [plots,shps] = plot_gaussian_ellipsoid2D(X,S,sd,p);
    case 3, [plots,shps] = plot_gaussian_ellipsoid3D(X,S,sd,p);
   otherwise
      error('Unsupported dimensionality');
end

if nargout==0,
    clear plots;
end

%-----------------------------
function [plots,shps] = plot_gaussian_ellipsoid1D(X, S, p)
    
x = linspace(X - p.sd_span * S, X + p.sd_span * S, 5000); 
P = normpdf(x, X, S); 

if p.plt
    if p.display
        plots{1} = plot(p.axh, x, P, 'LineStyle', "-", 'Color', p.color{1}, 'LineWidth', p.lw, 'LineStyle', p.ls, 'DisplayName', "\mu = " + snum2str(X) + ", \sigma = " + snum2str(S));
    else
        plots{1} = plot(p.axh, x, P, 'LineStyle', "-", 'Color', p.color{1}, 'LineWidth', p.lw, 'LineStyle', p.ls, 'HandleVisibility','off');
    end
    if p.fill
        fill(p.axh, [x(:); flipud(x(:))], [P(:); zeros(size(P(:)))], p.color{1}, 'FaceAlpha', p.hist_alpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end

    if p.mean
        xline(p.axh, X, "Color", p.color{1}, 'LineWidth', p.lw, 'LineStyle', p.ls, 'HandleVisibility', 'off');
    end
else
    plots{1} = NaN;
end
shps{1} = P;

%-----------------------------
function [plots,shps] = plot_gaussian_ellipsoid2D(X, S, sd, p)

count = 1; 
for i=sd
    npts=50; 
    % plot the gaussian fits
    tt = linspace(0, 2*pi, npts);
    x = cos(tt); y=sin(tt);
    ap = [x(:) y(:)]';
    [v,d]=eig(S); 
    d = i * sqrt(d); % convert variance to sdwidth*sd
    bp = (v*d*ap) + repmat(X, 1, size(ap,2)); 
    if p.plt
        % if p.mean, scatter(p.axh, X(1), X(2), 100, p.color{1}, "pentagram", 'filled','HandleVisibility','off'); end
        if(p.display==1)&&(count == 1)
            if(p.type=="fill")
                plots{count} = fill(p.axh, bp(1,:), bp(2,:), p.color{count}, 'EdgeColor', 'none', 'FaceAlpha', p.alpha(count),'DisplayName',p.name);
            elseif(p.type=="line")
                plots{count} = plot(p.axh, bp(1,:), bp(2,:), 'LineWidth', p.lw, 'LineStyle', p.ls, 'Color', p.color{count}, 'LineWidth', 3, 'DisplayName',p.name);
            end
        else
            if(p.type=="fill")
                plots{count} = fill(p.axh, bp(1,:), bp(2,:), p.color{count}, 'EdgeColor', 'none', 'FaceAlpha', p.alpha(count),'HandleVisibility','off');
            elseif(p.type=="line")
                plots{count} = plot(p.axh, bp(1,:), bp(2,:), 'LineWidth', p.lw, 'LineStyle', p.ls, 'Color', p.color{count}, 'LineWidth', 3, 'HandleVisibility','off');
            end
        end
    else
        plots{count} = NaN;
    end
    shps{count} = bp;
    p.mean = 0; count = count + 1; 
end

%-----------------------------
function [plots, shps] = plot_gaussian_ellipsoid3D(X, S, sd, p)

count = 1; 
for i=sd
    npts = 50; 
    if isfield(p, 'hgt')
        % plot the gaussian fits
        tt = linspace(0, 2*pi, npts);
        x = cos(tt); y=sin(tt);
        ap = [x(:) y(:)]';
        [v,d]=eig(S); 
        d = i * sqrt(d); % convert variance to sdwidth*sd
        bp = (v*d*ap) + repmat(X(2:3), 1, size(ap,2)); 
        xp = [X(1)*ones(size(bp(1,:))) + (length(sd)-count+1)*p.hgt X(1)*ones(size(bp(1,:))) + (length(sd)-count)*p.hgt]';
        yp = [bp(1,:) bp(1,:)]'; 
        zp = [bp(2,:) bp(2,:)]'; 
        [k, ~] = boundary(xp, yp, zp, 0.1); 

        if p.plt
            % if p.mean, scatter3(p.axh, X(1), X(2), X(3), 100, p.color{1}, "pentagram", 'filled','HandleVisibility','off'); end
            if (p.display)&&(count == 1)
                plots{count} = trisurf(k, xp, yp, zp, 'Parent', p.axh, 'Edgecolor', 'none', 'FaceColor', p.color{count}, 'FaceAlpha', p.alpha(count), 'DisplayName', p.name);  
            else
                plots{count} = trisurf(k, xp, yp, zp, 'Parent', p.axh, 'Edgecolor', 'none', 'FaceColor', p.color{count}, 'FaceAlpha', p.alpha(count), 'HandleVisibility', 'off');
            end
        else
            plots{count} = NaN;
        end
        shps{count} = [reshape(xp,1,[])', reshape(yp,1,[])', reshape(zp,1,[])']; 
        p.mean = 0; count = count + 1; 
    else
        [x,y,z] = sphere(npts);
        ap = [x(:) y(:) z(:)]';
        [v,d]=eig(S); 
        if any(d(:) < 0)
           fprintf('warning: negative eigenvalues\n');
           d = max(d,0);
        end
        d = i * sqrt(d); % convert variance to sdwidth*sd
        bp = (v*d*ap) + repmat(X, 1, size(ap,2)); 
        xp = reshape(bp(1,:), size(x));
        yp = reshape(bp(2,:), size(y));
        zp = reshape(bp(3,:), size(z));
        if p.plt
            % if p.mean, scatter3(p.axh, X(1), X(2), X(3), 100, p.color, "pentagram", 'filled','HandleVisibility','off'); end
            if(p.display==1)
                plots{count} = surf(p.axh,xp,yp,zp,"FaceColor",p.color{count},"EdgeColor","none","FaceAlpha",p.alpha(count),'DisplayName',p.name);
            else
                plots{count} = surf(p.axh,xp,yp,zp,"FaceColor",p.color{count},"EdgeColor","none","FaceAlpha",p.alpha(count),'HandleVisibility','off');
            end
        else
            plots{count} = NaN;
        end
        shps{count} = [reshape(xp,1,[])', reshape(yp,1,[])', reshape(zp,1,[])']; 
        p.display = 0; p.mean = 0; count = count + 1; 
    end
end