function [R] = spm_DEM_EEG(DEM,dt,n,graphics)
% simulated electrophysiological response based on conditional estimates
% FORMAT [R] = spm_DEM_EEG(DEM,dt,n,graphics)
% DEM  - DEM structure
% dt   - time bin (seconds)
% n    - level[s]
% g    - graphics switch
%
% R{i} - response over peri-stimulus time (whitened error): level i
%
% These simulated response assume that LFPs are generated by superficial
% pyramidal cells that correspond to units encoding precision-weighted
% prediction error.
%
% see also spm_DEM_ERP
%__________________________________________________________________________

% Karl Friston
% Copyright (C) 2008-2022 Wellcome Centre for Human Neuroimaging

% defaults
%--------------------------------------------------------------------------
try
    dt;
catch
    try
        dt = DEM.U.dt;
    catch
        dt = 1;
    end
end
try
    n;
catch
    n = 1;
end
try
    graphics;
catch
    if nargout
        graphics = 0;
    else
        graphics = 1;
    end
end


% loop over hierarchical (cortical) levels
%--------------------------------------------------------------------------
if graphics, hold off; cla; hold on; end

z     = DEM.qU.z;
pst   = (1:size(z{1},2))*dt*1000;
for k = 1:length(n)

    % level
    %----------------------------------------------------------------------
    i = n(k);
    
    % precisions
    %----------------------------------------------------------------------
    P   = DEM.M(i).V;
    h   = DEM.M(i).hE;
    for j = 1:length(h)
        P = P + DEM.M(i).Q{j}*exp(h(j));
    end

    % ERPs
    %----------------------------------------------------------------------
    R{k}  = spm_sqrtm(P)*z{i};
    
    if graphics
        if i == 1
            plot(pst,R{k},'r')
        else
            plot(pst,R{k},'r:')
        end
    end
end

% labels
%--------------------------------------------------------------------------
if graphics
    xlabel('peristimulus time (ms)')
    ylabel('LFP (micro-volts)')
    box on
    hold off
    drawnow
end
